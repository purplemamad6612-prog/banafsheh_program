// Server-side price quotation and invoice-item price guard for PocketBase >= 0.23.
// Prices are computed from private product_costs; the API never sends cost to sales,
// warehouse, customer or investor accounts. The browser is never trusted for prices.

function rateBasisPoints(percent) { return Math.round((Number(percent) || 0) * 100); }
function applyBasisPoints(amount, basisPoints) {
  const integer = Math.round(Number(amount) || 0);
  const multiplier = 10000 + basisPoints;
  const whole = Math.floor(integer / 10000);
  const remainder = integer - whole * 10000;
  return whole * multiplier + Math.round(remainder * multiplier / 10000);
}
function applyTwoRates(amount, firstPercent, secondPercent) {
  return applyBasisPoints(applyBasisPoints(amount, rateBasisPoints(firstPercent)), rateBasisPoints(secondPercent));
}
function applyPercentAmount(amount, percent) {
  const basisPoints = rateBasisPoints(percent);
  const integer = Math.round(Number(amount) || 0);
  const whole = Math.floor(integer / 10000);
  const remainder = integer - whole * 10000;
  return whole * basisPoints + Math.round(remainder * basisPoints / 10000);
}
function multiplyScaled(value, multiplier, denominator) {
  const integer = Math.round(Number(value) || 0);
  const whole = Math.floor(integer / denominator);
  const remainder = integer - whole * denominator;
  return whole * multiplier + Math.round(remainder * multiplier / denominator);
}
function multiplyPriceByFactor(price, factor) {
  return multiplyScaled(price, Math.round((Number(factor) || 0) * 1000000), 1000000);
}
function lineMoneyTotal(unitPrice, quantity) {
  return multiplyScaled(unitPrice, Math.round((Number(quantity) || 0) * 1000), 1000);
}
function roundToman(amount, rule) {
  const step = rule === "nearest_10000" ? 10000 : rule === "nearest_5000" ? 5000 : rule === "none" ? 1 : 1000;
  const integer = Math.round(Number(amount) || 0);
  const quotient = Math.floor(integer / step);
  const remainder = integer - quotient * step;
  return (remainder >= Math.ceil(step / 2) ? quotient + 1 : quotient) * step;
}
function safeFind(app, collection, filter, params) {
  try { return app.findFirstRecordByFilter(collection, filter, params || {}); }
  catch (_) { return null; }
}
function safeList(app, collection, filter, sort, limit, params) {
  try { return app.findRecordsByFilter(collection, filter, sort || "", limit || 500, 0, params || {}); }
  catch (_) { return []; }
}
function recordNumber(record, name, fallback) {
  if (!record) return fallback || 0;
  const value = Number(record.getFloat(name));
  return Number.isFinite(value) ? value : (fallback || 0);
}
function activeUnitFor(app, productId, unitName) {
  const rows = safeList(app, "product_units", "product_id = {:productId} && unit_name = {:unitName}", "-version_number", 100, { productId, unitName });
  return rows.find(row => row.getBool("is_sellable") && !row.getString("valid_to_jalali")) || rows.find(row => row.getBool("is_sellable")) || null;
}
function productPriceContext(app, product, customer) {
  const productId = product.id;
  const costRecord = safeFind(app, "product_costs", "product = {:productId}", { productId });
  if (!costRecord) throw new BadRequestError("Missing administrator cost record for a product.");
  const cost = recordNumber(costRecord, "base_cost_price", 0);
  const groupId = product.getString("product_group_id");
  const profiles = safeList(app, "pricing_profiles", "product_group_ids ?= {:groupId}", "", 100, { groupId });
  const profile = profiles[0] || null;
  const profitPercent = recordNumber(profile, "default_profit_percent", 20);
  const roundingRule = profile ? profile.getString("rounding_rule") : "nearest_1000";
  let adjustmentPercent = 0;
  if (customer) {
    const priceGroupId = customer.getString("price_group_id");
    const priceGroup = priceGroupId ? safeFind(app, "customer_price_groups", "id = {:priceGroupId}", { priceGroupId }) : null;
    adjustmentPercent = recordNumber(priceGroup, "adjustment_percent", 0);
  }
  return { cost, profile, profitPercent, roundingRule, adjustmentPercent };
}
function volumeDiscount(app, profile, amount, scope) {
  if (!profile || amount <= 0) return 0;
  const profileId = profile.id;
  const tiers = safeList(app, "volume_discount_tiers", "pricing_profile_id = {:profileId}", "min_amount", 250, { profileId });
  const matches = tiers.filter(t => t.getString("scope") === scope && amount >= recordNumber(t, "min_amount", 0) && (!recordNumber(t, "max_amount", 0) || amount <= recordNumber(t, "max_amount", 0)));
  if (!matches.length) return 0;
  return recordNumber(matches[matches.length - 1], "discount_percent", 0);
}
function chequeSurcharge(app, profile, days) {
  if (!profile || days <= 0) return 0;
  const profileId = profile.id;
  const rows = safeList(app, "cheque_surcharge_rules", "pricing_profile_id = {:profileId}", "min_days", 250, { profileId });
  const match = rows.filter(row => days >= recordNumber(row, "min_days", 0) && (!recordNumber(row, "max_days", 0) || days <= recordNumber(row, "max_days", 0))).pop();
  return recordNumber(match, "surcharge_percent", 0);
}
function calculateQuote(app, auth, body) {
  const role = auth ? auth.getString("role") : "";
  if (!["admin", "accountant", "sales", "customer"].includes(role)) throw new ForbiddenError("This role cannot request a sales quote.");
  if (!body || !Array.isArray(body.lines) || !body.lines.length) throw new BadRequestError("At least one invoice line is required.");

  const customerId = String(body.customer_id || "");
  if (role === "customer" && customerId !== auth.getString("customer_id")) throw new ForbiddenError("Customers can only request their own price.");
  const customer = customerId ? safeFind(app, "customers", "id = {:customerId}", { customerId }) : null;
  if (customerId && !customer) throw new BadRequestError("Customer was not found.");
  const mode = String(body.sale_mode || "cash");
  if (!["cash", "cheque_direct", "investor"].includes(mode)) throw new BadRequestError("Unknown sale mode.");
  const scope = body.discount_scope === "per_group" ? "per_group" : "per_invoice";
  const days = Math.max(0, Math.min(3650, Number(body.cheque_duration_days) || 0));
  const lines = [];

  for (const input of body.lines) {
    const productId = String(input.product_id || "");
    const product = safeFind(app, "products", "id = {:productId} && is_active = true", { productId });
    if (!product) throw new BadRequestError("A requested product is missing or inactive.");
    const quantity = Number(input.quantity);
    if (!Number.isFinite(quantity) || quantity <= 0) throw new BadRequestError("Line quantity must be positive.");
    const unitName = String(input.unit_name || product.getString("base_unit_name"));
    const unit = activeUnitFor(app, product.id, unitName);
    if (!unit && unitName !== product.getString("base_unit_name")) throw new BadRequestError("The requested sales unit is not currently valid.");
    const factor = unit ? recordNumber(unit, "conversion_factor", 1) : 1;
    const context = productPriceContext(app, product, customer);
    const quantityBase = Number((quantity * factor).toFixed(3));
    const basePrice = roundToman(applyTwoRates(context.cost, context.profitPercent, context.adjustmentPercent), context.roundingRule);
    const unitSellPrice = roundToman(multiplyPriceByFactor(basePrice, factor), context.roundingRule);
    const lineTotal = lineMoneyTotal(unitSellPrice, quantity);
    lines.push({
      product_id: product.id,
      product_name: product.getString("name"),
      product_group_id: product.getString("product_group_id"),
      unit_name: unitName,
      quantity,
      conversion_factor_snapshot: factor,
      quantity_in_base_unit: quantityBase,
      unit_sell_price: unitSellPrice,
      line_total: lineTotal,
      pricing_rule_source: profileLabel(context.profile),
      profile_id: context.profile ? context.profile.id : "",
      _cost: context.cost,
      _rounding: context.roundingRule
    });
  }

  const subtotal = lines.reduce((sum, line) => sum + line.line_total, 0);
  const discountRates = new Map();
  if (mode === "cash") {
    if (scope === "per_group") {
      const groups = {};
      lines.forEach(line => { groups[line.product_group_id] = (groups[line.product_group_id] || 0) + line.line_total; });
      for (const [groupId, amount] of Object.entries(groups)) {
        const profileId = lines.find(line => line.product_group_id === groupId)?.profile_id;
        const profile = profileId ? safeFind(app, "pricing_profiles", "id = {:id}", { id: profileId }) : null;
        const rate = volumeDiscount(app, profile, amount, "per_group");
        lines.filter(line => line.product_group_id === groupId).forEach(line => discountRates.set(line, rate));
      }
    } else {
      const profileIds = [...new Set(lines.map(line => line.profile_id).filter(Boolean))];
      const rates = profileIds.map(id => volumeDiscount(app, safeFind(app, "pricing_profiles", "id = {:id}", { id }), subtotal, "per_invoice"));
      const rate = rates.length ? Math.max(...rates) : 0;
      lines.forEach(line => discountRates.set(line, rate));
    }
  }
  let discountAmount = 0, surchargeAmount = 0;
  for (const line of lines) {
    const discountRate = mode === "cash" ? (discountRates.get(line) || 0) : 0;
    const surchargeRate = mode === "cash" ? 0 : chequeSurcharge(app, line.profile_id ? safeFind(app, "pricing_profiles", "id = {:id}", { id: line.profile_id }) : null, days);
    const finalUnitPrice = roundToman(applyTwoRates(line.unit_sell_price, -discountRate, surchargeRate), line._rounding);
    const finalLineTotal = lineMoneyTotal(finalUnitPrice, line.quantity);
    discountAmount += Math.max(0, line.line_total - finalLineTotal);
    surchargeAmount += Math.max(0, finalLineTotal - line.line_total);
    line.unit_sell_price = finalUnitPrice;
    line.line_total = finalLineTotal;
  }
  const total = lines.reduce((sum, line) => sum + line.line_total, 0);
  const responseLines = lines.map(line => {
    const clean = { ...line };
    delete clean._cost; delete clean._rounding; delete clean.profile_id;
    if (role === "admin") clean.unit_cost_price = multiplyPriceByFactor(line._cost, line.conversion_factor_snapshot);
    return clean;
  });
  return { lines: responseLines, subtotal, discount_amount: discountAmount, surcharge_amount: surchargeAmount, total, sale_mode: mode, discount_scope: scope, cheque_duration_days: days };
}
function profileLabel(profile) {
  return profile ? `pricing_profile:${profile.id}` : "default_pricing_profile";
}

