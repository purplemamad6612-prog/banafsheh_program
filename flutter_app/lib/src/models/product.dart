typedef JsonMap = Map<String, dynamic>;

int asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double asDouble(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

String asString(Object? value, {String fallback = ''}) =>
    value == null ? fallback : value.toString();

class ProductUnit {
  const ProductUnit({
    required this.id,
    required this.name,
    required this.factor,
    this.version = 1,
    this.isSellable = true,
    this.validToJalali = '',
  });

  final String id;
  final String name;
  final double factor;
  final int version;
  final bool isSellable;
  final String validToJalali;

  bool get isActive => validToJalali.isEmpty;

  factory ProductUnit.fromMap(JsonMap map) => ProductUnit(
        id: asString(map['id']),
        name: asString(map['unit_name'] ?? map['name'], fallback: 'عدد'),
        factor: asDouble(map['conversion_factor'] ?? map['factor'], fallback: 1),
        version: asInt(map['version_number'] ?? map['version'], fallback: 1),
        isSellable: map['is_sellable'] != false,
        validToJalali: asString(map['valid_to_jalali']),
      );

  JsonMap toMap() => {
        'id': id,
        'unit_name': name,
        'conversion_factor': factor,
        'version_number': version,
        'is_sellable': isSellable,
        'valid_to_jalali': validToJalali,
      };
}

class Product {
  const Product({
    required this.id,
    required this.code,
    required this.name,
    required this.baseUnitName,
    required this.stockBase,
    required this.minStock,
    this.groupName = 'سایر',
    this.isActive = true,
    this.demoSellPriceToman = 0,
    this.units = const [],
  });

  final String id;
  final String code;
  final String name;
  final String baseUnitName;
  final double stockBase;
  final double minStock;
  final String groupName;
  final bool isActive;
  final int demoSellPriceToman;
  final List<ProductUnit> units;

  bool get isLowStock => stockBase <= minStock;
  List<ProductUnit> get sellableUnits => units.where((unit) => unit.isSellable && unit.isActive).toList();

  factory Product.fromMap(JsonMap map) {
    final rawUnits = map['units'];
    final units = rawUnits is List
        ? rawUnits.whereType<Map>().map((item) => ProductUnit.fromMap(Map<String, dynamic>.from(item))).toList()
        : <ProductUnit>[];
    if (units.isEmpty) {
      units.add(ProductUnit(id: '', name: asString(map['base_unit_name'], fallback: 'عدد'), factor: 1, isSellable: true));
    }
    return Product(
      id: asString(map['id']),
      code: asString(map['code']),
      name: asString(map['name']),
      baseUnitName: asString(map['base_unit_name'], fallback: 'عدد'),
      stockBase: asDouble(map['stock_base'] ?? map['stockBase']),
      minStock: asDouble(map['min_stock'] ?? map['minStock']),
      groupName: asString(map['group_name'] ?? map['product_group_name'], fallback: 'سایر'),
      isActive: map['is_active'] != false,
      demoSellPriceToman: asInt(map['demo_sell_price_toman']),
      units: units,
    );
  }

  JsonMap toMap() => {
        'id': id,
        'code': code,
        'name': name,
        'base_unit_name': baseUnitName,
        'stock_base': stockBase,
        'min_stock': minStock,
        'group_name': groupName,
        'is_active': isActive,
        'units': units.map((unit) => unit.toMap()).toList(),
      };
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.syncId,
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.warehouse,
    this.warehouseId = '',
    required this.type,
    required this.quantityBase,
    required this.unitName,
    required this.quantity,
    required this.conversionFactor,
    required this.businessDateJalali,
    this.destinationWarehouse = '',
    this.reference = '',
    this.direction = 'increase',
    this.clientTimestamp = '',
  });

  final String id;
  final String syncId;
  final String productId;
  final String productCode;
  final String productName;
  final String warehouse;
  final String warehouseId;
  final String destinationWarehouse;
  final String type;
  final double quantityBase;
  final String unitName;
  final double quantity;
  final double conversionFactor;
  final String businessDateJalali;
  final String reference;
  final String direction;
  final String clientTimestamp;

  JsonMap toQueuePayload() => {
        'id': id,
        'syncId': syncId,
        'productId': productId,
        'productCode': productCode,
        'productName': productName,
        'warehouse': warehouse,
        'warehouseId': warehouseId,
        'destinationWarehouse': destinationWarehouse,
        'type': type,
        'quantityBase': quantityBase,
        'unit': unitName,
        'quantity': quantity,
        'factor': conversionFactor,
        'direction': direction,
        'date': businessDateJalali,
        'reference': reference,
        'clientTimestamp': clientTimestamp,
      };
}
