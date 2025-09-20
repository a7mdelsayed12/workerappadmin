class PigeonAsset {
  String id = '';
  String assetNumber = '';
  String nameEn = '';
  String projectNumber = '';
  String equipmentId = '';
  String employeeName = '';
  String employeeId = '';
  String nameAr = '';
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
}

class PigeonUser {
  String id = '';
  String name = '';
  String email = '';
  String status = ''; // approved / pending / rejected
}
