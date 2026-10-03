// PocketBase >= 0.23 initial schema for Benafsheh.
// Monetary amounts are integer Toman. Jalali dates are stored as Persian date strings;
// PocketBase's built-in created/updated fields remain ISO timestamps for audit/sorting.
// Cost data is split into private collections because PocketBase rules are record-level,
// not field-level. This prevents exposing costs to sales, warehouse, investors or customers.

const ADMIN = "@request.auth.role = 'admin'";
const ACCOUNTING = "@request.auth.role = 'admin' || @request.auth.role = 'accountant'";
const SALES = "@request.auth.role = 'admin' || @request.auth.role = 'accountant' || @request.auth.role = 'sales'";
const WAREHOUSE = "@request.auth.role = 'admin' || @request.auth.role = 'warehouse'";
const ACTIVE = "@request.auth.id != '' && @request.auth.is_active = true";
const allRules = (rule) => ({ listRule: rule, viewRule: rule, createRule: rule, updateRule: rule, deleteRule: rule });
const adminRules = allRules(ADMIN);
const activeRead = { listRule: ACTIVE, viewRule: ACTIVE, createRule: ADMIN, updateRule: ADMIN, deleteRule: ADMIN };
const accountingRead = { listRule: ACCOUNTING, viewRule: ACCOUNTING, createRule: ACCOUNTING, updateRule: ACCOUNTING, deleteRule: ADMIN };
const managerSales = { listRule: SALES, viewRule: SALES, createRule: SALES, updateRule: ACCOUNTING, deleteRule: ADMIN };

const text = (name, extra = {}) => ({ name, type: "text", max: 500, ...extra });
const number = (name, extra = {}) => ({ name, type: "number", noDecimal: true, ...extra });
const decimal = (name, extra = {}) => ({ name, type: "number", ...extra });
const bool = (name, extra = {}) => ({ name, type: "bool", ...extra });
const select = (name, values, extra = {}) => ({ name, type: "select", maxSelect: 1, values, ...extra });
const json = (name, extra = {}) => ({ name, type: "json", maxSize: 2000000, ...extra });
const relation = (name, collection, extra = {}) => ({ name, collection, maxSelect: 1, cascadeDelete: false, ...extra });