routerAdd("POST", "/api/benafsheh/pricing/calculate", (e) => {
  const body = e.requestInfo().body || {};
  return e.json(200, calculateQuote(e.app, e.auth, body));
}, $apis.requireAuth());

// Prevent a sales user from forging a unit conversion or manually changing the
// price submitted in an invoice line. Prices are recomputed on create and update.
function applyServerPrice(app, record) {
  const productId = record.getString("product_id");
  const product = safeFind(app, "products", "id = {:productId} && is_active = true", { productId });
  if (!product) throw new BadRequestError("A valid active product is required.");
  const invoiceId = record.getString("invoice_id");
  const invoice = safeFind(app, "invoices", "id = {:invoiceId}", { invoiceId });
  if (!invoice) throw new BadRequestError("A valid invoice is required.");
  const requestedUnit = record.getString("unit_used") || product.getString("base_unit_name");
  const unit = activeUnitFor(app, product.id, requestedUnit);
  if (!unit && requestedUnit !== product.getString("base_unit_name")) throw new BadRequestError("Invalid or expired product unit.");
  const factor = unit ? recordNumber(unit, "conversion_factor", 1) : 1;
  const qty = Number(record.getFloat("quantity"));
  if (!Number.isFinite(qty) || qty <= 0) throw new BadRequestError("Line quantity must be positive.");
  const customerId = invoice.getString("customer_id");
  const customer = customerId ? safeFind(app, "customers", "id = {:customerId}", { customerId }) : null;
  const context = productPriceContext(app, product, customer);
  const qtyBase = Number((qty * factor).toFixed(3));
  const basePrice = roundToman(applyTwoRates(context.cost, context.profitPercent, context.adjustmentPercent), context.roundingRule);
  const unitPrice = roundToman(multiplyPriceByFactor(basePrice, factor), context.roundingRule);
  record.set("conversion_factor_snapshot", factor);
  record.set("quantity_in_base_unit", qtyBase);
  record.set("unit_sell_price", unitPrice);
  record.set("line_total", lineMoneyTotal(unitPrice, qty));
  record.set("pricing_rule_source", profileLabel(context.profile));
}
onRecordCreateRequest((e) => { applyServerPrice(e.app, e.record); e.next(); }, "invoice_items");
onRecordUpdateRequest((e) => { applyServerPrice(e.app, e.record); e.next(); }, "invoice_items");

