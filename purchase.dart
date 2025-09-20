class Purchase {
  final String id;
  final String expenseId; // ربط بالمصروف
  final String supplierName;
  final double totalAmount;
  final DateTime purchaseDate;
  final String invoiceImagePath;
  final List<PurchaseItem> items;
  final String notes;
  final String purchasedBy; // ID موظف المشتريات
  final String requestedBy; // ID الموظف اللي طلب المصروف الأصلي
  final String status; // 'pending_review', 'approved', 'rejected'
  final String? reviewedBy; // ID الأدمن اللي راجع
  final DateTime? reviewDate;
  final String? reviewNotes;

  Purchase({
    required this.id,
    required this.expenseId,
    required this.supplierName,
    required this.totalAmount,
    required this.purchaseDate,
    required this.invoiceImagePath,
    required this.items,
    required this.notes,
    required this.purchasedBy,
    required this.requestedBy,
    required this.status,
    this.reviewedBy,
    this.reviewDate,
    this.reviewNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expenseId': expenseId,
      'supplierName': supplierName,
      'totalAmount': totalAmount,
      'purchaseDate': purchaseDate.toIso8601String(),
      'invoiceImagePath': invoiceImagePath,
      'items': items.map((item) => item.toJson()).toList(),
      'notes': notes,
      'purchasedBy': purchasedBy,
      'requestedBy': requestedBy,
      'status': status,
      'reviewedBy': reviewedBy,
      'reviewDate': reviewDate?.toIso8601String(),
      'reviewNotes': reviewNotes,
    };
  }

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'] ?? '',
      expenseId: json['expenseId'] ?? '',
      supplierName: json['supplierName'] ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: DateTime.parse(json['purchaseDate']),
      invoiceImagePath: json['invoiceImagePath'] ?? '',
      items: (json['items'] as List?)?.map((item) => PurchaseItem.fromJson(item)).toList() ?? [],
      notes: json['notes'] ?? '',
      purchasedBy: json['purchasedBy'] ?? '',
      requestedBy: json['requestedBy'] ?? '',
      status: json['status'] ?? 'pending_review',
      reviewedBy: json['reviewedBy'],
      reviewDate: json['reviewDate'] != null ? DateTime.parse(json['reviewDate']) : null,
      reviewNotes: json['reviewNotes'],
    );
  }
}

class PurchaseItem {
  final String name;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double totalPrice;
  final bool addToWarehouse; // هل يضاف للمستودع؟
  final String? warehouseItemCode; // كود الصنف في المستودع (إذا أضيف)

  PurchaseItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
    required this.addToWarehouse,
    this.warehouseItemCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'addToWarehouse': addToWarehouse,
      'warehouseItemCode': warehouseItemCode,
    };
  }

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      name: json['name'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      addToWarehouse: json['addToWarehouse'] ?? false,
      warehouseItemCode: json['warehouseItemCode'],
    );
  }
}