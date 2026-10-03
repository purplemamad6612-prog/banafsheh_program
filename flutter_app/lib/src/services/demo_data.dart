import '../models/app_enums.dart';
import '../models/product.dart';

class DemoData {
  const DemoData._();

  static const demoInvestorId = 'investor-1';
  static const demoCustomerId = 'customer-1';

  static List<JsonMap> records(String collection, AppRole role) {
    final rows = switch (collection) {
      'warehouses' => _warehouses,
      'product_groups' => _productGroups,
      'products' => _products,
      'product_units' => _units,
      'customer_price_groups' => _customerPriceGroups,
      'customers' => _customers,
      'suppliers' => _suppliers,
      'pricing_profiles' => _pricingProfiles,
      'volume_discount_tiers' => _volumeTiers,
      'cheque_surcharge_rules' => _chequeRules,
      'stock_movements' => _movements,
      'investors' => _investors,
      'invoices' => _invoices,
      'invoice_items' => _invoiceItems,
      'payments' => _payments,
      'cheques' => _cheques,
      'investor_deals' => _deals,
      'investor_settlements' => _settlements,
      'settings' => _settings,
      'suppliers_costs' => const <JsonMap>[],
      _ => const <JsonMap>[],
    };
    final copied = rows.map((item) => Map<String, dynamic>.from(item)).toList();
    if (role == AppRole.investor) {
      if (collection == 'investors') return copied.where((row) => row['id'] == demoInvestorId).toList();
      if (collection == 'investor_deals' || collection == 'cheques' || collection == 'investor_settlements') {
        return copied.where((row) => row['investor_id'] == demoInvestorId).toList();
      }
      if (collection == 'invoices' || collection == 'invoice_items' || collection == 'payments') return const <JsonMap>[];
      if (collection == 'customers' || collection == 'suppliers') return const <JsonMap>[];
    }
    if (role == AppRole.customer) {
      if (collection == 'customers') return copied.where((row) => row['id'] == demoCustomerId).toList();
      if (collection == 'invoices') return copied.where((row) => row['customer_id'] == demoCustomerId && row['invoice_type'] != 'purchase').toList();
      if (collection == 'invoice_items') return copied.where((row) => row['customer_id'] == demoCustomerId).toList();
      if (collection == 'payments' || collection == 'cheques') return copied.where((row) => row['customer_id'] == demoCustomerId).toList();
      if (collection == 'customers' || collection == 'suppliers' || collection == 'investors' || collection == 'investor_deals') return const <JsonMap>[];
    }
    if (role != AppRole.admin && (collection == 'invoices' || collection == 'invoice_items')) {
      return copied.where((row) => row['invoice_type'] != 'purchase' && row['invoice_type'] != 'purchase_return').toList();
    }
    if (role == AppRole.warehouse && (collection == 'customers' || collection == 'suppliers' || collection == 'investors' || collection == 'invoices' || collection == 'cheques')) {
      return const <JsonMap>[];
    }
    return copied;
  }

  static const List<JsonMap> _warehouses = [
    {'id': 'wh-main', 'name': 'انبار مرکزی', 'address': 'تهران، جاده مخصوص', 'is_active': true},
    {'id': 'wh-west', 'name': 'انبار شعبه غرب', 'address': 'تهران، شهرک غرب', 'is_active': true},
    {'id': 'wh-showroom', 'name': 'انبار شوروم', 'address': 'تهران، ستارخان', 'is_active': true},
  ];

  static const List<JsonMap> _productGroups = [
    {'id': 'group-profile', 'name': 'پروفیل فریم', 'is_active': true},
    {'id': 'group-hardware', 'name': 'یراق‌آلات', 'is_active': true},
    {'id': 'group-seal', 'name': 'نوار و لاستیک', 'is_active': true},
  ];