// Non-admins may create a draft, but cannot forge totals or directly confirm it.
onRecordCreateRequest((e) => {
  const role = e.auth ? e.auth.getString("role") : "";
  if (role !== "admin") {
    if (["purchase", "purchase_return"].includes(e.record.getString("invoice_type"))) throw new ForbiddenError("Only administrators can create purchase invoices or returns.");
    e.record.set("status", "draft");
    e.record.set("subtotal", 0); e.record.set("discount_amount", 0);
    e.record.set("surcharge_amount", 0); e.record.set("total", 0);
  }
  e.next();
}, "invoices");
onRecordUpdateRequest((e) => {
  const role = e.auth ? e.auth.getString("role") : "";
  if (e.record.getString("status") === "confirmed" && role !== "admin") {
    throw new ForbiddenError("Use the Benafsheh invoice confirmation endpoint to finalize an invoice.");
  }
  e.next();
}, "invoices");

function signedStock(movement) {
  const amount = recordNumber(movement, "quantity_in_base_unit", 0);
  const type = movement.getString("movement_type");
  if (type === "purchase_in" || type === "transfer_in") return amount;
  if (type === "sale_out" || type === "transfer_out") return -amount;
  if (type === "adjustment") {
    const metadata = movement.get("metadata") || {};
    return metadata.direction === "decrease" || metadata.direction === -1 ? -amount : amount;
  }
  return 0;
}
function stockInWarehouse(app, productId, warehouseId) {
  const movements = safeList(app, "stock_movements", "product_id = {:productId} && warehouse_id = {:warehouseId}", "", 5000, { productId, warehouseId });
  return movements.reduce((sum, movement) => sum + signedStock(movement), 0);
}