const definitions = [
  {
    name: "users", type: "auth",
    passwordAuth: { enabled: true, identityFields: ["username", "phone"] },
    authRule: "is_active = true",
    listRule: `${ADMIN} || ${ACCOUNTING} || id = @request.auth.id`,
    viewRule: `${ADMIN} || id = @request.auth.id`,
    createRule: ADMIN,
    updateRule: `${ADMIN} || (id = @request.auth.id && (@request.body.role:isset = false || @request.body.role = role) && (@request.body.is_active:isset = false || @request.body.is_active = is_active) && (@request.body.customer_id:isset = false || @request.body.customer_id = customer_id) && (@request.body.investor_id:isset = false || @request.body.investor_id = investor_id))`,
    deleteRule: ADMIN,
    fields: [
      text("username", { required: true, min: 3, max: 48, presentable: true }),
      text("name", { required: true, max: 160, presentable: true }),
      text("phone", { required: true, max: 32 }),
      select("role", ["admin", "accountant", "warehouse", "sales", "investor", "customer"], { required: true }),
      bool("is_active", { required: true }),
      text("preferred_warehouse_id", { max: 64 })
    ],
    indexes: ["CREATE UNIQUE INDEX idx_users_username ON users (username)", "CREATE UNIQUE INDEX idx_users_phone ON users (phone)"]
  },
  {
    name: "warehouses", type: "base", ...activeRead,
    listRule: `${ACTIVE} && @request.auth.role != 'customer' && @request.auth.role != 'investor'`,
    viewRule: `${ACTIVE} && @request.auth.role != 'customer' && @request.auth.role != 'investor'`,
    createRule: ADMIN, updateRule: ADMIN, deleteRule: ADMIN,
    fields: [text("name", { required: true, max: 120, presentable: true }), text("address", { max: 500 }), bool("is_active")],
    indexes: ["CREATE INDEX idx_warehouses_active ON warehouses (is_active)"]
  },
  {
    name: "product_groups", type: "base", ...activeRead,
    fields: [text("name", { required: true, max: 120, presentable: true }), text("description", { max: 1000 }), bool("is_active")]
  },
  {
    name: "products", type: "base", ...activeRead,
    fields: [
      text("code", { required: true, max: 64, presentable: true }), text("name", { required: true, max: 180 }),
      text("base_unit_name", { required: true, max: 32 }), decimal("weight_per_base_unit", { min: 0 }),
      decimal("min_stock", { min: 0 }), { name: "image", type: "file", maxSelect: 1, maxSize: 5242880, mimeTypes: ["image/jpeg", "image/png", "image/webp"] }, bool("is_active", { required: true })
    ],
    indexes: ["CREATE UNIQUE INDEX idx_products_code ON products (code)", "CREATE INDEX idx_products_active_group ON products (is_active, product_group_id)"]
  },
  {
    name: "product_units", type: "base", ...activeRead,
    fields: [
      text("unit_name", { required: true, max: 32 }), decimal("conversion_factor", { required: true, min: 0.000001 }),
      bool("is_base"), bool("is_sellable"), text("valid_from_jalali", { max: 10 }), text("valid_to_jalali", { max: 10 }), number("version_number", { min: 1 })
    ],
    indexes: ["CREATE INDEX idx_product_units_product_valid ON product_units (product_id, valid_from_jalali, valid_to_jalali)"]
  },
  {
    name: "customers", type: "base",
    listRule: `${ACCOUNTING} || @request.auth.role = 'sales' || (@request.auth.role = 'customer' && id = @request.auth.customer_id)`,
    viewRule: `${ACCOUNTING} || @request.auth.role = 'sales' || (@request.auth.role = 'customer' && id = @request.auth.customer_id)`,
    createRule: `${ACCOUNTING} || @request.auth.role = 'sales'`, updateRule: ACCOUNTING, deleteRule: ADMIN,
    fields: [
      text("code", { required: true, max: 64, presentable: true }), text("name", { required: true, max: 180 }),
      text("phone", { max: 32 }), text("address", { max: 700 }), select("customer_type", ["wholesale", "retail", "misc"], { required: true }),
      number("credit_limit", { min: 0 }), number("current_balance", { min: 0 }), bool("is_active", { required: true })
    ],
    indexes: ["CREATE UNIQUE INDEX idx_customers_code ON customers (code)", "CREATE INDEX idx_customers_name ON customers (name)"]
  },
  {
    name: "suppliers", type: "base", ...accountingRead,
    fields: [text("name", { required: true, max: 180, presentable: true }), text("phone", { max: 32 }), text("address", { max: 700 }), text("notes", { max: 2000 }), bool("is_active")],
    indexes: ["CREATE INDEX idx_suppliers_name ON suppliers (name)"]
  },
  {
    name: "pricing_profiles", type: "base", ...adminRules,
    fields: [text("name", { required: true, max: 120, presentable: true }), number("default_profit_percent", { min: 0 }), select("rounding_rule", ["none", "nearest_1000", "nearest_5000", "nearest_10000"], { required: true })]
  },
  {
    name: "volume_discount_tiers", type: "base", ...adminRules,
    fields: [number("min_amount", { min: 0 }), number("max_amount", { min: 0 }), decimal("discount_percent", { min: 0, max: 100 }), select("scope", ["per_group", "per_invoice"], { required: true })],
    indexes: ["CREATE INDEX idx_volume_tiers_profile_amount ON volume_discount_tiers (pricing_profile_id, min_amount, max_amount)"]
  },
  {
    name: "cheque_surcharge_rules", type: "base", ...adminRules,
    fields: [number("min_days", { min: 0 }), number("max_days", { min: 0 }), decimal("surcharge_percent", { min: 0, max: 100 })],
    indexes: ["CREATE INDEX idx_cheque_rules_profile_days ON cheque_surcharge_rules (pricing_profile_id, min_days, max_days)"]
  },
  {
    name: "customer_price_groups", type: "base", ...adminRules,
    fields: [text("name", { required: true, max: 120, presentable: true }), decimal("adjustment_percent", { min: -100, max: 100 })]
  },
  {
    name: "stock_movements", type: "base",
    listRule: `${WAREHOUSE} || @request.auth.role = 'accountant'`,
    viewRule: `${WAREHOUSE} || @request.auth.role = 'accountant'`,
    createRule: WAREHOUSE, updateRule: ADMIN, deleteRule: ADMIN,
    fields: [
      select("movement_type", ["purchase_in", "sale_out", "transfer_in", "transfer_out", "adjustment"], { required: true }),
      decimal("quantity_in_base_unit", { required: true }), text("unit_used", { required: true, max: 32 }),
      decimal("quantity_in_used_unit", { required: true }), decimal("conversion_factor_used", { required: true, min: 0.000001 }),
      text("reference_document_id", { max: 64 }), select("reference_document_type", ["invoice", "purchase", "transfer", "adjustment", "other"]),
      text("business_date_jalali", { required: true, max: 10 }), text("sync_id", { required: true, max: 64, unique: true }), json("metadata", { maxSize: 50000 })
    ],
    indexes: ["CREATE UNIQUE INDEX idx_stock_movements_sync_id ON stock_movements (sync_id)", "CREATE INDEX idx_stock_movements_product_date ON stock_movements (product_id, business_date_jalali)"]
  },
  {
    name: "invoices", type: "base",
    listRule: `${ADMIN} || ((@request.auth.role = 'accountant' || @request.auth.role = 'sales') && invoice_type != 'purchase' && invoice_type != 'purchase_return') || (@request.auth.role = 'customer' && customer_id = @request.auth.customer_id)`,
    viewRule: `${ADMIN} || ((@request.auth.role = 'accountant' || @request.auth.role = 'sales') && invoice_type != 'purchase' && invoice_type != 'purchase_return') || (@request.auth.role = 'customer' && customer_id = @request.auth.customer_id)`,
    createRule: `${ADMIN} || ((@request.auth.role = 'accountant' || @request.auth.role = 'sales') && invoice_type != 'purchase' && invoice_type != 'purchase_return') || (@request.auth.role = 'customer' && customer_id = @request.auth.customer_id && invoice_type = 'quote')`,
    updateRule: `${ADMIN} || (@request.auth.role = 'accountant' && invoice_type != 'purchase' && invoice_type != 'purchase_return') || (@request.auth.role = 'sales' && created_by = @request.auth.id && status = 'draft' && invoice_type != 'purchase' && invoice_type != 'purchase_return')`, deleteRule: ADMIN,
    fields: [
      select("invoice_type", ["purchase", "sale", "quote", "sale_return", "purchase_return"], { required: true }),
      text("invoice_number", { required: true, max: 32, presentable: true }),
      select("sale_mode", ["cash", "cheque_direct", "investor"]), select("discount_scope", ["per_group", "per_invoice"]),
      number("subtotal", { min: 0 }), number("discount_amount", { min: 0 }), number("surcharge_amount", { min: 0 }), number("total", { min: 0 }),
      select("status", ["draft", "confirmed", "cancelled"], { required: true }), text("notes", { max: 3000 }),
      text("invoice_date_jalali", { required: true, max: 10 }), number("cheque_duration_days", { min: 0 }), bool("stock_posted"), text("idempotency_key", { max: 64 })
    ],
    indexes: ["CREATE UNIQUE INDEX idx_invoices_number ON invoices (invoice_number)", "CREATE INDEX idx_invoices_customer_date ON invoices (customer_id, invoice_date_jalali)", "CREATE INDEX idx_invoices_status ON invoices (status)"]
  },
  {
    name: "invoice_items", type: "base",
    listRule: `${ADMIN} || ((@request.auth.role = 'accountant' || @request.auth.role = 'sales') && invoice_id.invoice_type != 'purchase' && invoice_id.invoice_type != 'purchase_return') || (@request.auth.role = 'customer' && invoice_id.customer_id = @request.auth.customer_id)`,
    viewRule: `${ADMIN} || ((@request.auth.role = 'accountant' || @request.auth.role = 'sales') && invoice_id.invoice_type != 'purchase' && invoice_id.invoice_type != 'purchase_return') || (@request.auth.role = 'customer' && invoice_id.customer_id = @request.auth.customer_id)`,
    createRule: `${ADMIN} || ((@request.auth.role = 'accountant' || @request.auth.role = 'sales') && invoice_id.invoice_type != 'purchase' && invoice_id.invoice_type != 'purchase_return' && invoice_id.status = 'draft') || (@request.auth.role = 'customer' && invoice_id.customer_id = @request.auth.customer_id && invoice_id.invoice_type = 'quote')`,
    updateRule: `${ADMIN} || ((@request.auth.role = 'accountant' || (@request.auth.role = 'sales' && invoice_id.created_by = @request.auth.id)) && invoice_id.invoice_type != 'purchase' && invoice_id.invoice_type != 'purchase_return' && invoice_id.status = 'draft')`, deleteRule: `${ADMIN} && invoice_id.status = 'draft'`,
    fields: [
      text("unit_used", { required: true, max: 32 }), decimal("quantity", { required: true, min: 0 }),
      decimal("conversion_factor_snapshot", { required: true, min: 0.000001 }), decimal("quantity_in_base_unit", { required: true, min: 0 }),
      number("unit_sell_price", { min: 0 }), text("pricing_rule_source", { max: 500 }), decimal("line_discount_percent", { min: 0, max: 100 }), number("line_total", { min: 0 })
    ]
  },
  {
    name: "payments", type: "base",
    listRule: `${ACCOUNTING} || (@request.auth.role = 'customer' && customer_id = @request.auth.customer_id)`,
    viewRule: `${ACCOUNTING} || (@request.auth.role = 'customer' && customer_id = @request.auth.customer_id)`,
    createRule: ACCOUNTING, updateRule: ACCOUNTING, deleteRule: ADMIN,
    fields: [select("payment_type", ["cash", "card", "cheque"], { required: true }), number("amount", { required: true, min: 1 }), text("payment_date_jalali", { required: true, max: 10 }), text("reference_number", { max: 100 }), text("notes", { max: 2000 })],
    indexes: ["CREATE INDEX idx_payments_date ON payments (payment_date_jalali)"]
  },
  {
    name: "cheques", type: "base",
    listRule: `${ACCOUNTING} || (@request.auth.role = 'investor' && investor_id = @request.auth.investor_id) || (@request.auth.role = 'customer' && related_party_id = @request.auth.customer_id)`,
    viewRule: `${ACCOUNTING} || (@request.auth.role = 'investor' && investor_id = @request.auth.investor_id) || (@request.auth.role = 'customer' && related_party_id = @request.auth.customer_id)`,
    createRule: ACCOUNTING, updateRule: ACCOUNTING, deleteRule: ADMIN,
    fields: [
      select("cheque_type", ["received", "issued"], { required: true }), text("cheque_number", { required: true, max: 64 }),
      text("bank_name", { required: true, max: 100 }), number("amount", { required: true, min: 1 }),
      text("due_date_jalali", { required: true, max: 10 }), select("status", ["in_hand", "deposited", "cleared", "bounced", "transferred"], { required: true }),
      select("holder", ["benafsheh", "investor"]), text("related_party_id", { max: 64 }), text("notes", { max: 2000 })
    ],
    indexes: ["CREATE INDEX idx_cheques_status_due ON cheques (status, due_date_jalali)", "CREATE INDEX idx_cheques_number ON cheques (cheque_number)"]
  },
  {
    name: "investors", type: "base",
    listRule: `${ACCOUNTING} || (@request.auth.role = 'investor' && id = @request.auth.investor_id)`,
    viewRule: `${ACCOUNTING} || (@request.auth.role = 'investor' && id = @request.auth.investor_id)`,
    createRule: ACCOUNTING, updateRule: ACCOUNTING, deleteRule: ADMIN,
    fields: [text("name", { required: true, max: 180, presentable: true }), text("phone", { max: 32 }), text("address", { max: 700 }), select("settlement_type", ["cash", "goods", "cheque", "mixed"]), bool("is_active")],
    indexes: ["CREATE INDEX idx_investors_active ON investors (is_active)"]
  },
  {
    name: "investor_deals", type: "base",
    listRule: `${ACCOUNTING} || (@request.auth.role = 'investor' && investor_id = @request.auth.investor_id)`,
    viewRule: `${ACCOUNTING} || (@request.auth.role = 'investor' && investor_id = @request.auth.investor_id)`,
    createRule: ACCOUNTING, updateRule: ACCOUNTING, deleteRule: ADMIN,
    fields: [number("benafsheh_sell_price", { min: 0 }), number("customer_sell_price", { min: 0 }), number("investor_profit", { min: 0 }), select("status", ["open", "settled"], { required: true }), text("deal_date_jalali", { required: true, max: 10 })],
    indexes: ["CREATE INDEX idx_investor_deals_investor_status ON investor_deals (investor_id, status)"]
  },
  {
    name: "investor_settlements", type: "base",
    listRule: `${ACCOUNTING} || (@request.auth.role = 'investor' && investor_id = @request.auth.investor_id)`,
    viewRule: `${ACCOUNTING} || (@request.auth.role = 'investor' && investor_id = @request.auth.investor_id)`,
    createRule: ACCOUNTING, updateRule: ACCOUNTING, deleteRule: ADMIN,
    fields: [select("settlement_type", ["cash", "goods", "cheque"], { required: true }), number("amount", { required: true, min: 1 }), text("settlement_date_jalali", { required: true, max: 10 }), text("notes", { max: 2000 })],
    indexes: ["CREATE INDEX idx_investor_settlements_investor_date ON investor_settlements (investor_id, settlement_date_jalali)"]
  },
  {
    name: "settings", type: "base", ...adminRules,
    fields: [text("key", { required: true, max: 120, presentable: true }), json("value")],
    indexes: ["CREATE UNIQUE INDEX idx_settings_key ON settings (key)"]
  },
  {
    name: "activity_log", type: "base", ...adminRules,
    fields: [text("action", { required: true, max: 120 }), text("entity_type", { required: true, max: 120 }), text("entity_id", { max: 64 }), json("old_values"), json("new_values"), text("business_date_jalali", { max: 10 })],
    indexes: ["CREATE INDEX idx_activity_log_entity ON activity_log (entity_type, entity_id)"]
  },
  {
    name: "sync_queue", type: "base",
    listRule: `${ADMIN} || (@request.auth.role = 'warehouse' && user_id = @request.auth.id)`,
    viewRule: `${ADMIN} || (@request.auth.role = 'warehouse' && user_id = @request.auth.id)`,
    createRule: `@request.auth.role = 'warehouse' && @request.auth.is_active = true && user_id = @request.auth.id && entity_type = 'stock_movement' && action = 'create'`, updateRule: ADMIN, deleteRule: ADMIN,
    fields: [text("device_id", { required: true, max: 120 }), text("entity_type", { required: true, max: 80 }), text("entity_id", { required: true, max: 120 }), select("action", ["create", "update", "delete"], { required: true }), json("payload", { maxSize: 500000 }), text("sync_id", { required: true, max: 64, unique: true }), text("synced_at", { max: 40 }), bool("conflict"), text("error_message", { max: 500 })],
    indexes: ["CREATE UNIQUE INDEX idx_sync_queue_sync_id ON sync_queue (sync_id)", "CREATE INDEX idx_sync_queue_device ON sync_queue (device_id, created)"]
  },
  // Private accounting collections. They are intentionally separate from records
  // listed to regular users; PocketBase API rules cannot redact individual fields.
  {
    name: "product_costs", type: "base", ...adminRules,
    fields: [number("base_cost_price", { required: true, min: 0 }), text("valid_from_jalali", { max: 10 }), text("notes", { max: 1000 })],
    indexes: ["CREATE UNIQUE INDEX idx_product_costs_product ON product_costs (product)"]
  },
  {
    name: "invoice_item_costs", type: "base", ...adminRules,
    fields: [number("unit_cost_price", { required: true, min: 0 }), number("cost_total", { min: 0 })],
    indexes: ["CREATE UNIQUE INDEX idx_invoice_item_costs_item ON invoice_item_costs (invoice_item)"]
  },
  {
    name: "investor_deal_costs", type: "base",
    listRule: ADMIN, viewRule: ADMIN, createRule: ADMIN, updateRule: ADMIN, deleteRule: ADMIN,
    fields: [number("benafsheh_cost_price", { required: true, min: 0 }), number("benafsheh_profit", { min: 0 }), text("notes", { max: 1000 })],
    indexes: ["CREATE UNIQUE INDEX idx_investor_deal_costs_deal ON investor_deal_costs (investor_deal)"]
  }
];