  static const List<JsonMap> _products = [
    {'id': 'product-60', 'code': 'PR-060-GD', 'name': 'پروفیل ۶۰ گلدویین', 'base_unit_name': 'شاخه', 'product_group_id': 'group-profile', 'group_name': 'پروفیل فریم', 'stock_base': 876, 'min_stock': 180, 'demo_sell_price_toman': 1770000, 'warehouse_id': 'wh-main', 'is_active': true, 'units': [{'id': 'unit-60-branch', 'unit_name': 'شاخه', 'conversion_factor': 1, 'version_number': 1, 'is_sellable': true}, {'id': 'unit-60-meter', 'unit_name': 'متر', 'conversion_factor': 0.1667, 'version_number': 1, 'is_sellable': true}, {'id': 'unit-60-pack', 'unit_name': 'بسته', 'conversion_factor': 25, 'version_number': 2, 'is_sellable': true}]},
    {'id': 'product-70', 'code': 'PR-070-WH', 'name': 'پروفیل ۷۰ سفید', 'base_unit_name': 'شاخه', 'product_group_id': 'group-profile', 'group_name': 'پروفیل فریم', 'stock_base': 93, 'min_stock': 120, 'demo_sell_price_toman': 2220000, 'warehouse_id': 'wh-main', 'is_active': true, 'units': [{'id': 'unit-70-branch', 'unit_name': 'شاخه', 'conversion_factor': 1, 'version_number': 1, 'is_sellable': true}, {'id': 'unit-70-meter', 'unit_name': 'متر', 'conversion_factor': 0.1667, 'version_number': 1, 'is_sellable': true}, {'id': 'unit-70-pack', 'unit_name': 'بسته', 'conversion_factor': 20, 'version_number': 1, 'is_sellable': true}]},
    {'id': 'product-glass', 'code': 'GL-4-CLR', 'name': 'شیشه دوجداره ۴ میل', 'base_unit_name': 'مترمربع', 'product_group_id': 'group-profile', 'group_name': 'شیشه و ملزومات', 'stock_base': 62, 'min_stock': 50, 'demo_sell_price_toman': 1439000, 'warehouse_id': 'wh-west', 'is_active': true, 'units': [{'id': 'unit-glass-m2', 'unit_name': 'مترمربع', 'conversion_factor': 1, 'version_number': 1, 'is_sellable': true}, {'id': 'unit-glass-sheet', 'unit_name': 'ورق', 'conversion_factor': 4.5, 'version_number': 1, 'is_sellable': true}]},
    {'id': 'product-hinge', 'code': 'HW-HNG-3D', 'name': 'لولا سه‌بعدی ترک', 'base_unit_name': 'عدد', 'product_group_id': 'group-hardware', 'group_name': 'یراق‌آلات', 'stock_base': 44, 'min_stock': 60, 'demo_sell_price_toman': 354000, 'warehouse_id': 'wh-main', 'is_active': true, 'units': [{'id': 'unit-hinge-piece', 'unit_name': 'عدد', 'conversion_factor': 1, 'version_number': 1, 'is_sellable': true}, {'id': 'unit-hinge-pack', 'unit_name': 'بسته', 'conversion_factor': 10, 'version_number': 1, 'is_sellable': true}]},
    {'id': 'product-seal', 'code': 'GSK-EPDM', 'name': 'لاستیک EPDM مشکی', 'base_unit_name': 'کیلو', 'product_group_id': 'group-seal', 'group_name': 'نوار و لاستیک', 'stock_base': 176, 'min_stock': 80, 'demo_sell_price_toman': 458000, 'warehouse_id': 'wh-west', 'is_active': true, 'units': [{'id': 'unit-seal-kg', 'unit_name': 'کیلو', 'conversion_factor': 1, 'version_number': 1, 'is_sellable': true}, {'id': 'unit-seal-coil', 'unit_name': 'کلاف', 'conversion_factor': 15, 'version_number': 1, 'is_sellable': true}]},
  ];

  static const List<JsonMap> _units = [
    {'id': 'unit-60-branch', 'product_id': 'product-60', 'unit_name': 'شاخه', 'conversion_factor': 1, 'version_number': 1, 'is_sellable': true},
    {'id': 'unit-60-meter', 'product_id': 'product-60', 'unit_name': 'متر', 'conversion_factor': 0.1667, 'version_number': 1, 'is_sellable': true},
    {'id': 'unit-60-pack', 'product_id': 'product-60', 'unit_name': 'بسته', 'conversion_factor': 25, 'version_number': 2, 'is_sellable': true},
  ];