// Expose quantities only (never financial fields) to active operational roles.
routerAdd("GET", "/api/benafsheh/stock-summary", (e) => {
  const role = e.auth ? e.auth.getString("role") : "";
  if (!e.auth || !e.auth.getBool("is_active") || !["admin", "accountant", "warehouse", "sales"].includes(role)) throw new ForbiddenError("This role cannot view stock availability.");
  const products = safeList(e.app, "products", "", "", 50000, {});
  const totals = {};
  for (const product of products) totals[product.id] = 0;
  const movements = safeList(e.app, "stock_movements", "", "", 50000, {});
  for (const movement of movements) {
    const productId = movement.getString("product_id");
    if (!productId) continue;
    totals[productId] = (totals[productId] || 0) + signedStock(movement);
  }
  return e.json(200, { stocks: Object.entries(totals).map(([product_id, stock_base]) => ({ product_id, stock_base })) });
}, $apis.requireAuth());

function newSyncId() { return "pb-" + Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 14); }

// The only non-admin path that can confirm sales. It recalculates every line,
// applies discounts/surcharges, snapshots final prices and creates stock movements
// atomically so a retry cannot partially post an invoice.
routerAdd("POST", "/api/benafsheh/invoices/{id}/confirm", (e) => {
  const role = e.auth ? e.auth.getString("role") : "";
  if (!["admin", "accountant", "sales"].includes(role)) throw new ForbiddenError("This role cannot confirm sales invoices.");
  const invoiceId = e.request.pathValue("id");
  let result = {};
  e.app.runInTransaction((txApp) => {
    const invoice = txApp.findRecordById("invoices", invoiceId);
    if (invoice.getString("status") !== "draft") throw new BadRequestError("Only draft invoices can be confirmed.");
    if (!["sale", "quote"].includes(invoice.getString("invoice_type"))) throw new BadRequestError("This endpoint confirms sales and quotes only.");
    const customerId = invoice.getString("customer_id");
    const customer = customerId ? safeFind(txApp, "customers", "id = {:customerId}", { customerId }) : null;
    if (!customer) throw new BadRequestError("A valid customer is required.");
    if (role === "sales" && invoice.getString("created_by") !== e.auth.id) throw new ForbiddenError("You can only confirm invoices you created.");
    const itemRows = safeList(txApp, "invoice_items", "invoice_id = {:invoiceId}", "created", 1000, { invoiceId });
    if (!itemRows.length) throw new BadRequestError("An invoice must contain at least one item.");
    const lines = itemRows.map(item => {
      const productId = item.getString("product_id");
      const product = txApp.findRecordById("products", productId);
      const context = productPriceContext(txApp, product, customer);
      const qty = recordNumber(item, "quantity", 0);
      const factor = recordNumber(item, "conversion_factor_snapshot", 1);
      const baseUnitPrice = roundToman(applyTwoRates(context.cost, context.profitPercent, context.adjustmentPercent), context.roundingRule);
      const rawUnitPrice = roundToman(multiplyPriceByFactor(baseUnitPrice, factor), context.roundingRule);
      return { item, product, context, qty, factor, rawUnitPrice, rawTotal: lineMoneyTotal(rawUnitPrice, qty), profile: context.profile };
    });
    const subtotal = lines.reduce((sum, line) => sum + line.rawTotal, 0);
    const mode = invoice.getString("sale_mode") || "cash";
    const scope = invoice.getString("discount_scope") || "per_invoice";
    const days = recordNumber(invoice, "cheque_duration_days", 0);
    const discountRates = new Map();
    if (mode === "cash") {
      if (scope === "per_group") {
        const groupTotals = {};
        lines.forEach(line => { const group = line.product.getString("product_group_id"); groupTotals[group] = (groupTotals[group] || 0) + line.rawTotal; });
        for (const [groupId, amount] of Object.entries(groupTotals)) {
          const context = lines.find(line => line.product.getString("product_group_id") === groupId)?.context;
          const rate = volumeDiscount(txApp, context?.profile || null, amount, "per_group");
          lines.filter(line => line.product.getString("product_group_id") === groupId).forEach(line => discountRates.set(line.item.id, rate));
        }
      } else {
        const profile = lines[0].profile;
        const rate = volumeDiscount(txApp, profile, subtotal, "per_invoice");
        lines.forEach(line => discountRates.set(line.item.id, rate));
      }
    }
    let finalTotal = 0, discountAmount = 0, surchargeAmount = 0;
    for (const line of lines) {
      const discountRate = mode === "cash" ? (discountRates.get(line.item.id) || 0) : 0;
      const surchargeRate = mode === "cash" ? 0 : chequeSurcharge(txApp, line.profile, days);
      const finalUnitPrice = roundToman(applyTwoRates(line.rawUnitPrice, -discountRate, surchargeRate), line.context.roundingRule);
      const finalLineTotal = lineMoneyTotal(finalUnitPrice, line.qty);
      line.item.set("unit_sell_price", finalUnitPrice);
      line.item.set("line_total", finalLineTotal);
      txApp.save(line.item);
      finalTotal += finalLineTotal;
      discountAmount += Math.max(0, line.rawTotal - finalLineTotal);
      surchargeAmount += Math.max(0, finalLineTotal - line.rawTotal);
    }
    const invoiceType = invoice.getString("invoice_type");
    const warehouseId = invoice.getString("warehouse_id");
    if (invoiceType === "sale") {
      if (!warehouseId) throw new BadRequestError("A warehouse is required before stock can be deducted.");
      const demand = {};
      lines.forEach(line => { demand[line.product.id] = (demand[line.product.id] || 0) + recordNumber(line.item, "quantity_in_base_unit", 0); });
      for (const [productId, quantity] of Object.entries(demand)) {
        if (stockInWarehouse(txApp, productId, warehouseId) < quantity) throw new BadRequestError("Insufficient stock for one or more invoice items.");
      }
      const movements = txApp.findCollectionByNameOrId("stock_movements");
      for (const line of lines) {
        const movement = new Record(movements);
        movement.set("product_id", line.product.id);
        movement.set("warehouse_id", warehouseId);
        movement.set("movement_type", "sale_out");
        movement.set("quantity_in_base_unit", recordNumber(line.item, "quantity_in_base_unit", 0));
        movement.set("unit_used", line.item.getString("unit_used"));
        movement.set("quantity_in_used_unit", line.qty);
        movement.set("conversion_factor_used", line.factor);
        movement.set("reference_document_id", invoice.getString("invoice_number"));
        movement.set("reference_document_type", "invoice");
        movement.set("business_date_jalali", invoice.getString("invoice_date_jalali"));
        movement.set("sync_id", newSyncId());
        movement.set("user_id", e.auth.id);
        txApp.save(movement);
      }
      customer.set("current_balance", recordNumber(customer, "current_balance", 0) + finalTotal);
      txApp.save(customer);
    }
    invoice.set("subtotal", subtotal);
    invoice.set("discount_amount", discountAmount);
    invoice.set("surcharge_amount", surchargeAmount);
    invoice.set("total", finalTotal);
    invoice.set("stock_posted", invoiceType === "sale");
    invoice.set("status", "confirmed");
    txApp.save(invoice);
    result = { id: invoice.id, invoice_number: invoice.getString("invoice_number"), subtotal, discount_amount: discountAmount, surcharge_amount: surchargeAmount, total: finalTotal, status: "confirmed", stock_posted: invoiceType === "sale" };
  });
  return e.json(200, result);
}, $apis.requireAuth());

