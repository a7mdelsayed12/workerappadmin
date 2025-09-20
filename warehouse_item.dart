// models/warehouse_item.dart
class WarehouseItem {
  final String id; // معرف فريد لكل عنصر
  final String itemCode;
  final String itemName;
  final String projectCode;
  final String uom;
  final double quantity;
  final double unitCost;
  final double value;
  final String itemNameAr;

  WarehouseItem({
    String? id,
    required this.itemCode,
    required this.itemName,
    required this.projectCode,
    required this.uom,
    required this.quantity,
    required this.unitCost,
    required this.value,
    required this.itemNameAr,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemCode': itemCode,
      'itemName': itemName,
      'projectCode': projectCode,
      'uom': uom,
      'quantity': quantity,
      'unitCost': unitCost,
      'value': value,
      'itemNameAr': itemNameAr,
    };
  }

  // تحويل إلى Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemCode': itemCode,
      'itemName': itemName,
      'projectCode': projectCode,
      'uom': uom,
      'quantity': quantity,
      'unitCost': unitCost,
      'value': value,
      'itemNameAr': itemNameAr,
    };
  }

  // إنشاء من Map (JSON)
  factory WarehouseItem.fromJson(Map<String, dynamic> json) {
    return WarehouseItem(
      id: json['id'],
      itemCode: json['itemCode'] ?? '',
      itemName: json['itemName'] ?? '',
      projectCode: json['projectCode'] ?? '',
      uom: json['uom'] ?? '',
      quantity: (json['quantity'] is int)
          ? (json['quantity'] as int).toDouble()
          : (json['quantity'] as double? ?? 0.0),
      unitCost: (json['unitCost'] is int)
          ? (json['unitCost'] as int).toDouble()
          : (json['unitCost'] as double? ?? 0.0),
      value: (json['value'] is int)
          ? (json['value'] as int).toDouble()
          : (json['value'] as double? ?? 0.0),
      itemNameAr: json['itemNameAr'] ?? '',
    );
  }

  // إنشاء نسخة معدلة
  WarehouseItem copyWith({
    String? id,
    String? itemCode,
    String? itemName,
    String? projectCode,
    String? uom,
    double? quantity,
    double? unitCost,
    double? value,
    String? itemNameAr,
  }) {
    return WarehouseItem(
      id: id ?? this.id,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      projectCode: projectCode ?? this.projectCode,
      uom: uom ?? this.uom,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      value: value ?? this.value,
      itemNameAr: itemNameAr ?? this.itemNameAr,
    );
  }

  // المساواة حسب itemCode
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WarehouseItem && other.itemCode == itemCode;
  }

  @override
  int get hashCode => itemCode.hashCode;

  @override
  String toString() {
    return 'WarehouseItem(id: $id, itemCode: $itemCode, itemName: $itemName, quantity: $quantity, value: $value)';
  }
}