  static const List<JsonMap> _customerPriceGroups = [
    {'id': 'pricegroup-partner', 'name': 'همکاران', 'adjustment_percent': -1.0},
    {'id': 'pricegroup-special', 'name': 'همکاران ویژه', 'adjustment_percent': -2.0},
  ];

  static const List<JsonMap> _customers = [
    {'id': 'customer-1', 'code': 'C-1042', 'name': 'شرکت پنجره‌سازان آریا', 'phone': '۰۲۱-۴۴۴۲۱۲۸۰', 'customer_type': 'wholesale', 'current_balance': 36800000, 'credit_limit': 250000000, 'address': 'تهران', 'is_active': true},
    {'id': 'customer-2', 'code': 'C-1088', 'name': 'فروشگاه خانه مدرن', 'phone': '۰۲۱-۸۸۴۳۱۰۲۴', 'customer_type': 'wholesale', 'current_balance': 12850000, 'credit_limit': 120000000, 'address': 'تهران', 'is_active': true},
    {'id': 'customer-3', 'code': 'C-1116', 'name': 'آقای محمد امینی', 'phone': '۰۹۱۲۷۳۸۴۱۵۰', 'customer_type': 'retail', 'current_balance': 0, 'credit_limit': 30000000, 'address': 'کرج', 'is_active': true},
  ];

  static const List<JsonMap> _suppliers = [
    {'id': 'supplier-1', 'name': 'بازرگانی آذر پروفیل', 'phone': '۰۲۱-۶۶۱۲۸۳۹۰', 'address': 'تهران، شهرک صنعتی غرب', 'notes': 'تأمین پروفیل'},
    {'id': 'supplier-2', 'name': 'یراق‌آلات آریا', 'phone': '۰۲۱-۵۵۶۷۳۲۱۸', 'address': 'تهران، بازار آهن', 'notes': 'تأمین یراق'},
  ];

  static const List<JsonMap> _pricingProfiles = [
    {'id': 'pricing-profile-1', 'name': 'پروفیل فریم', 'default_profit_percent': 22, 'rounding_rule': 'nearest_1000'},
  ];
  static const List<JsonMap> _volumeTiers = [
    {'id': 'tier-20m', 'min_amount': 20000000, 'max_amount': 50000000, 'discount_percent': 1, 'scope': 'per_invoice'},
    {'id': 'tier-50m', 'min_amount': 50000000, 'max_amount': 100000000, 'discount_percent': 2, 'scope': 'per_invoice'},
    {'id': 'tier-100m', 'min_amount': 100000000, 'max_amount': 0, 'discount_percent': 3, 'scope': 'per_invoice'},
  ];
  static const List<JsonMap> _chequeRules = [
    {'id': 'cheque-30', 'min_days': 30, 'max_days': 59, 'surcharge_percent': 2},
    {'id': 'cheque-60', 'min_days': 60, 'max_days': 89, 'surcharge_percent': 3},
    {'id': 'cheque-90', 'min_days': 90, 'max_days': 3650, 'surcharge_percent': 5},
  ];

  static const List<JsonMap> _movements = [
    {'id': 'movement-1', 'product_id': 'product-60', 'movement_type': 'sale_out', 'quantity_in_base_unit': 25, 'unit_used': 'شاخه', 'quantity_in_used_unit': 25, 'conversion_factor_used': 1, 'business_date_jalali': '۱۴۰۵/۰۷/۱۱', 'warehouse_id': 'wh-main', 'sync_id': 'demo-sync-1'},
    {'id': 'movement-2', 'product_id': 'product-hinge', 'movement_type': 'transfer_out', 'quantity_in_base_unit': 12, 'unit_used': 'عدد', 'quantity_in_used_unit': 12, 'conversion_factor_used': 1, 'business_date_jalali': '۱۴۰۵/۰۷/۱۰', 'warehouse_id': 'wh-main', 'sync_id': 'demo-sync-2'},
  ];

  static const List<JsonMap> _investors = [
    {'id': 'investor-1', 'name': 'شرکت سرمایه‌گذاری آریا', 'phone': '۰۲۱-۸۸۷۳۲۱۱۰', 'is_active': true},
    {'id': 'investor-2', 'name': 'آقای فرهاد موسوی', 'phone': '۰۹۱۲۴۵۳۸۱۲۰', 'is_active': true},
  ];