// Validate offline payloads and apply stock movements idempotently on the server.
// The device can submit only warehouse movement data; cost/price fields are rejected.
function syncPayloadValue(record) {
  let value = record.get("payload");
  if (typeof value === "string") { try { value = JSON.parse(value); } catch (_) { value = null; } }
  if (Array.isArray(value)) { try { value = JSON.parse(toString(value)); } catch (_) { value = null; } }
  return value && typeof value === "object" ? value : null;
}
onRecordCreateRequest((e) => {
  const payload = syncPayloadValue(e.record);
  if (!payload) throw new BadRequestError("Invalid offline payload.");
  const allowed = ["id", "syncId", "productId", "productCode", "productName", "warehouse", "warehouseId", "destinationWarehouse", "type", "quantityBase", "unit", "quantity", "factor", "direction", "date", "user", "reference", "synced", "clientTimestamp"];
  if (Object.keys(payload).some(key => !allowed.includes(key))) throw new ForbiddenError("Offline payload contains unsupported fields.");
  if (!payload.syncId || payload.syncId !== e.record.getString("sync_id")) throw new BadRequestError("Offline idempotency key mismatch.");
  if (!["purchase_in", "sale_out", "transfer_in", "transfer_out", "adjustment"].includes(payload.type)) throw new BadRequestError("Unsupported stock operation.");
  const quantity = Number(payload.quantityBase);
  const factor = Number(payload.factor);
  if (!Number.isFinite(quantity) || quantity <= 0 || !Number.isFinite(factor) || factor <= 0) throw new BadRequestError("Invalid offline quantity or conversion factor.");
  if (!payload.productId && !payload.productCode) throw new BadRequestError("Offline movement needs a product ID or code.");
  if (!payload.warehouse && !payload.warehouseId) throw new BadRequestError("Offline movement needs a warehouse.");
  if ((payload.type === "transfer_in" || payload.type === "transfer_out") && !payload.destinationWarehouse) throw new BadRequestError("Transfer movement needs a destination/source warehouse.");
  // Never trust a client-supplied status: otherwise a failed movement could be
  // discarded locally as if it had synced successfully.
  e.record.set("synced_at", "");
  e.record.set("conflict", false);
  e.record.set("error_message", "");
  e.next();
}, "sync_queue");

