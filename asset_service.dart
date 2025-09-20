// lib/services/asset_service.dart
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import '../../../models/asset.dart';

class AssetService extends ChangeNotifier {
  final List<Asset> _asset = [];
  List<Asset> get asset => List.unmodifiable(_asset);

  Future<void> importFromExcel(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null) return;

    _asset.clear();
    for (var r = 1; r < sheet.maxRows; r++) {
      final row = sheet.row(r);
      final assetNumber = row[0]?.value?.toString() ?? '';
      if (assetNumber.isEmpty) continue;

      _asset.add(Asset(
        assetNumber: assetNumber,
        nameEn: row[1]?.value?.toString() ?? '',
        projectNumber: row[2]?.value?.toString() ?? '',
        equipmentId: row[3]?.value?.toString() ?? '',
        employeeName: row[4]?.value?.toString() ?? '',
        employeeId: row[5]?.value?.toString() ?? '',
        nameAr: row[6]?.value?.toString() ?? '',

      ));
    }
    notifyListeners();
  }
}