  static const List<JsonMap> _invoices = [
    {'id': 'invoice-82', 'invoice_number': '۱۴۰۵-۰۰۸۲', 'invoice_type': 'sale', 'customer_id': 'customer-1', 'customer_name': 'شرکت پنجره‌سازان آریا', 'invoice_date_jalali': '۱۴۰۵/۰۷/۱۱', 'status': 'confirmed', 'sale_mode': 'cash', 'subtotal': 23850000, 'discount_amount': 477000, 'surcharge_amount': 0, 'total': 23373000},
    {'id': 'invoice-81', 'invoice_number': '۱۴۰۵-۰۰۸۱', 'invoice_type': 'sale', 'customer_id': 'customer-2', 'customer_name': 'فروشگاه خانه مدرن', 'invoice_date_jalali': '۱۴۰۵/۰۷/۱۰', 'status': 'confirmed', 'sale_mode': 'cheque_direct', 'subtotal': 46200000, 'discount_amount': 0, 'surcharge_amount': 924000, 'total': 47124000},
    {'id': 'invoice-77', 'invoice_number': '۱۴۰۵-۰۰۷۷', 'invoice_type': 'purchase', 'customer_id': 'supplier-1', 'customer_name': 'بازرگانی آذر پروفیل', 'invoice_date_jalali': '۱۴۰۵/۰۷/۰۸', 'status': 'confirmed', 'sale_mode': 'cash', 'subtotal': 78500000, 'discount_amount': 0, 'surcharge_amount': 0, 'total': 78500000},
  ];
  static const List<JsonMap> _invoiceItems = [
    {'id': 'line-1', 'invoice_id': 'invoice-82', 'customer_id': 'customer-1', 'product_id': 'product-60', 'product_name': 'پروفیل ۶۰ گلدویین', 'unit_used': 'شاخه', 'quantity': 25, 'conversion_factor_snapshot': 1, 'quantity_in_base_unit': 25, 'unit_sell_price': 1770000, 'line_total': 44250000},
  ];
  static const List<JsonMap> _payments = [
    {'id': 'payment-1', 'customer_id': 'customer-1', 'payment_type': 'cash', 'amount': 10000000, 'payment_date_jalali': '۱۴۰۵/۰۷/۱۱', 'reference_number': 'رسید ۲۵۱'},
  ];
  static const List<JsonMap> _cheques = [
    {'id': 'cheque-1', 'cheque_number': '۶۲۴۸۳۱', 'bank_name': 'ملت', 'amount': 32500000, 'due_date_jalali': '۱۴۰۵/۰۷/۱۳', 'status': 'in_hand', 'cheque_type': 'received', 'customer_id': 'customer-1'},
    {'id': 'cheque-2', 'cheque_number': '۷۲۰۵۵۱', 'bank_name': 'سامان', 'amount': 12700000, 'due_date_jalali': '۱۴۰۵/۰۷/۲۰', 'status': 'transferred', 'cheque_type': 'received', 'investor_id': 'investor-1', 'holder': 'investor'},
  ];
  static const List<JsonMap> _deals = [
    {'id': 'deal-1', 'investor_id': 'investor-1', 'customer_name': 'پروژه مسکونی پارک وی', 'deal_date_jalali': '۱۴۰۵/۰۷/۱۰', 'benafsheh_sell_price': 51200000, 'customer_sell_price': 57886000, 'investor_profit': 6686000, 'status': 'open'},
    {'id': 'deal-2', 'investor_id': 'investor-2', 'customer_name': 'تولیدی پنجره آفتاب', 'deal_date_jalali': '۱۴۰۵/۰۷/۰۸', 'benafsheh_sell_price': 33800000, 'customer_sell_price': 37400000, 'investor_profit': 3600000, 'status': 'settled'},
  ];
  static const List<JsonMap> _settlements = [
    {'id': 'settlement-1', 'investor_id': 'investor-1', 'settlement_type': 'cash', 'amount': 2000000, 'settlement_date_jalali': '۱۴۰۵/۰۷/۰۵'},
  ];
  static const List<JsonMap> _settings = [
    {'id': 'setting-1', 'key': 'default_rounding_rule', 'value': 'nearest_1000'},
  ];
}