// Relations are attached after every collection has an ID, allowing forward and self links.
const relations = {
  users: [relation("customer_id", "customers"), relation("investor_id", "investors")],
  product_groups: [relation("parent_id", "product_groups")],
  products: [relation("product_group_id", "product_groups")],
  product_units: [relation("product_id", "products")],
  customers: [relation("price_group_id", "customer_price_groups")],
  pricing_profiles: [relation("product_group_ids", "product_groups", { maxSelect: 100 })],
  volume_discount_tiers: [relation("pricing_profile_id", "pricing_profiles")],
  cheque_surcharge_rules: [relation("pricing_profile_id", "pricing_profiles")],
  stock_movements: [relation("product_id", "products"), relation("warehouse_id", "warehouses"), relation("user_id", "users")],
  invoices: [relation("customer_id", "customers"), relation("supplier_id", "suppliers"), relation("investor_id", "investors"), relation("warehouse_id", "warehouses"), relation("created_by", "users")],
  invoice_items: [relation("invoice_id", "invoices"), relation("product_id", "products")],
  payments: [relation("invoice_id", "invoices"), relation("customer_id", "customers"), relation("supplier_id", "suppliers")],
  cheques: [relation("invoice_id", "invoices"), relation("investor_id", "investors")],
  investor_deals: [relation("sale_invoice_id", "invoices"), relation("customer_invoice_id", "invoices"), relation("investor_id", "investors")],
  investor_settlements: [relation("investor_id", "investors")],
  activity_log: [relation("user_id", "users")],
  sync_queue: [relation("user_id", "users")],
  product_costs: [relation("product", "products")],
  invoice_item_costs: [relation("invoice_item", "invoice_items")],
  investor_deal_costs: [relation("investor_deal", "investor_deals")]
};