function resolveSyncWarehouse(app, id, name) {
  let warehouse = null;
  if (id) warehouse = safeFind(app, "warehouses", "id = {:id}", { id: String(id) });
  if (!warehouse && name) warehouse = safeFind(app, "warehouses", "name = {:name}", { name: String(name) });
  return warehouse;
}
function saveSyncMovement(app, queue, product, warehouse, payload, type, syncId) {
  let movement = safeFind(app, "stock_movements", "sync_id = {:syncId}", { syncId });
  if (movement) return movement;
  const movements = app.findCollectionByNameOrId("stock_movements");
  movement = new Record(movements);
  movement.set("product_id", product.id);
  movement.set("warehouse_id", warehouse.id);
  movement.set("movement_type", type);
  movement.set("quantity_in_base_unit", Number(payload.quantityBase));
  movement.set("unit_used", String(payload.unit || product.getString("base_unit_name")));
  movement.set("quantity_in_used_unit", Number(payload.quantity) || Number(payload.quantityBase));
  movement.set("conversion_factor_used", Number(payload.factor) || 1);
  movement.set("reference_document_id", String(payload.reference || ""));
  movement.set("reference_document_type", type.startsWith("transfer_") ? "transfer" : "other");
  movement.set("business_date_jalali", String(payload.date || ""));
  movement.set("sync_id", syncId);
  movement.set("user_id", queue.getString("user_id"));
  movement.set("metadata", { direction: payload.direction || "increase", device_timestamp: payload.clientTimestamp || "", server_received_at: new Date().toISOString(), timestamp_authority: "server" });
  app.save(movement);
  return movement;
}
function processSyncQueue(app, queue) {
  try {
    const syncId = queue.getString("sync_id");
    const payload = syncPayloadValue(queue);
    if (!payload) throw new Error("Invalid offline payload.");
    let product = null;
    if (payload.productId) product = safeFind(app, "products", "id = {:id}", { id: String(payload.productId) });
    if (!product && payload.productCode) product = safeFind(app, "products", "code = {:code}", { code: String(payload.productCode) });
    if (!product) throw new Error("کالای این عملیات در سرور پیدا نشد؛ کد کالا را تطبیق دهید.");

    const type = String(payload.type);
    const quantity = Number(payload.quantityBase);
    if (type === "transfer_in" || type === "transfer_out") {
      const sourceName = payload.warehouse;
      const destinationName = payload.destinationWarehouse;
      const source = resolveSyncWarehouse(app, payload.warehouseId, sourceName);
      const destination = resolveSyncWarehouse(app, "", destinationName);
      if (!source || !destination) throw new Error("انبار مبدأ یا مقصد در سرور پیدا نشد.");
      if (source.id === destination.id) throw new Error("انبار مبدأ و مقصد انتقال باید متفاوت باشند.");
      app.runInTransaction((txApp) => {
        const outSyncId = type === "transfer_out" ? syncId : `${syncId}-out`;
        const inSyncId = type === "transfer_in" ? syncId : `${syncId}-in`;
        const existingOut = safeFind(txApp, "stock_movements", "sync_id = {:syncId}", { syncId: outSyncId });
        if (!existingOut && stockInWarehouse(txApp, product.id, source.id) < quantity) throw new Error("موجودی انبار مبدأ برای انتقال کافی نیست.");
        saveSyncMovement(txApp, queue, product, source, payload, "transfer_out", outSyncId);
        saveSyncMovement(txApp, queue, product, destination, payload, "transfer_in", inSyncId);
      });
    } else {
      const warehouse = resolveSyncWarehouse(app, payload.warehouseId, payload.warehouse);
      if (!warehouse) throw new Error("انبار متناظر در سرور پیدا نشد.");
      app.runInTransaction((txApp) => {
        const existing = safeFind(txApp, "stock_movements", "sync_id = {:syncId}", { syncId });
        if (existing) return;
        if (["sale_out", "adjustment"].includes(type) && (type !== "adjustment" || payload.direction === "decrease")) {
          if (stockInWarehouse(txApp, product.id, warehouse.id) < quantity) throw new Error("موجودی سرور برای این حواله کافی نیست.");
        }
        saveSyncMovement(txApp, queue, product, warehouse, payload, type, syncId);
      });
    }

    const clientTime = Date.parse(String(payload.clientTimestamp || ""));
    queue.set("synced_at", new Date().toISOString());
    queue.set("conflict", Number.isFinite(clientTime) && Math.abs(Date.now() - clientTime) > 60000);
    queue.set("error_message", "");
    app.save(queue);
    return true;
  } catch (error) {
    queue.set("error_message", String(error?.message || error).slice(0, 480));
    queue.set("conflict", true);
    try { app.save(queue); } catch (_) { /* keep the original record and report on retry */ }
    return false;
  }
}
onRecordAfterCreateSuccess((e) => {
  processSyncQueue(e.app, e.record);
  e.next();
}, "sync_queue");

