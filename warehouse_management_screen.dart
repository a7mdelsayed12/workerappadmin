import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../models/warehouse_item.dart';
import '../../../models/dispatch_request.dart';
import '../../../services/database_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../utils/constants.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';



class WarehouseViewOnlyScreen extends StatefulWidget {
  @override
  _WarehouseViewOnlyScreenState createState() => _WarehouseViewOnlyScreenState();
}

class _WarehouseViewOnlyScreenState extends State<WarehouseViewOnlyScreen> {
  String _searchQuery = '';
  final List<String> _selectedItemCodes = []; // قائمة العناصر المحددة
  bool _selectAll = false;
  bool _showSelectedOnly = false;

  //......... تاني اضافه
  final Map<String, Map<String, TextEditingController>> _editControllers = {};
  final Map<String, bool> _editingItems = {};
  int _selectedIndex = 0;
  final List<String> tabs = ['المستودع', 'مراجعة الاضافات', 'طلبات الصرف'];

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final allItems = db.warehouseItems;

    // الفلترة للبحث والعرض المحدد
    final filteredItems = allItems.where((item) {
      // إذا كان وضع "عرض المحدد" مفعل، فلنعرض فقط العناصر المحددة
      if (_showSelectedOnly && !_selectedItemCodes.contains(item.itemCode)) {
        return false;
      }

      // ثم الفلترة حسب البحث
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return item.itemName.toLowerCase().contains(query) ||
          item.itemNameAr.toLowerCase().contains(query) ||
          item.itemCode.toLowerCase().contains(query) ||
          item.projectCode.toLowerCase().contains(query);
    }).toList();