function findExistingCollection(app, name) {
  try {
    return app.findCollectionByNameOrId(name);
  } catch (_) {
    return null;
  }
}

function hasField(collection, name) {
  try {
    collection.fields.getByName(name);
    return true;
  } catch (_) {
    return false;
  }
}

function newFieldFromDefinition(def) {
  const config = { ...def };
  delete config.type;
  switch (def.type) {
    case "text": return new TextField(config);
    case "number": return new NumberField(config);
    case "bool": return new BoolField(config);
    case "select": return new SelectField(config);
    case "json": return new JSONField(config);
    case "file": return new FileField(config);
    default: throw new Error(`Unsupported field type: ${def.type}`);
  }
}

migrate((app) => {
  // The 19 business collections may already have been installed manually. Reuse them
  // in place, enforce role rules, and create only missing application/support collections.
  for (const def of definitions) {
    let collection = findExistingCollection(app, def.name);
    if (!collection) {
      const config = { ...def };
      delete config.fields;
      delete config.indexes;
      collection = new Collection({ ...config, fields: def.fields || [], indexes: [] });
      app.save(collection);
      continue;
    }

    for (const ruleName of ["authRule", "listRule", "viewRule", "createRule", "updateRule", "deleteRule"]) {
      if (Object.prototype.hasOwnProperty.call(def, ruleName)) collection[ruleName] = def[ruleName];
    }
    if (def.passwordAuth && collection.type === "auth") collection.passwordAuth = def.passwordAuth;
    for (const fieldDef of def.fields || []) {
      if (!hasField(collection, fieldDef.name)) collection.fields.add(newFieldFromDefinition(fieldDef));
    }
    app.save(collection);
  }

  for (const [collectionName, fields] of Object.entries(relations)) {
    const collection = app.findCollectionByNameOrId(collectionName);
    for (const spec of fields) {
      if (hasField(collection, spec.name)) continue;
      const target = app.findCollectionByNameOrId(spec.collection);
      collection.fields.add(new RelationField({
        name: spec.name,
        collectionId: target.id,
        maxSelect: spec.maxSelect || 1,
        cascadeDelete: spec.cascadeDelete || false,
        required: spec.required || false
      }));
    }
    app.save(collection);
  }

  for (const def of definitions) {
    if (!def.indexes?.length) continue;
    const collection = app.findCollectionByNameOrId(def.name);
    for (const index of def.indexes) {
      if (!collection.indexes.includes(index)) collection.indexes.push(index);
    }
    app.save(collection);
  }
}, (_app) => {
  // Deliberately non-destructive: some of the 19 business collections may predate
  // this migration and contain production data. Use an explicit reviewed backup and
  // manual removal plan rather than cascading a rollback into customer data loss.
});
