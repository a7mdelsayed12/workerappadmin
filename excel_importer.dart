import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/asset.dart';
import '../../services/database_service.dart';

Future<void> importAssetsFromExcel(BuildContext context) async {
  // إظهار نافذة التحميل
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Text('جاري تحديد الملف...'),
        ],
      ),
    ),
  );

  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'],
    );

    if (result == null || result.files.single.path == null) {
      Navigator.pop(context); // إغلاق نافذة التحميل
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لم يتم اختيار ملف'))
      );
      return;
    }

    // تحديث نافذة التحميل
    Navigator.pop(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Flexible(child: Text('جارٍ تحديد الملف...')),
          ],
        ),
      ),
    );

    final filePath = result.files.single.path!;
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    List<Asset> assets = [];

    for (var tableName in excel.tables.keys) {
      final sheet = excel.tables[tableName];
      if (sheet == null) continue;

      // البحث عن صف الرؤوس
      int headerRow = -1;
      for (int row = 0; row < sheet.maxRows && headerRow == -1; row++) {
        for (int col = 0; col < sheet.maxColumns; col++) {
          final cellValue = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))?.value?.toString()?.toLowerCase() ?? '';
          if (cellValue.contains('أصل') || cellValue.contains('asset') ||
              cellValue.contains('رقم') || cellValue.contains('اسم')) {
            headerRow = row;
            break;
          }
        }
      }

      int startRow = headerRow == -1 ? 1 : headerRow + 1;

      for (int rowIndex = startRow; rowIndex < sheet.maxRows; rowIndex++) {
        try {
          final row = sheet.row(rowIndex);

          final assetNumber = row[0]?.value.toString().trim() ?? '';
          final nameEn = row[1]?.value.toString().trim() ?? '';
          final projectNumber = row[2]?.value.toString().trim() ?? '';
          final equipmentId = row[3]?.value.toString().trim() ?? '';
          final employeeName = row[4]?.value.toString().trim() ?? '';
          final employeeId = row[5]?.value.toString().trim() ?? '';
          final nameAr = row[6]?.value.toString().trim() ?? '';

// تعيين قيم افتراضية للحقول الفارغة بطريقة سليمة
          final finalAssetNumber = assetNumber.isNotEmpty ? assetNumber : 'A${DateTime.now().millisecondsSinceEpoch}-$rowIndex';
          final finalNameEn = nameEn.isNotEmpty ? nameEn : (nameAr.isNotEmpty ? nameAr : 'Imported Data $rowIndex');
          final finalProjectNumber = projectNumber;
          final finalEquipmentId = equipmentId.isNotEmpty ? equipmentId : finalAssetNumber;
          final finalEmployeeName = employeeName;
          final finalEmployeeId = employeeId;
          final finalNameAr = nameAr.isNotEmpty ? nameAr : (nameEn.isNotEmpty ? nameEn : 'بيانات مستوردة $rowIndex');

          assets.add(Asset(
            assetNumber: finalAssetNumber,
            nameEn: finalNameEn,
            projectNumber: finalProjectNumber,
            equipmentId: finalEquipmentId,
            employeeName: finalEmployeeName,
            employeeId: finalEmployeeId,
            nameAr: finalNameAr,
          ));

          // إضافة تأخير قصير كل 50 صف
          if (assets.length % 50 == 0) {
            await Future.delayed(Duration(milliseconds: 1));
          }

        } catch (e) {
          print('خطأ في قراءة الصف $rowIndex: $e');
          continue;
        }
      }
    }

    Navigator.pop(context); // إغلاق نافذة التحميل

    if (assets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('الملف لا يحتوي على بيانات صالحة'),
            backgroundColor: Colors.orange,
          )
      );
      return;
    }

    // نافذة تأكيد قبل الحفظ
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('تأكيد الاستيراد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تم العثور على ${assets.length} عنصر في الملف'),
            SizedBox(height: 12),
            Text('أمثلة على البيانات المستوردة:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ...assets.take(3).map((v) => Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text('• ${v.assetNumber} - ${v.nameAr}', style: TextStyle(fontSize: 12)),
            )),
            if (assets.length > 3)
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text('... و ${assets.length - 3} عنصر آخر', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
            SizedBox(height: 12),
            Text('هل تريد حفظ هذه البيانات؟'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حفظ'),
          ),
        ],
      ),
    );

    if (shouldSave != true) return;

    // إظهار نافذة الحفظ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('جاري حفظ البيانات...'),
          ],
        ),
      ),
    );

    // الحفظ في قاعدة البيانات
    final db = Provider.of<DatabaseService>(context, listen: false);
    await db.addAssets(assets);

    Navigator.pop(context); // إغلاق نافذة الحفظ

    // إشعار النجاح
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم استيراد وحفظ ${assets.length} عنصر بنجاح'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        )
    );

  } catch (e) {
    Navigator.pop(context); // إغلاق أي نافذة مفتوحة
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء الاستيراد: ${e.toString().length > 50 ? e.toString().substring(0, 50) + "..." : e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        )
    );
  }
}