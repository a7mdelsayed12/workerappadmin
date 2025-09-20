// lib/pigeon/pigeon.dart

// ==============================
// Pigeon Models
// ==============================

class PigeonAsset {
  String id = '';
  String assetNumber = '';
  String nameEn = '';
  String projectNumber = '';
  String equipmentId = '';
  String employeeName = '';
  String employeeId = '';
  String nameAr = '';

  PigeonAsset({
    this.id = '',
    this.assetNumber = '',
    this.nameEn = '',
    this.projectNumber = '',
    this.equipmentId = '',
    this.employeeName = '',
    this.employeeId = '',
    this.nameAr = '',
  });

  @override
  String toString() {
    return 'PigeonAsset(id: $id, assetNumber: $assetNumber, nameEn: $nameEn)';
  }
}

class PigeonWarehouseItem {
  String id = '';
  String itemCode = '';
  String itemName = '';
  String projectCode = '';
  String uom = '';
  double quantity = 0.0;
  double unitCost = 0.0;
  double value = 0.0;
  String itemNameAr = '';

  PigeonWarehouseItem({
    this.id = '',
    this.itemCode = '',
    this.itemName = '',
    this.projectCode = '',
    this.uom = '',
    this.quantity = 0.0,
    this.unitCost = 0.0,
    this.value = 0.0,
    this.itemNameAr = '',
  });

  @override
  String toString() {
    return 'PigeonWarehouseItem(id: $id, itemCode: $itemCode, itemName: $itemName)';
  }
}

class PigeonUser {
  String id = '';
  String name = '';
  String email = '';
  String status = ''; // approved / pending / rejected

  PigeonUser({
    this.id = '',
    this.name = '',
    this.email = '',
    this.status = '',
  });

  @override
  String toString() {
    return 'PigeonUser(id: $id, name: $name, email: $email, status: $status)';
  }
}