    // العناصر المحددة الفعلية
    final selectedItems = allItems.where((item) => _selectedItemCodes.contains(item.itemCode)).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],

      appBar: AppBar(
        centerTitle: true,
        title: Text('عرض المستودع'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,

        // الأزرار على اليسار
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            // الـ 3 نقاط

            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.white, size: 20),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    if (_selectedItemCodes.isNotEmpty) _enableEditingForSelected();
                    break;
                  case 'add':
                    _showAddItemDialog(context);
                    break;
                  case 'delete':
                    if (_selectedItemCodes.isNotEmpty) _deleteSelectedItems(context, db);
                    break;
                  case 'save':
                    _saveChanges(context, db);
                    break;
                  case 'import':
                    _importFromExcel(context, db);
                    break;
                  case 'export':
                    _exportToExcel(selectedItems.isNotEmpty ? selectedItems : filteredItems);
                    break;
                  case 'share':
                    _shareItems(selectedItems.isNotEmpty ? selectedItems : filteredItems);
                    break;
                  case 'print':
                    _printItems(selectedItems.isNotEmpty ? selectedItems : filteredItems);
                    break;
                  case 'select_all':
                    _toggleSelectAll(filteredItems);
                    break;
                  case 'clear_selection':
                    _clearSelection();
                    setState(() {
                      _showSelectedOnly = false;
                    });
                    break;
                }
              },


              itemBuilder: (context) => [

                PopupMenuItem(
                  value: 'edit',
                  enabled: _selectedItemCodes.isNotEmpty,
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18, color: _selectedItemCodes.isNotEmpty ? Colors.teal : Colors.grey),
                      SizedBox(width: 8),
                      Text('تعديل المحدد', style: TextStyle(fontSize: 13, color: _selectedItemCodes.isNotEmpty ? Colors.teal : Colors.grey)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'add',
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 18, color: Colors.green),
                      SizedBox(width: 6),
                      Text('إضافة عنصر جديد', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  enabled: _selectedItemCodes.isNotEmpty,
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: _selectedItemCodes.isNotEmpty ? Colors.red : Colors.grey),
                      SizedBox(width: 8),
                      Text('مسح المحدد', style: TextStyle(fontSize: 13, color: _selectedItemCodes.isNotEmpty ? Colors.red : Colors.grey)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'save',
                  child: Row(
                    children: [
                      Icon(Icons.save, size: 18, color: Colors.blue),
                      SizedBox(width: 6),
                      Text('حفظ التعديلات', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(Icons.upload_file, size: 18, color: Colors.purple),
                      SizedBox(width: 6),
                      Text('استيراد من Excel', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download, size: 18, color: Colors.green),
                      SizedBox(width: 6),
                      Text('تصدير إلى Excel', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 18, color: Colors.orange),
                      SizedBox(width: 6),
                      Text('مشاركة', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'print',
                  child: Row(
                    children: [
                      Icon(Icons.print, size: 18, color: Colors.blue),
                      SizedBox(width: 6),
                      Text('طباعة', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),

                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'select_all',
                  child: Row(
                    children: [
                      Icon(Icons.select_all, size: 18, color: Colors.purple),
                      SizedBox(width: 8),
                      Text('تحديد الكل', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_selection',
                  enabled: _selectedItemCodes.isNotEmpty,
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, size: 18, color: _selectedItemCodes.isNotEmpty ? Colors.red : Colors.grey),
                      SizedBox(width: 10),
                      Text('إلغاء التحديد', style: TextStyle(fontSize: 13, color: _selectedItemCodes.isNotEmpty ? Colors.red : Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),


            // زر عرض المحدد (يظهر فقط عند وجود تحديد)
            if (_selectedItemCodes.isNotEmpty)
              _buildAppBarButton(
                _showSelectedOnly ? 'عرض\nالكل' : 'عرض\nالمحدد',
                Icons.filter_list,
                _showSelectedOnly ? Colors.orange : Colors.teal,
                    () => _toggleShowSelectedOnly(),
              ),

// زر تحديد البحث (يظهر فقط عند البحث)
            if (_searchQuery.isNotEmpty)
              _buildAppBarButton(
                'تحديد\nالبحث',
                Icons.search,
                Colors.purple,
                    () => _selectSearchResults(filteredItems),
              ),
          ],
        ),
        leadingWidth: _calculateLeadingWidth(),

        // زر الرجوع على اليمين
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_forward, size: 20),
            onPressed: () => Navigator.pop(context),
            tooltip: 'رجوع',
          ),
        ],
      ),

      body: Column(
        children: [
          // بطاقة الإحصائيات والبحث
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // الإحصائيات فقط
                Row(
                  children: [
                    _buildStatCard('العناصر', '${allItems.length}', Colors.blue),
                    SizedBox(width: 6),
                    _buildStatCard('المعروض', '${filteredItems.length}', Colors.green),
                    SizedBox(width: 6),
                    _buildStatCard('المحدد', '${_selectedItemCodes.length}', Colors.orange),
                    SizedBox(width: 6),
                    _buildStatCard('منخفض', '${db.lowStockItems.length}', Colors.red),
                  ],
                ),

                Spacer(),

                // البحث
                Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 18),
                            hintText: 'ابحث في المستودع...',
                            hintStyle: TextStyle(fontSize: 12),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            isDense: true,
                          ),
                          onChanged: (value) => setState(() => _searchQuery = value),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.clear, size: 16, color: Colors.grey[600]),
                          onPressed: () => setState(() => _searchQuery = ''),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
/////// خامس نقطه          // المحتوى
          Container(
            color: Colors.white,
            child: Row(
              children: tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final title = entry.value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _selectedIndex == index ? Colors.white : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedIndex == index ? Colors.green[600]! : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedIndex == index ? Colors.green[600] : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

// المحتوى
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                // تبويب المستودع
                filteredItems.isEmpty
                    ? _buildEmptyState()
                    : _buildDataTable(filteredItems),
                // تبويب طلبات الصرف
                _buildDispatchRequests(db.dispatchRequests),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatIcon(title), size: 12, color: color),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: color.withOpacity(0.8),
              height: 1.1,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isEmpty ? Icons.inventory_outlined : Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'لا توجد عناصر في المستودع' : 'لم يتم العثور على نتائج',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_searchQuery.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'قم بإضافة عناصر للمستودع أولاً',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }

// أضف ده في بداية الكلاس
  final ScrollController _horizontalScrollController = ScrollController();

  Widget _buildDataTable(List<WarehouseItem> items) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                // هنا نحرك الهيدر مع السكرول الأفقي
                return true;
              },
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    // Header ثابت
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 56,
                            child: Center(
                              child: Tooltip(
                                message: _selectAll ? 'إلغاء التحديد' : 'تحديد الكل',
                                child: InkWell(
                                  onTap: () => _toggleSelectAll(items),
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: _getCheckboxHeaderColor(),
                                    ),
                                    child: Icon(
                                      _selectAll ? Icons.check_box : Icons.check_box_outline_blank,
                                      size: 20,
                                      color: _getCheckboxIconColor(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _buildHeaderCell('كود العنصر', 100),
                          _buildHeaderCell('الاسم بالإنجليزي', 150),
                          _buildHeaderCell('كود المشروع', 120),
                          _buildHeaderCell('الوحدة', 80),
                          _buildHeaderCell('الكمية', 80),
                          _buildHeaderCell('سعر الوحدة', 100),
                          _buildHeaderCell('القيمة الإجمالية', 120),
                          _buildHeaderCell('الاسم بالعربي', 150),
                        ],
                      ),
                    ),

                    // البيانات
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: items.map((item) {
                            final isSelected = _selectedItemCodes.contains(item.itemCode);
                            final isLowStock = item.quantity <= 5;

                            return Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: isLowStock ? Colors.red[50] :
                                isSelected ? Colors.blue[50] : Colors.white,
                                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    child: Center(
                                      child: Checkbox(
                                        value: isSelected,
                                        onChanged: (selected) {
                                          setState(() {
                                            if (selected == true) {
                                              _selectedItemCodes.add(item.itemCode);
                                            } else {
                                              _selectedItemCodes.remove(item.itemCode);
                                            }
                                            _updateSelectAllState(items);
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  _buildDataCell(item, 'itemCode', 121),
                                  _buildDataCell(item, 'itemName', 250),
                                  _buildDataCell(item, 'projectCode', 90),
                                  _buildDataCell(item, 'uom', 40),
                                  _buildDataCell(item, 'quantity', 40, isNumeric: true),
                                  _buildDataCell(item, 'unitCost', 90 , isNumeric: true),
                                  _buildDataCell(item, 'value', 100, isNumeric: true),
                                  _buildDataCell(item, 'itemNameAr', 200),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }
  Widget _buildHeaderCell(String text, double width) {
    return Container(
      width: width,
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
          maxLines: 2, // إضافة هذا السطر
          overflow: TextOverflow.ellipsis, // إضافة هذا السطر
        ),
      ),
    );
  }

  Widget _buildDataCell(WarehouseItem item, String field, double width, {bool isNumeric = false}) {
    final isEditing = _editingItems[item.itemCode] ?? false;

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: isEditing ?
      TextFormField(
        controller: _editControllers[item.itemCode]?[field],
        decoration: InputDecoration(isDense: true),
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      ) :
      Text(
        _getFieldValue(item, field),
        style: TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  // أضف هذه الدالة الجديدة لتحديد نتائج البحث فقط
  void _selectSearchResults(List<WarehouseItem> items) {
    setState(() {
      // إضافة جميع العناصر المعروضة في نتائج البحث للتحديد
      for (var item in items) {
        if (!_selectedItemCodes.contains(item.itemCode)) {
          _selectedItemCodes.add(item.itemCode);
        }
      }
      _updateSelectAllState(items);
    });
  }

  void _toggleSelectAll(List<WarehouseItem> items) {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        // إضافة جميع العناصر المعروضة للتحديد
        for (var item in items) {
          if (!_selectedItemCodes.contains(item.itemCode)) {
            _selectedItemCodes.add(item.itemCode);
          }
        }
      } else {
        // إزالة جميع العناصر المعروضة من التحديد
        for (var item in items) {
          _selectedItemCodes.remove(item.itemCode);
        }
      }
    });
  }

  void _updateSelectAllState(List<WarehouseItem> items) {
    final allDisplayedSelected = items.every((item) => _selectedItemCodes.contains(item.itemCode));
    setState(() {
      _selectAll = allDisplayedSelected && items.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedItemCodes.clear();
      _selectAll = false;
    });
  }

  Future<void> _exportToExcel(List<WarehouseItem> items) async {
    try {
      // طلب صلاحية الكتابة على التخزين
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('يرجى السماح بصلاحية الوصول للتخزين'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('جاري إنشاء ملف Excel...'),
            ],
          ),
        ),
      );

      final excelFile = excel.Excel.createExcel();
      final sheet = excelFile['قائمة المستودع'];

      // إضافة الرؤوس
      sheet.cell(excel.CellIndex.indexByString('A1')).value = excel.TextCellValue('كود العنصر');
      sheet.cell(excel.CellIndex.indexByString('B1')).value = excel.TextCellValue('الاسم بالإنجليزي');
      sheet.cell(excel.CellIndex.indexByString('C1')).value = excel.TextCellValue('كود المشروع');
      sheet.cell(excel.CellIndex.indexByString('D1')).value = excel.TextCellValue('الوحدة');
      sheet.cell(excel.CellIndex.indexByString('E1')).value = excel.TextCellValue('الكمية');
      sheet.cell(excel.CellIndex.indexByString('F1')).value = excel.TextCellValue('سعر الوحدة');
      sheet.cell(excel.CellIndex.indexByString('G1')).value = excel.TextCellValue('القيمة الإجمالية');
      sheet.cell(excel.CellIndex.indexByString('H1')).value = excel.TextCellValue('الاسم بالعربي');

      // إضافة البيانات
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final rowIndex = i + 2;

        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = excel.TextCellValue(item.itemCode);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = excel.TextCellValue(item.itemName);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = excel.TextCellValue(item.projectCode);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = excel.TextCellValue(item.uom);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = excel.DoubleCellValue(item.quantity);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = excel.DoubleCellValue(item.unitCost);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = excel.DoubleCellValue(item.value);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = excel.TextCellValue(item.itemNameAr);
      }

      // حفظ الملف في مجلد Downloads
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'قائمة_المستودع_$timestamp.xlsx';

      // مسار Downloads للأندرويد
      final downloadsPath = '/storage/emulated/0/Download';
      final filePath = '$downloadsPath/$fileName';
      String finalSavedPath = filePath;

      try {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(excelFile.encode()!);
      } catch (e) {
        // إذا فشل في Downloads، جرب مجلد التطبيق
        final directory = await getApplicationDocumentsDirectory();
        final fallbackPath = '${directory.path}/$fileName';
        finalSavedPath = fallbackPath;
        File(fallbackPath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(excelFile.encode()!);
      }

      Navigator.pop(context);

      // رسالة نجاح مع مسار الملف
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('تم التصدير بنجاح'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تم تصدير ${items.length} عنصر إلى ملف Excel'),
              SizedBox(height: 8),
              Text('مسار الملف:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  finalSavedPath,
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('تم'),
            ),
          ],
        ),
      );

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء التصدير: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _printItems(List<WarehouseItem> items) {
    // إنشاء محتوى قابل للطباعة
    String printContent = "قائمة المستودع\n\n";
    for (var item in items) {
      printContent += "كود العنصر: ${item.itemCode}\n";
      printContent += "الاسم بالإنجليزية: ${item.itemName}\n";
      printContent += "الاسم بالعربية: ${item.itemNameAr}\n";
      printContent += "كود المشروع: ${item.projectCode}\n";
      printContent += "الوحدة: ${item.uom}\n";
      printContent += "الكمية: ${item.quantity}\n";
      printContent += "سعر الوحدة: ${item.unitCost} ر.س\n";
      printContent += "القيمة الإجمالية: ${item.value} ر.س\n";
      printContent += "────────────────────────\n";
    }

    // عرض محتوى الطباعة في صفحة منفصلة
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('طباعة ${items.length} عنصر'),
            actions: [
              IconButton(
                icon: Icon(Icons.print),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('جاري إرسال المحتوى للطباعة...'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Text(
              printContent,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ),
    );
  }

  void _shareItems(List<WarehouseItem> items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا توجد عناصر للمشاركة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // عرض dialog للاختيار بين Excel أو PDF أو النص
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.share, color: Colors.blue),
            SizedBox(width: 8),
            Text('مشاركة ${items.length} عنصر'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('اختر صيغة الملف:', style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),

            // خيار Excel
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.table_chart, color: Colors.green[700]),
              ),
              title: Text('Excel'),
              subtitle: Text('ملف جداول بيانات'),
              onTap: () {
                Navigator.pop(context);
                _shareExcelFile(items);
              },
            ),

            Divider(),

            // خيار PDF
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.picture_as_pdf, color: Colors.red[700]),
              ),
              title: Text('PDF'),
              subtitle: Text('ملف محمول للطباعة'),
              onTap: () {
                Navigator.pop(context);
                _sharePdfFile(items);
              },
            ),

            Divider(),

            // خيار النص
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.text_snippet, color: Colors.blue[700]),
              ),
              title: Text('نص'),
              subtitle: Text('نص مقروء لجميع التطبيقات'),
              onTap: () {
                Navigator.pop(context);
                _shareTextContent(items);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _shareTextContent(List<WarehouseItem> items) async {
    try {
      // بناء محتوى النص
      String textContent = "";
      textContent += "📋 قائمة المستودع\n";
      textContent += "═══════════════\n\n";
      textContent += "📅 التاريخ: ${DateTime.now().toString().substring(0, 10)}\n";
      textContent += "📊 إجمالي العناصر: ${items.length}\n\n";

      for (int i = 0; i < items.length; i++) {
        var item = items[i];
        textContent += "🔸 العنصر ${i + 1}:\n";
        textContent += "  كود العنصر: ${item.itemCode}\n";

        if (item.itemName.isNotEmpty) {
          textContent += "  الاسم (EN): ${item.itemName}\n";
        }
        if (item.itemNameAr.isNotEmpty) {
          textContent += "  الاسم (AR): ${item.itemNameAr}\n";
        }

        textContent += "  كود المشروع: ${item.projectCode}\n";
        textContent += "  الوحدة: ${item.uom}\n";
        textContent += "  الكمية: ${item.quantity}\n";
        textContent += "  سعر الوحدة: ${item.unitCost} ر.س\n";
        textContent += "  القيمة الإجمالية: ${item.value} ر.س\n";
        textContent += "─────────────────\n";
      }

      textContent += "\n📱 تم إنشاؤه بواسطة نظام إدارة المستودع";

      // مشاركة النص
      Share.share(
        textContent,
        subject: 'قائمة المستودع - ${items.length} عنصر',
      );

      // رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('تم مشاركة ${items.length} عنصر كنص'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء إنشاء النص: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  Color _getCheckboxHeaderColor() {
    if (_selectAll) {
      return Colors.green[100]!;
    } else if (_selectedItemCodes.isNotEmpty) {
      return Colors.orange[100]!;
    } else {
      return Colors.transparent;
    }
  }

  Color _getCheckboxIconColor() {
    if (_selectAll) {
      return Colors.green[700]!;
    } else if (_selectedItemCodes.isNotEmpty) {
      return Colors.orange[700]!;
    } else {
      return Colors.grey[600]!;
    }
  }

  Widget _buildAppBarButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      margin: EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              SizedBox(height: 3),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateLeadingWidth() {
    double width = 56; // عرض الـ 3 نقاط الأساسي
    if (_searchQuery.isNotEmpty) width += 60; // زر تحديد البحث أوسع
    if (_selectedItemCodes.isNotEmpty) width += 60; // زر عرض المحدد أوسع
    return width;
  }

  void _toggleShowSelectedOnly() {
    setState(() {
      _showSelectedOnly = !_showSelectedOnly;
    });
  }

  IconData _getStatIcon(String title) {
    if (title.contains('العناصر')) {
      return Icons.inventory;
    } else if (title.contains('المعروض')) {
      return Icons.visibility;
    } else if (title.contains('المحدد')) {
      return Icons.check_box;
    } else if (title.contains('منخفض')) {
      return Icons.warning;
    } else {
      return Icons.assessment;
    }
  }
  Widget _buildDispatchRequests(List<DispatchRequest> requests) {
    final pending = requests.where((r) => r.status == AppConstants.statusPending).toList();
    return pending.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.request_page_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('لا توجد طلبات صرف', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ],
      ),
    )
        : ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: pending.length,
      itemBuilder: (_, i) {
        final r = pending[i];
        return Card(
          child: ListTile(
            title: Text('طلب صرف #${r.id}'),
            subtitle: Text('الكمية المطلوبة: ${r.requestedQuantity}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () async {
                    await Provider.of<DatabaseService>(context, listen: false).approveDispatchRequest(r.id, r.requestedQuantity);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () async {
                    await Provider.of<DatabaseService>(context, listen: false).rejectDispatchRequest(r.id, 'مرفوض');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  void _shareExcelFile(List<WarehouseItem> items) async {
    try {
      final excelFile = excel.Excel.createExcel();
      final sheet = excelFile['قائمة المستودع'];

      // إضافة الرؤوس
      sheet.cell(excel.CellIndex.indexByString('A1')).value = excel.TextCellValue('كود العنصر');
      sheet.cell(excel.CellIndex.indexByString('B1')).value = excel.TextCellValue('الاسم بالإنجليزي');
      sheet.cell(excel.CellIndex.indexByString('C1')).value = excel.TextCellValue('كود المشروع');
      sheet.cell(excel.CellIndex.indexByString('D1')).value = excel.TextCellValue('الوحدة');
      sheet.cell(excel.CellIndex.indexByString('E1')).value = excel.TextCellValue('الكمية');
      sheet.cell(excel.CellIndex.indexByString('F1')).value = excel.TextCellValue('سعر الوحدة');
      sheet.cell(excel.CellIndex.indexByString('G1')).value = excel.TextCellValue('القيمة الإجمالية');
      sheet.cell(excel.CellIndex.indexByString('H1')).value = excel.TextCellValue('الاسم بالعربي');

      // إضافة البيانات
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final rowIndex = i + 2;

        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = excel.TextCellValue(item.itemCode);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = excel.TextCellValue(item.itemName);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = excel.TextCellValue(item.projectCode);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = excel.TextCellValue(item.uom);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = excel.DoubleCellValue(item.quantity);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = excel.DoubleCellValue(item.unitCost);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = excel.DoubleCellValue(item.value);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = excel.TextCellValue(item.itemNameAr);
      }

      // حفظ الملف مؤقتاً للمشاركة
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'قائمة_المستودع_$timestamp.xlsx';
      final filePath = '${directory.path}/$fileName';

      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excelFile.encode()!);

      // مشاركة الملف
      Share.shareFiles([filePath], subject: 'قائمة المستودع', text: 'مرفق قائمة المستودع المحددة');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء إنشاء الملف: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sharePdfFile(List<WarehouseItem> items) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('جاري إنشاء ملف PDF...'),
            ],
          ),
        ),
      );

      final pdf = pw.Document();

      // تحميل خط عربي من Google Fonts
      pw.Font? arabicFont;
      try {
        arabicFont = await PdfGoogleFonts.notoSansArabicRegular();
      } catch (e) {
        print('فشل في تحميل الخط العربي: $e');
      }

      // عدد الصفوف في كل صفحة
      const int itemsPerPage = 15;
      final int totalPages = (items.length / itemsPerPage).ceil();

      // إنشاء الصفحات
      for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
        final int startIndex = pageIndex * itemsPerPage;
        final int endIndex = (startIndex + itemsPerPage).clamp(0, items.length);
        final List<WarehouseItem> pageItems = items.sublist(startIndex, endIndex);

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: pw.EdgeInsets.all(20),
            header: (pw.Context context) {
              return _buildPdfHeaderMixed(pageIndex + 1, totalPages, items.length, arabicFont);
            },
            footer: (pw.Context context) {
              return _buildPdfFooterMixed(pageIndex + 1, totalPages, arabicFont);
            },
            build: (pw.Context context) {
              return [
                // الجدول
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  columnWidths: {
                    0: pw.FixedColumnWidth(60),   // كود العنصر
                    1: pw.FlexColumnWidth(2.5),   // الاسم بالإنجليزي
                    2: pw.FixedColumnWidth(70),   // كود المشروع
                    3: pw.FixedColumnWidth(50),   // الوحدة
                    4: pw.FixedColumnWidth(60),   // الكمية
                    5: pw.FixedColumnWidth(70),   // سعر الوحدة
                    6: pw.FixedColumnWidth(80),   // القيمة
                    7: pw.FlexColumnWidth(2.5),   // الاسم بالعربي
                  },
                  children: [
                    // صف الرؤوس
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        _buildMixedTextCell('كود العنصر', isHeader: true, isArabic: true, arabicFont: arabicFont),
                        _buildMixedTextCell('الاسم بالإنجليزي', isHeader: true, isArabic: true, arabicFont: arabicFont),
                        _buildMixedTextCell('كود المشروع', isHeader: true, isArabic: true, arabicFont: arabicFont),
                        _buildMixedTextCell('الوحدة', isHeader: true, isArabic: true, arabicFont: arabicFont),
                        _buildMixedTextCell('الكمية', isHeader: true, isArabic: true, arabicFont: arabicFont),
                        _buildMixedTextCell('سعر الوحدة', isHeader: true, isArabic: true, arabicFont: arabicFont),
                        _buildMixedTextCell('القيمة', isHeader: true, isArabic: true, arabicFont: arabicFont),
                        _buildMixedTextCell('الاسم بالعربي', isHeader: true, isArabic: true, arabicFont: arabicFont),
                      ],
                    ),
                    // صفوف البيانات
                    ...pageItems.map((item) => pw.TableRow(
                      children: [
                        _buildMixedTextCell(item.itemCode, isArabic: false, arabicFont: arabicFont),
                        _buildMixedTextCell(item.itemName.isNotEmpty ? item.itemName : '-', isArabic: false, arabicFont: arabicFont),
                        _buildMixedTextCell(item.projectCode, isArabic: false, arabicFont: arabicFont),
                        _buildMixedTextCell(item.uom, isArabic: false, arabicFont: arabicFont),
                        _buildMixedTextCell(item.quantity.toString(), isArabic: false, arabicFont: arabicFont),
                        _buildMixedTextCell(item.unitCost.toString(), isArabic: false, arabicFont: arabicFont),
                        _buildMixedTextCell(item.value.toString(), isArabic: false, arabicFont: arabicFont),
                        _buildMixedTextCell(item.itemNameAr.isNotEmpty ? item.itemNameAr : item.itemName,
                            isArabic: item.itemNameAr.isNotEmpty, arabicFont: arabicFont),
                      ],
                    )).toList(),
                  ],
                ),
              ];
            },
          ),
        );
      }

      // حفظ ومشاركة الملف
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'قائمة_المستودع_$timestamp.pdf';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      Navigator.pop(context);

      Share.shareFiles(
          [filePath],
          subject: 'قائمة المستودع PDF - ${items.length} عنصر',
          text: 'مرفق قائمة المستودع الكاملة بصيغة PDF ($totalPages صفحة)'
      );

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء إنشاء ملف PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  pw.Widget _buildPdfHeaderMixed(int currentPage, int totalPages, int totalItems, pw.Font? arabicFont) {
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'قائمة المستودع',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  font: arabicFont,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'Page $currentPage of $totalPages',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'التاريخ: ${DateTime.now().toString().substring(0, 10)}',
                style: pw.TextStyle(fontSize: 10, font: arabicFont),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'إجمالي العناصر: $totalItems',
                style: pw.TextStyle(fontSize: 10, font: arabicFont),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.Divider(),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooterMixed(int currentPage, int totalPages, pw.Font? arabicFont) {
    return pw.Container(
      margin: pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        children: [
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'تم الإنشاء بواسطة نظام إدارة المستودع',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, font: arabicFont),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'Page $currentPage of $totalPages',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMixedTextCell(String text, {bool isHeader = false, bool isArabic = false, pw.Font? arabicFont}) {
    String cleanText = text.replaceAll(RegExp(
        r'[^\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF\u0020-\u007F]'),
        '');
    return pw.Padding(
      padding: pw.EdgeInsets.all(6),
      child: pw.Text(
        cleanText.isEmpty ? text : cleanText,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          font: isArabic && arabicFont != null ? arabicFont : null,
        ),
        textAlign: pw.TextAlign.center,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        maxLines: isHeader ? 2 : 3,
      ),
    );
  }
  void _deleteSelectedItems(BuildContext context, DatabaseService db) {
    final selectedCount = _selectedItemCodes.length;
    if (selectedCount == 0) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد المسح'),
        content: Text('هل تريد مسح $selectedCount عنصر؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              for (String itemCode in _selectedItemCodes) {
                db.deleteWarehouseItem(itemCode);
              }
              setState(() {
                _selectedItemCodes.clear();
                _selectAll = false;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم مسح $selectedCount عنصر')),
              );
            },
            child: Text('مسح'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final itemCodeCtrl = TextEditingController();
    final itemNameCtrl = TextEditingController();
    final projectCodeCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();
    final unitCostCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final itemNameArCtrl = TextEditingController();

    String selectedUom = AppConstants.unitOfMeasures.first;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('إضافة قطعة جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: itemCodeCtrl,
                  decoration: InputDecoration(
                    labelText: 'كود القطعة *',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: itemNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'اسم القطعة *',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: projectCodeCtrl,
                  decoration: InputDecoration(
                    labelText: 'كود المشروع',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedUom,
                  decoration: InputDecoration(
                    labelText: 'الوحدة',
                    border: OutlineInputBorder(),
                  ),
                  items: AppConstants.unitOfMeasures.map((uom) => DropdownMenuItem(
                    value: uom,
                    child: Text(uom),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedUom = value;
                      });
                    }
                  },
                ),
                SizedBox(height: 8),
                TextField(
                  controller: quantityCtrl,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'الكمية *',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final quantity = double.tryParse(value) ?? 0.0;
                    final unitCost = double.tryParse(unitCostCtrl.text) ?? 0.0;
                    valueCtrl.text = (quantity * unitCost).toString();
                  },
                ),
                SizedBox(height: 8),
                TextField(
                  controller: unitCostCtrl,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'سعر الوحدة',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final quantity = double.tryParse(quantityCtrl.text) ?? 0.0;
                    final unitCost = double.tryParse(value) ?? 0.0;
                    valueCtrl.text = (quantity * unitCost).toString();
                  },
                ),
                SizedBox(height: 8),
                TextField(
                  controller: valueCtrl,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'القيمة الإجمالية',
                    border: OutlineInputBorder(),
                  ),
                  enabled: false,
                ),
                SizedBox(height: 8),
                TextField(
                  controller: itemNameArCtrl,
                  decoration: InputDecoration(
                    labelText: 'الاسم العربي',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (itemCodeCtrl.text.isNotEmpty &&
                    itemNameCtrl.text.isNotEmpty &&
                    quantityCtrl.text.isNotEmpty) {
                  final item = WarehouseItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    itemCode: itemCodeCtrl.text,
                    itemName: itemNameCtrl.text,
                    projectCode: projectCodeCtrl.text,
                    uom: selectedUom,
                    quantity: double.tryParse(quantityCtrl.text) ?? 0.0,
                    unitCost: double.tryParse(unitCostCtrl.text) ?? 0.0,
                    value: double.tryParse(valueCtrl.text) ?? 0.0,
                    itemNameAr: itemNameArCtrl.text,
                  );

                  Provider.of<DatabaseService>(context, listen: false).addWarehouseItem(item);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم إضافة العنصر بنجاح')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('يرجى ملء الحقول المطلوبة')),
                  );
                }
              },
              child: Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }






  Future<void> _importFromExcel(BuildContext context, DatabaseService db) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        var bytes = file.readAsBytesSync();
        var excelFile = excel.Excel.decodeBytes(bytes);

        int importedCount = 0;

        for (var table in excelFile.tables.keys) {
          var sheet = excelFile.tables[table]!;

          for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
            try {
              var itemCodeCell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
              var itemNameCell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
              var projectCodeCell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex));
              var uomCell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex));
              var quantityCell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex));
              var unitCostCell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex));
              var valueCell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex));
              var itemNameArCell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex));

              String itemCode = itemCodeCell?.value?.toString()?.trim() ?? '';
              String itemName = itemNameCell?.value?.toString()?.trim() ?? '';
              String projectCode = projectCodeCell?.value?.toString()?.trim() ?? '';
              String uom = uomCell?.value?.toString()?.trim() ?? '';
              String itemNameAr = itemNameArCell?.value?.toString()?.trim() ?? '';

              if (itemCode.isEmpty && itemName.isEmpty) continue;

              final item = WarehouseItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                itemCode: itemCode.isNotEmpty ? itemCode : 'ITEM_${DateTime.now().millisecondsSinceEpoch}',
                itemName: itemName,
                projectCode: projectCode,
                uom: uom.isNotEmpty ? uom : 'قطعة',
                quantity: double.tryParse(quantityCell?.value?.toString() ?? '0') ?? 0.0,
                unitCost: double.tryParse(unitCostCell?.value?.toString() ?? '0') ?? 0.0,
                value: double.tryParse(valueCell?.value?.toString() ?? '0') ?? 0.0,
                itemNameAr: itemNameAr,
              );

              await db.addWarehouseItem(item);
              importedCount++;

            } catch (e) {
              continue;
            }
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم استيراد $importedCount عنصر بنجاح')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الاستيراد: $e')),
      );
    }
  }
  void _enableEditingForSelected() {
    setState(() {
      for (String itemCode in _selectedItemCodes) {
        _editingItems[itemCode] = true;
        if (!_editControllers.containsKey(itemCode)) {
          final item = Provider.of<DatabaseService>(context, listen: false)
              .warehouseItems
              .firstWhere((item) => item.itemCode == itemCode);

          _editControllers[itemCode] = {
            'itemCode': TextEditingController(text: item.itemCode),
            'itemName': TextEditingController(text: item.itemName),
            'projectCode': TextEditingController(text: item.projectCode),
            'uom': TextEditingController(text: item.uom),
            'quantity': TextEditingController(text: item.quantity.toString()),
            'unitCost': TextEditingController(text: item.unitCost.toString()),
            'value': TextEditingController(text: item.value.toString()),
            'itemNameAr': TextEditingController(text: item.itemNameAr),
          };
        }
      }
    });
  }

  void _saveChanges(BuildContext context, DatabaseService db) {
    final editingItems = _editingItems.entries.where((e) => e.value).toList();
    if (editingItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى تحديد عناصر للحفظ')),
      );
      return;
    }

    for (var entry in editingItems) {
      final itemCode = entry.key;
      final controllers = _editControllers[itemCode];
      if (controllers != null) {
        final updatedItem = WarehouseItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          itemCode: controllers['itemCode']!.text,
          itemName: controllers['itemName']!.text,
          projectCode: controllers['projectCode']!.text,
          uom: controllers['uom']!.text,
          quantity: double.tryParse(controllers['quantity']!.text) ?? 0.0,
          unitCost: double.tryParse(controllers['unitCost']!.text) ?? 0.0,
          value: double.tryParse(controllers['value']!.text) ?? 0.0,
          itemNameAr: controllers['itemNameAr']!.text,
        );
        db.updateWarehouseItem(itemCode, updatedItem);
      }
    }

    setState(() {
      _editingItems.clear();
      _editControllers.clear();
      _selectedItemCodes.clear();
      _selectAll = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حفظ التعديلات بنجاح')),
    );
  }
  DataCell _buildEditableCell(WarehouseItem item, String field, {bool isNumeric = false}) {
    final isEditing = _editingItems[item.itemCode] ?? false;

    if (isEditing) {
      final controller = _editControllers[item.itemCode]?[field];
      if (field == 'uom') {
        return DataCell(
          DropdownButtonFormField<String>(
            value: AppConstants.unitOfMeasures.contains(controller?.text) ? controller?.text : AppConstants.unitOfMeasures.first,
            decoration: InputDecoration(isDense: true),
            items: AppConstants.unitOfMeasures.map((uom) => DropdownMenuItem(
              value: uom,
              child: Text(uom),
            )).toList(),
            onChanged: (value) {
              if (value != null) {
                controller?.text = value;
              }
            },
          ),
        );
      } else {
        return DataCell(
          TextFormField(
            controller: controller,
            decoration: InputDecoration(isDense: true),
            keyboardType: isNumeric ? TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          ),
        );
      }
    } else {
      return DataCell(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: item.quantity <= 5.0 && field == 'quantity' ? Colors.red[100] : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _getFieldValue(item, field),
            style: TextStyle(
              color: item.quantity <= 5.0 && field == 'quantity' ? Colors.red[800] : null,
              fontWeight: item.quantity <= 5.0 && field == 'quantity' ? FontWeight.bold : null,
            ),
          ),
        ),
      );
    }
  }

  String _getFieldValue(WarehouseItem item, String field) {
    switch (field) {
      case 'itemCode': return item.itemCode;
      case 'itemName': return item.itemName.isNotEmpty ? item.itemName : item.itemNameAr;
      case 'projectCode': return item.projectCode;
      case 'uom': return item.uom;
      case 'quantity': return item.quantity.toStringAsFixed(0);
      case 'unitCost': return '${item.unitCost.toStringAsFixed(2)} ر.س';
      case 'value': return '${item.value.toStringAsFixed(2)} ر.س';
      case 'itemNameAr': return item.itemNameAr.isNotEmpty ? item.itemNameAr : item.itemName;
      default: return '';
    }
  }

}