routerAdd("POST", "/api/benafsheh/sync-queue/{id}/retry", (e) => {
  const role = e.auth ? e.auth.getString("role") : "";
  if (!["admin", "warehouse"].includes(role)) throw new ForbiddenError("Only an administrator or warehouse user can retry stock sync.");
  const queue = e.app.findRecordById("sync_queue", e.request.pathValue("id"));
  if (role === "warehouse" && queue.getString("user_id") !== e.auth.id) throw new ForbiddenError("You can only retry your own offline movements.");
  const ok = processSyncQueue(e.app, queue);
  return e.json(ok ? 200 : 409, { id: queue.id, synced_at: queue.getString("synced_at"), conflict: queue.getBool("conflict"), error_message: queue.getString("error_message") });
}, $apis.requireAuth());

// Store purchase-price-at-sale privately after a line is created. This collection
// is inaccessible to non-admin users through the public PocketBase API rules.
onRecordAfterCreateSuccess((e) => {
  const item = e.record;
  const productId = item.getString("product_id");
  const product = safeFind(e.app, "products", "id = {:productId}", { productId });
  const cost = product ? safeFind(e.app, "product_costs", "product = {:productId}", { productId }) : null;
  if (item && cost) {
    const collection = e.app.findCollectionByNameOrId("invoice_item_costs");
    const privateCost = new Record(collection);
    privateCost.set("invoice_item", item.id);
    privateCost.set("unit_cost_price", multiplyPriceByFactor(recordNumber(cost, "base_cost_price", 0), recordNumber(item, "conversion_factor_snapshot", 1)));
    privateCost.set("cost_total", lineMoneyTotal(recordNumber(cost, "base_cost_price", 0), recordNumber(item, "quantity_in_base_unit", 0)));
    e.app.save(privateCost);
  }
  e.next();
}, "invoice_items");
