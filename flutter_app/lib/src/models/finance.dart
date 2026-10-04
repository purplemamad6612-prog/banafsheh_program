import 'product.dart';

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.code,
    required this.phone,
    required this.balanceToman,
    required this.creditLimitToman,
    this.customerType = 'wholesale',
    this.address = '',
  });

  final String id;
  final String name;
  final String code;
  final String phone;
  final int balanceToman;
  final int creditLimitToman;
  final String customerType;
  final String address;

  factory Customer.fromMap(JsonMap map) => Customer(
        id: asString(map['id']),
        name: asString(map['name']),
        code: asString(map['code']),
        phone: asString(map['phone']),
        balanceToman: asInt(map['current_balance'] ?? map['balance_toman']),
        creditLimitToman: asInt(map['credit_limit']),
        customerType: asString(map['customer_type'], fallback: 'wholesale'),
        address: asString(map['address']),
      );
}

class InvoiceLine {
  const InvoiceLine({
    required this.productId,
    required this.productName,
    required this.unitName,
    required this.quantityMilli,
    required this.conversionFactorMicros,
    required this.quantityBaseMilli,
    required this.unitSellPriceToman,
    required this.lineTotalToman,
    this.pricingRuleSource = '',
  });

  final String productId;
  final String productName;
  final String unitName;
  final int quantityMilli;
  final int conversionFactorMicros;
  final int quantityBaseMilli;
  final int unitSellPriceToman;
  final int lineTotalToman;
  final String pricingRuleSource;

  factory InvoiceLine.fromMap(JsonMap map) => InvoiceLine(
        productId: asString(map['product_id']),
        productName: asString(map['product_name']),
        unitName: asString(map['unit_name'] ?? map['unit_used']),
        quantityMilli: (asDouble(map['quantity']) * 1000).round(),
        conversionFactorMicros: (asDouble(map['conversion_factor_snapshot']) * 1000000).round(),
        quantityBaseMilli: (asDouble(map['quantity_in_base_unit']) * 1000).round(),
        unitSellPriceToman: asInt(map['unit_sell_price']),
        lineTotalToman: asInt(map['line_total']),
        pricingRuleSource: asString(map['pricing_rule_source']),
      );
}

class Invoice {
  const Invoice({
    required this.id,
    required this.number,
    required this.type,
    required this.customerId,
    required this.customerName,
    required this.dateJalali,
    required this.status,
    required this.totalToman,
    this.saleMode = 'cash',
    this.discountScope = 'per_invoice',
    this.chequeDurationDays = 0,
    this.warehouseId = '',
    this.investorId = '',
    this.createdBy = '',
    this.notes = '',
    this.discountToman = 0,
    this.surchargeToman = 0,
    this.items = const [],
  });

  final String id;
  final String number;
  final String type;
  final String customerId;
  final String customerName;
  final String dateJalali;
  final String status;
  final int totalToman;
  final String saleMode;
  final String discountScope;
  final int chequeDurationDays;
  final String warehouseId;
  final String investorId;
  final String createdBy;
  final String notes;
  final int discountToman;
  final int surchargeToman;
  final List<InvoiceLine> items;

  factory Invoice.fromMap(JsonMap map) {
    final rawItems = map['items'];
    return Invoice(
      id: asString(map['id']),
      number: asString(map['invoice_number'] ?? map['number']),
      type: asString(map['invoice_type'] ?? map['type'], fallback: 'sale'),
      customerId: asString(map['customer_id']),
      customerName: asString(map['customer_name']),
      dateJalali: asString(map['invoice_date_jalali'] ?? map['date']),
      status: asString(map['status'], fallback: 'draft'),
      totalToman: asInt(map['total']),
      saleMode: asString(map['sale_mode'], fallback: 'cash'),
      discountScope: asString(map['discount_scope'], fallback: 'per_invoice'),
      chequeDurationDays: asInt(map['cheque_duration_days']),
      warehouseId: asString(map['warehouse_id']),
      investorId: asString(map['investor_id']),
      createdBy: asString(map['created_by']),
      notes: asString(map['notes']),
      discountToman: asInt(map['discount_amount']),
      surchargeToman: asInt(map['surcharge_amount']),
      items: rawItems is List
          ? rawItems.whereType<Map>().map((item) => InvoiceLine.fromMap(Map<String, dynamic>.from(item))).toList()
          : const [],
    );
  }
}

class Cheque {
  const Cheque({
    required this.id,
    required this.number,
    required this.bank,
    required this.amountToman,
    required this.dueDateJalali,
    required this.status,
    required this.type,
    this.partyName = '',
    this.relatedPartyId = '',
    this.investorId = '',
    this.notes = '',
  });

  final String id;
  final String number;
  final String bank;
  final int amountToman;
  final String dueDateJalali;
  final String status;
  final String type;
  final String partyName;
  final String relatedPartyId;
  final String investorId;
  final String notes;

  factory Cheque.fromMap(JsonMap map) => Cheque(
        id: asString(map['id']),
        number: asString(map['cheque_number'] ?? map['number']),
        bank: asString(map['bank_name'] ?? map['bank']),
        amountToman: asInt(map['amount']),
        dueDateJalali: asString(map['due_date_jalali'] ?? map['due']),
        status: asString(map['status'], fallback: 'in_hand'),
        type: asString(map['cheque_type'] ?? map['type'], fallback: 'received'),
        partyName: asString(map['party_name'] ?? map['related_party_name']),
        relatedPartyId: asString(map['related_party_id'] ?? map['customer_id']),
        investorId: asString(map['investor_id']),
        notes: asString(map['notes']),
      );
}

class InvestorDeal {
  const InvestorDeal({
    required this.id,
    required this.investorId,
    required this.customerName,
    this.customerInvoiceId = '',
    required this.dealDateJalali,
    required this.benafshehSellToman,
    required this.customerSellToman,
    required this.investorProfitToman,
    required this.status,
  });

  final String id;
  final String investorId;
  final String customerName;
  final String customerInvoiceId;
  final String dealDateJalali;
  final int benafshehSellToman;
  final int customerSellToman;
  final int investorProfitToman;
  final String status;

  factory InvestorDeal.fromMap(JsonMap map) => InvestorDeal(
        id: asString(map['id']),
        investorId: asString(map['investor_id']),
        customerName: asString(map['customer_name']),
        customerInvoiceId: asString(map['customer_invoice_id']),
        dealDateJalali: asString(map['deal_date_jalali']),
        benafshehSellToman: asInt(map['benafsheh_sell_price']),
        customerSellToman: asInt(map['customer_sell_price']),
        investorProfitToman: asInt(map['investor_profit']),
        status: asString(map['status'], fallback: 'open'),
      );
}

class LedgerEntry {
  const LedgerEntry({
    required this.dateJalali,
    required this.description,
    required this.reference,
    required this.debitToman,
    required this.creditToman,
  });

  final String dateJalali;
  final String description;
  final String reference;
  final int debitToman;
  final int creditToman;
}
