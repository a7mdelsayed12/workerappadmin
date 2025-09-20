import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../../services/database_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../models/maintenance_request.dart';
import '../../../models/asset.dart';
import 'maintenance_requests_screen.dart';


class AssetsViewOnlyScreen extends StatefulWidget {
  @override
  _AssetsViewOnlyScreenState createState() => _AssetsViewOnlyScreenState();
}

class _AssetsViewOnlyScreenState extends State<AssetsViewOnlyScreen> {
  String _searchQuery = '';
  final List<String> _selectedAssetIds = []; // قائمة العناصر المحددة
  bool _selectAll = false;
  bool _showSelectedOnly = false;

  final Map<String, Map<String, TextEditingController>> _editControllers = {};
  final Map<String, bool> _editingItems = {};
  int _selectedIndex = 0;
  final List<String> tabs = ['الأصول', 'طلبات الصيانة'];

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final allAssets = db.assets;

    // الفلترة للبحث والعرض المحدد
    final filteredAssets = allAssets.where((v) {
      // إذا كان وضع "عرض المحدد" مفعل، فلنعرض فقط العناصر المحددة
      if (_showSelectedOnly && !_selectedAssetIds.contains(v.id)) {
        return false;
      }

      // ثم الفلترة حسب البحث
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return v.assetNumber.toLowerCase().contains(query) ||
          v.nameEn.toLowerCase().contains(query) ||
          v.projectNumber.toLowerCase().contains(query) ||
          v.equipmentId.toLowerCase().contains(query) ||
          v.employeeName.toLowerCase().contains(query) ||
          v.employeeId.toLowerCase().contains(query) ||
          v.nameAr.toLowerCase().contains(query);
    }).toList();

    // العناصر المحددة الفعلية
    final selectedAssets = allAssets.where((v) => _selectedAssetIds.contains(v.id)).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],

// اعدل الـ AppBar بالشكل ده:

// اعدل الـ AppBar بالشكل ده:

      appBar: AppBar(
        leadingWidth: 120, // ← اضيف هذا السطر
        centerTitle: true,
        title: Text('عرض الأصول'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,

        // استبدل الـ leading بهذا الكود:
        leading: Container(
          width: 120,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // زر الـ 3 نقاط مصغر
              SizedBox(
                width: 40,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_vert, color: Colors.white, size: 18),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        if (_selectedAssetIds.isNotEmpty) _enableEditingForSelected();
                        break;
                      case 'add':
                        _showAddAssetDialog(context);
                        break;
                      case 'delete':
                        if (_selectedAssetIds.isNotEmpty) _deleteSelectedAssets(context, db);
                        break;
                      case 'save':
                        _saveChanges(context, db);
                        break;
                      case 'import':
                        _importFromExcel(context, db);
                        break;
                      case 'export':
                        _exportToExcel(selectedAssets.isNotEmpty ? selectedAssets : filteredAssets);
                        break;
                      case 'share':
                        _shareAssets(selectedAssets.isNotEmpty ? selectedAssets : filteredAssets);
                        break;
                      case 'print':
                        _printAssets(selectedAssets.isNotEmpty ? selectedAssets : filteredAssets);
                        break;
                      case 'select_all':
                        _toggleSelectAll(filteredAssets);
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
                      enabled: _selectedAssetIds.isNotEmpty,
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16, color: _selectedAssetIds.isNotEmpty ? Colors.teal : Colors.grey),
                          SizedBox(width: 6),
                          Text('تعديل المحدد', style: TextStyle(fontSize: 12, color: _selectedAssetIds.isNotEmpty ? Colors.teal : Colors.grey)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'add',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 16, color: Colors.green),
                          SizedBox(width: 6),
                          Text('إضافة أصل جديد', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      enabled: _selectedAssetIds.isNotEmpty,
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: _selectedAssetIds.isNotEmpty ? Colors.red : Colors.grey),
                          SizedBox(width: 6),
                          Text('مسح المحدد', style: TextStyle(fontSize: 12, color: _selectedAssetIds.isNotEmpty ? Colors.red : Colors.grey)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'save',
                      child: Row(
                        children: [
                          Icon(Icons.save, size: 16, color: Colors.blue),
                          SizedBox(width: 6),
                          Text('حفظ التعديلات', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'import',
                      child: Row(
                        children: [
                          Icon(Icons.upload_file, size: 16, color: Colors.purple),
                          SizedBox(width: 6),
                          Text('استيراد من Excel', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.download, size: 16, color: Colors.green),
                          SizedBox(width: 6),
                          Text('تصدير إلى Excel', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, size: 16, color: Colors.orange),
                          SizedBox(width: 6),
                          Text('مشاركة', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'print',
                      child: Row(
                        children: [
                          Icon(Icons.print, size: 16, color: Colors.blue),
                          SizedBox(width: 6),
                          Text('طباعة', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'select_all',
                      child: Row(
                        children: [
                          Icon(Icons.select_all, size: 16, color: Colors.purple),
                          SizedBox(width: 6),
                          Text('تحديد الكل', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'clear_selection',
                      enabled: _selectedAssetIds.isNotEmpty,
                      child: Row(
                        children: [
                          Icon(Icons.clear_all, size: 16, color: _selectedAssetIds.isNotEmpty ? Colors.red : Colors.grey),
                          SizedBox(width: 6),
                          Text('إلغاء التحديد', style: TextStyle(fontSize: 12, color: _selectedAssetIds.isNotEmpty ? Colors.red : Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // زر إرسال للصيانة
              if (_selectedAssetIds.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(left: 4),
                  child: InkWell(
                    onTap: () => _sendToMaintenance(),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.build, size: 14, color: Colors.white),
                          SizedBox(height: 3),
                          Text(
                            'إرسال\nللصيانة',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        actions: [
          // احذف زر الصيانة من هنا واترك الباقي كما هو

          // زر تحديد البحث
          if (_searchQuery.isNotEmpty)
            Container(
              margin: EdgeInsets.only(left: 6),
              child: InkWell(
                onTap: () => _selectSearchResults(filteredAssets),
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
                      Icon(Icons.search, size: 14, color: Colors.white),
                      SizedBox(height: 3),
                      Text(
                        'تحديد\nالبحث',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // زر عرض المحدد
          if (_selectedAssetIds.isNotEmpty)
            Container(
              margin: EdgeInsets.only(left: 6),
              child: InkWell(
                onTap: () => _toggleShowSelectedOnly(),
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
                      Icon(Icons.filter_list, size: 14, color: Colors.white),
                      SizedBox(height: 3),
                      Text(
                        _showSelectedOnly ? 'عرض\nالكل' : 'عرض\nالمحدد',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // زر الرجوع
          IconButton(
            icon: Icon(Icons.arrow_forward, size: 20),
            onPressed: () => Navigator.pop(context),
            tooltip: 'رجوع',
          ),
        ],
      ),

      body: Column(
        children: [


          // استبدل شريط الإحصائيات بهذا الكود المحدث:

          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // الإحصائيات فقط
                Row(
                  children: [
                    _buildStatCard('الأصول', '${allAssets.length}', Colors.blue),
                    SizedBox(width: 10),
                    _buildStatCard('المعروض', '${filteredAssets.length}', Colors.green),
                    SizedBox(width: 10),
                    _buildStatCard('المحدد', '${_selectedAssetIds.length}', Colors.orange),
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
                          textAlign: TextAlign.right, // إضافة هذه السطر
                          textDirection: TextDirection.rtl, // إضافة هذه السطر للمحاذاة الصحيحة للنص العربي
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 18),
                            hintText: 'ابحث في الأصول...',
                            hintStyle: TextStyle(fontSize: 12),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            isDense: true, // لجعل الحقل أكثر إحكاماً
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

          // المحتوى
          // شريط التبويب
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
                            color: _selectedIndex == index ? Colors.blue[600]! : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedIndex == index ? Colors.blue[600] : Colors.black,
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
                // تبويب الأصول
                filteredAssets.isEmpty
                    ? _buildEmptyState()
                    : _buildDataTable(filteredAssets),
                // تبويب طلبات الصيانة
                // استبدل هذا الجزء في الكود:
// Center(child: Text('تبويب طلبات الصيانة قيد التطوير')),

// بهذا الكود:

                Consumer<DatabaseService>(
                  builder: (context, db, child) {
                    final maintenanceRequests = db.maintenanceRequests;

                    if (maintenanceRequests.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.build_circle_outlined, size: 64, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              'لا توجد طلبات صيانة',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'قم بتحديد أصول وإرسالها للصيانة',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        // شريط الإحصائيات
                        Container(
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              _buildMaintenanceStatCard(
                                  'إجمالي الطلبات',
                                  '${maintenanceRequests.length}',
                                  Colors.blue
                              ),
                              SizedBox(width: 12),
                              _buildMaintenanceStatCard(
                                  'معلقة',
                                  '${db.pendingMaintenanceRequests.length}',
                                  Colors.orange
                              ),
                              SizedBox(width: 12),
                              _buildMaintenanceStatCard(
                                  'مكتملة',
                                  '${db.completedMaintenanceRequests.length}',
                                  Colors.green
                              ),
                            ],
                          ),
                        ),

                        Divider(height: 1),

                        // قائمة طلبات الصيانة
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: maintenanceRequests.length,
                            itemBuilder: (context, index) {
                              final request = maintenanceRequests[index];
                              return Card(
                                margin: EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showMaintenanceRequestDetails(request),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // الصف الأول - رقم الأصل والحالة
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'رقم الأصل: ${request.assetNumber}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.blue[700],
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(request.status).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: _getStatusColor(request.status),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                request.statusArabic,
                                                style: TextStyle(
                                                  color: _getStatusColor(request.status),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        SizedBox(height: 8),

                                        // اسم الأصل
                                        Text(
                                          request.assetNameAr.isNotEmpty
                                              ? request.assetNameAr
                                              : request.assetNameEn,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),

                                        SizedBox(height: 8),

                                        // وصف المشكلة
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'وصف المشكلة:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                request.problemDescription,
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),

                                        SizedBox(height: 12),

                                        // الصف الأخير - التاريخ والموظف
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                            SizedBox(width: 4),
                                            Text(
                                              request.formattedRequestDate,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Spacer(),
                                            Icon(Icons.person, size: 16, color: Colors.grey[600]),
                                            SizedBox(width: 4),
                                            Text(
                                              request.employeeName,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

// ابحث عن دالة _buildStatCard واستبدلها بهذا الكود المحسن:

// استبدل دالة _buildStatCard بهذا الكود المضغوط:

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatIcon(title), size: 16, color: color),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
              height: 1.2,
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
            _searchQuery.isEmpty ? Icons.inbox_outlined : Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'لا توجد أصول' : 'لم يتم العثور على نتائج',
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
                'قم بإضافة أو استيراد الأصول أولاً',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }

  // استبدل دالة _buildDataTable بهذا الكود المحسن:

  Widget _buildDataTable(List<Asset> assets) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Expanded(
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
                                onTap: () => _toggleSelectAll(assets),
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
                        _buildHeaderCell('رقم الأصل', 100),
                        _buildHeaderCell('الوصف\nبالإنجليزي', 150),
                        _buildHeaderCell('رقم المشروع', 120),
                        _buildHeaderCell('رقم المعدة', 100),
                        _buildHeaderCell('اسم الموظف', 120),
                        _buildHeaderCell('الرقم الوظيفي', 100),
                        _buildHeaderCell('الوصف بالعربي', 150),
                      ],
                    ),
                  ),

                  // البيانات
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: assets.map((asset) {
                          final isSelected = _selectedAssetIds.contains(asset.id);

                          return Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue[50] : Colors.white,
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
                                            _selectedAssetIds.add(asset.id);
                                          } else {
                                            _selectedAssetIds.remove(asset.id);
                                          }
                                          _updateSelectAllState(assets);
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                _buildAssetDataCell(asset, 'assetNumber', 100),
                                _buildAssetDataCell(asset, 'nameEn', 150),
                                _buildAssetDataCell(asset, 'projectNumber', 120),
                                _buildAssetDataCell(asset, 'equipmentId', 100),
                                _buildAssetDataCell(asset, 'employeeName', 120),
                                _buildAssetDataCell(asset, 'employeeId', 100),
                                _buildAssetDataCell(asset, 'nameAr', 150),
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
        ],
      ),
    );
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
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
} // القوس الأخير للكلاس
  Widget _buildAssetDataCell(Asset asset, String field, double width) {
    final isEditing = _editingItems[asset.id] ?? false;

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: isEditing ?
      TextFormField(
        controller: _editControllers[asset.id]?[field],
        decoration: InputDecoration(isDense: true),
      ) :
      Text(
        _getFieldValue(asset, field),
        style: TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

// أضف هذه الدالة الجديدة لتحديد نتائج البحث فقط
  void _selectSearchResults(List<Asset> assets) {
    setState(() {
      // إضافة جميع العناصر المعروضة في نتائج البحث للتحديد
      for (var asset in assets) {
        if (!_selectedAssetIds.contains(asset.id)) {
          _selectedAssetIds.add(asset.id);
        }
      }
      _updateSelectAllState(assets);
    });
  }

  void _toggleSelectAll(List<Asset> assets) {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        // إضافة جميع العناصر المعروضة للتحديد
        for (var assets in assets) {
          if (!_selectedAssetIds.contains(assets.id)) {
            _selectedAssetIds.add(assets.id);
          }
        }
      } else {
        // إزالة جميع العناصر المعروضة من التحديد
        for (var asset in assets) {
          _selectedAssetIds.remove(asset.id);
        }
      }
    });
  }

  void _updateSelectAllState(List<Asset> assets) {
    final allDisplayedSelected = assets.every((v) => _selectedAssetIds.contains(v.id));
    setState(() {
      _selectAll = allDisplayedSelected && assets.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedAssetIds.clear();
      _selectAll = false;
    });
  }

  // أضف هذه المكتبة في أعلى الملف

// استبدل دالة _exportToExcel بهذا الكود المحدث:
  Future<void> _exportToExcel(List<Asset> assets) async {
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
      final sheet = excelFile['قائمة الأصول'];

      // إضافة الرؤوس
      sheet.cell(excel.CellIndex.indexByString('A1')).value = excel.TextCellValue('رقم الأصل');
      sheet.cell(excel.CellIndex.indexByString('B1')).value = excel.TextCellValue('الوصف بالإنجليزي');
      sheet.cell(excel.CellIndex.indexByString('C1')).value = excel.TextCellValue('رقم المشروع');
      sheet.cell(excel.CellIndex.indexByString('D1')).value = excel.TextCellValue('رقم المعدة');
      sheet.cell(excel.CellIndex.indexByString('E1')).value = excel.TextCellValue('اسم الموظف');
      sheet.cell(excel.CellIndex.indexByString('F1')).value = excel.TextCellValue('الرقم الوظيفي');
      sheet.cell(excel.CellIndex.indexByString('G1')).value = excel.TextCellValue('الوصف بالعربي');

      // إضافة البيانات
      for (int i = 0; i < assets.length; i++) {
        final v = assets[i];
        final rowIndex = i + 2;

        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = excel.TextCellValue(v.assetNumber);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = excel.TextCellValue(v.nameEn);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = excel.TextCellValue(v.projectNumber);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = excel.TextCellValue(v.equipmentId);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = excel.TextCellValue(v.employeeName);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = excel.TextCellValue(v.employeeId);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = excel.TextCellValue(v.nameAr);
      }

      // حفظ الملف في مجلد Downloads
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'قائمة_الأصول_$timestamp.xlsx';

      // مسار Downloads للأندرويد
      final downloadsPath = '/storage/emulated/0/Download';
      final filePath = '$downloadsPath/$fileName';
      String finalSavedPath = filePath; // هنا عرّفت المتغير

      try {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(excelFile.encode()!);
      } catch (e) {
        // إذا فشل في Downloads، جرب مجلد التطبيق
        final directory = await getApplicationDocumentsDirectory();
        final fallbackPath = '${directory.path}/$fileName';
        finalSavedPath = fallbackPath; // هنا حدّثت المتغير
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
              Text('تم تصدير ${assets.length} عنصر إلى ملف Excel'),
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
                  finalSavedPath, // هنا استخدمت المتغير الصحيح
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ),
              SizedBox(height: 8),
              Text('يمكنك نسخ المسار بالضغط عليه',
                  style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold)),
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

  void _printAssets(List<Asset> assets) {
    // إنشاء محتوى قابل للطباعة
    String printContent = "قائمة الأصول\n\n";
    for (var asset in assets) {
      printContent += "رقم الأصل: ${asset.assetNumber}\n";
      printContent += "الوصف بالإنجليزية: ${asset.nameEn}\n";
      printContent += "الوصف بالعربية: ${asset.nameAr}\n";
      printContent += "رقم المشروع: ${asset.projectNumber}\n";
      printContent += "رقم المعدة: ${asset.equipmentId}\n";
      printContent += "اسم الموظف: ${asset.employeeName}\n";
      printContent += "الرقم الوظيفي: ${asset.employeeId}\n";
      printContent += "────────────────────────\n";
    }

    // عرض محتوى الطباعة في صفحة منفصلة
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('طباعة ${assets.length} عنصر'),
            actions: [
              IconButton(
                icon: Icon(Icons.print),
                onPressed: () {
                  // هنا يمكنك إضافة كود الطباعة الفعلي
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

  void _shareAssets(List<Asset> assets) async {
    if (assets.isEmpty) {
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
            Text('مشاركة ${assets.length} عنصر'),
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
                _shareExcelFile(assets);
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
                _sharePdfFile(assets);
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
                _shareTextContent(assets);
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

// الدالة الجديدة لمشاركة النص
  void _shareTextContent(List<Asset> assets) async {
    try {
      // بناء محتوى النص
      String textContent = "";
      textContent += "📋 قائمة الأصول\n";
      textContent += "═══════════════\n\n";
      textContent += "📅 التاريخ: ${DateTime.now().toString().substring(0, 10)}\n";
      textContent += "📊 إجمالي العناصر: ${assets.length}\n\n";

      for (int i = 0; i < assets.length; i++) {
        var asset = assets[i];
        textContent += "🔸 العنصر ${i + 1}:\n";
        textContent += "  رقم الأصل: ${asset.assetNumber}\n";

        if (asset.nameEn.isNotEmpty) {
          textContent += "  الوصف (EN): ${asset.nameEn}\n";
        }
        if (asset.nameAr.isNotEmpty) {
          textContent += "  الوصف (AR): ${asset.nameAr}\n";
        }

        textContent += "  رقم المشروع: ${asset.projectNumber}\n";
        textContent += "  رقم المعدة: ${asset.equipmentId}\n";
        textContent += "  اسم الموظف: ${asset.employeeName}\n";
        textContent += "  الرقم الوظيفي: ${asset.employeeId}\n";
        textContent += "─────────────────\n";
      }

      textContent += "\n📱 تم إنشاؤه بواسطة نظام إدارة الأصول";

      // مشاركة النص
      Share.share(
        textContent,
        subject: 'قائمة الأصول - ${assets.length} عنصر',
      );

      // رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('تم مشاركة ${assets.length} عنصر كنص'),
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

// دالة لإنشاء ومشاركة ملف Excel
  void _shareExcelFile(List<Asset> assets) async {
    try {
      // أولاً ننشئ ملف Excel بنفس طريقة التصدير
      final excelFile = excel.Excel.createExcel();
      final sheet = excelFile['قائمة الأصول'];

      // إضافة الرؤوس
      sheet.cell(excel.CellIndex.indexByString('A1')).value = excel.TextCellValue('رقم الأصل');
      sheet.cell(excel.CellIndex.indexByString('B1')).value = excel.TextCellValue('الوصف بالإنجليزي');
      sheet.cell(excel.CellIndex.indexByString('C1')).value = excel.TextCellValue('رقم المشروع');
      sheet.cell(excel.CellIndex.indexByString('D1')).value = excel.TextCellValue('رقم المعدة');
      sheet.cell(excel.CellIndex.indexByString('E1')).value = excel.TextCellValue('اسم الموظف');
      sheet.cell(excel.CellIndex.indexByString('F1')).value = excel.TextCellValue('الرقم الوظيفي');
      sheet.cell(excel.CellIndex.indexByString('G1')).value = excel.TextCellValue('الوصف بالعربي');

      // إضافة البيانات
      for (int i = 0; i < assets.length; i++) {
        final v = assets[i];
        final rowIndex = i + 2;

        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = excel.TextCellValue(v.assetNumber);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = excel.TextCellValue(v.nameEn);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = excel.TextCellValue(v.projectNumber);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = excel.TextCellValue(v.equipmentId);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = excel.TextCellValue(v.employeeName);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = excel.TextCellValue(v.employeeId);
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = excel.TextCellValue(v.nameAr);
      }

      // حفظ الملف مؤقتاً للمشاركة
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'قائمة_الأصول_$timestamp.xlsx';
      final filePath = '${directory.path}/$fileName';

      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excelFile.encode()!);

      // مشاركة الملف
      Share.shareFiles([filePath], subject: 'قائمة الأصول', text: 'مرفق قائمة الأصول المحددة');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء إنشاء الملف: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  // استبدل دالة _sharePdfFile بهذا الكود المصحح:
  void _sharePdfFile(List<Asset> assets) async {
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
        print('Arabic font loaded successfully');
      } catch (e) {
        print('Failed to load Arabic font: $e');
      }

      // عدد الصفوف في كل صفحة
      const int itemsPerPage = 10;
      final int totalPages = (assets.length / itemsPerPage).ceil();

      // إنشاء الصفحات
      for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
        final int startIndex = pageIndex * itemsPerPage;
        final int endIndex = (startIndex + itemsPerPage).clamp(0, assets.length);
        final List<Asset> pageAssets = assets.sublist(startIndex, endIndex);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return pw.Column(
                children: [
                  // Header
                  _buildPdfHeaderMixed(pageIndex + 1, totalPages, assets.length, arabicFont),

                  pw.SizedBox(height: 10),

                  // الجدول
                  pw.Expanded(
                    child: pw.Table(
                      border: pw.TableBorder.all(width: 0.5),
                      columnWidths: {
                        0: pw.FixedColumnWidth(50),   // رقم الأصل
                        1: pw.FlexColumnWidth(2.5),   // الوصف بالإنجليزي
                        2: pw.FixedColumnWidth(50),   // رقم المشروع
                        3: pw.FixedColumnWidth(50 ),   // رقم المعدة
                        4: pw.FlexColumnWidth(2),     // اسم الموظف
                        5: pw.FixedColumnWidth(55),   // الرقم الوظيفي
                        6: pw.FlexColumnWidth(2),   // الوصف بالعربي
                      },
                      children: [
                        // صف الرؤوس
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: PdfColors.grey300),
                          children: [
                            _buildMixedTextCell('رقم الأصل', isHeader: true, isArabic: true, arabicFont: arabicFont),
                            _buildMixedTextCell('الوصف بالإنجليزي', isHeader: true, isArabic: true, arabicFont: arabicFont),
                            _buildMixedTextCell('رقم المشروع', isHeader: true, isArabic: true, arabicFont: arabicFont),
                            _buildMixedTextCell('رقم المعدة', isHeader: true, isArabic: true, arabicFont: arabicFont),
                            _buildMixedTextCell('اسم الموظف', isHeader: true, isArabic: true, arabicFont: arabicFont),
                            _buildMixedTextCell('الرقم الوظيفي', isHeader: true, isArabic: true, arabicFont: arabicFont),
                            _buildMixedTextCell('الوصف بالعربي', isHeader: true, isArabic: true, arabicFont: arabicFont),
                          ],
                        ),
                        // صفوف البيانات
                        ...pageAssets.map((asset) => pw.TableRow(
                          children: [
                            _buildMixedTextCell(asset.assetNumber, isArabic: false, arabicFont: arabicFont),
                            _buildMixedTextCell(asset.nameEn.isNotEmpty ? asset.nameEn : '-', isArabic: false, arabicFont: arabicFont),
                            _buildMixedTextCell(asset.projectNumber, isArabic: false, arabicFont: arabicFont),
                            _buildMixedTextCell(asset.equipmentId, isArabic: false, arabicFont: arabicFont),
                            _buildMixedTextCell(asset.employeeName, isArabic: false, arabicFont: arabicFont),
                            _buildMixedTextCell(asset.employeeId, isArabic: false, arabicFont: arabicFont),
                            _buildMixedTextCell(asset.nameAr.isNotEmpty ? asset.nameAr : asset.nameEn,
                                isArabic: asset.nameAr.isNotEmpty, arabicFont: arabicFont),
                          ],
                        )).toList(),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 10),

                  // Footer
                  _buildPdfFooterMixed(pageIndex + 1, totalPages, arabicFont),
                ],
              );
            },
          ),
        );
      }

      // حفظ ومشاركة الملف
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'قائمة_الأصول_$timestamp.pdf';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      Navigator.pop(context);

      Share.shareFiles(
          [filePath],
          subject: 'قائمة الأصول PDF - ${assets.length} عنصر',
          text: 'مرفق قائمة الأصول الكاملة بصيغة PDF ($totalPages صفحة)'
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('تم إنشاء PDF من $totalPages صفحة بنجاح'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
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

// دالة بناء هيدر مختلط
  pw.Widget _buildPdfHeaderMixed(int currentPage, int totalPages, int totalItems, pw.Font? arabicFont) {
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // العنوان بالعربي (بالخط العربي)
              pw.Text(
                'قائمة الأصول',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  font: arabicFont,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              // رقم الصفحة بالإنجليزي (بالخط العادي)
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
              // التاريخ بالعربي
              pw.Text(
                'التاريخ: ${DateTime.now().toString().substring(0, 10)}',
                style: pw.TextStyle(fontSize: 10, font: arabicFont),
                textDirection: pw.TextDirection.rtl,
              ),
              // العدد بالعربي
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

// دالة بناء تذييل مختلط
  pw.Widget _buildPdfFooterMixed(int currentPage, int totalPages, pw.Font? arabicFont) {
    return pw.Container(
      margin: pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        children: [
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // النص العربي
              pw.Text(
                'تم الإنشاء بواسطة نظام إدارة الأصول',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, font: arabicFont),
                textDirection: pw.TextDirection.rtl,
              ),
              // رقم الصفحة بالإنجليزي
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

// دالة ذكية لبناء خلايا مختلطة
  pw.Widget _buildMixedTextCell(String text, {bool isHeader = false, bool isArabic = false, pw.Font? arabicFont}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          font: isArabic ? arabicFont : null, // خط عربي فقط للنصوص العربية
        ),
        textAlign: pw.TextAlign.center,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        maxLines: isHeader ? 2 : 3,
      ),
    );
  }


  Color _getCheckboxHeaderColor() {
    if (_selectAll) {
      return Colors.blue[100]!;
    } else if (_selectedAssetIds.isNotEmpty) {
      return Colors.orange[100]!; // لون مختلف لما يكون فيه تحديد جزئي
    } else {
      return Colors.transparent;
    }
  }

  Color _getCheckboxIconColor() {
    if (_selectAll) {
      return Colors.blue[700]!;
    } else if (_selectedAssetIds.isNotEmpty) {
      return Colors.orange[700]!; // لون برتقالي لما يكون فيه تحديد جزئي
    } else {
      return Colors.grey[600]!;
    }
  }

  Widget _buildCompactStatCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8,
              color: Colors.white.withOpacity(0.9),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
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
                  fontSize: 8,
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

// حدث دالة _calculateLeadingWidth:
  double _calculateLeadingWidth() {
    double width = 56; // عرض الـ 3 نقاط الأساسي
    return width;
  }

  void _toggleShowSelectedOnly() {
    setState(() {
      _showSelectedOnly = !_showSelectedOnly;
    });
  }

  IconData _getStatIcon(String title) {
    if (title.contains('إجمالي')) {
      return Icons.inventory;
    } else if (title.contains('المعروض')) {
      return Icons.visibility;
    } else if (title.contains('المحدد')) {
      return Icons.check_box;
    } else {
      return Icons.assessment;
    }
  }
  void _deleteSelectedAssets(BuildContext context, DatabaseService db) {
    final selectedCount = _selectedAssetIds.length;
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
              for (String assetId in _selectedAssetIds) {
                db.removeAsset(assetId);
              }
              setState(() {
                _selectedAssetIds.clear();
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

  void _enableEditingForSelected() {
    setState(() {
      for (String assetId in _selectedAssetIds) {
        _editingItems[assetId] = true;
        if (!_editControllers.containsKey(assetId)) {
          final asset = Provider.of<DatabaseService>(context, listen: false)
              .assets
              .firstWhere((v) => v.id == assetId);

          _editControllers[assetId] = {
            'assetNumber': TextEditingController(text: asset.assetNumber),
            'nameEn': TextEditingController(text: asset.nameEn),
            'projectNumber': TextEditingController(text: asset.projectNumber),
            'equipmentId': TextEditingController(text: asset.equipmentId),
            'employeeName': TextEditingController(text: asset.employeeName),
            'employeeId': TextEditingController(text: asset.employeeId),
            'nameAr': TextEditingController(text: asset.nameAr),
          };
        }
      }
    });
  }

  void _showAddAssetDialog(BuildContext context) {
    final assetNumberCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();
    final projectNumberCtrl = TextEditingController();
    final equipmentIdCtrl = TextEditingController();
    final employeeNameCtrl = TextEditingController();
    final employeeIdCtrl = TextEditingController();
    final nameArCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('إضافة أصل جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: assetNumberCtrl, decoration: InputDecoration(labelText: 'رقم الأصل')),
              SizedBox(height: 8),
              TextField(controller: nameEnCtrl, decoration: InputDecoration(labelText: 'الوصف (EN)')),
              SizedBox(height: 8),
              TextField(controller: projectNumberCtrl, decoration: InputDecoration(labelText: 'رقم المشروع')),
              SizedBox(height: 8),
              TextField(controller: equipmentIdCtrl, decoration: InputDecoration(labelText: 'رقم المعدة')),
              SizedBox(height: 8),
              TextField(controller: employeeNameCtrl, decoration: InputDecoration(labelText: 'اسم الموظف')),
              SizedBox(height: 8),
              TextField(controller: employeeIdCtrl, decoration: InputDecoration(labelText: 'الرقم الوظيفي')),
              SizedBox(height: 8),
              TextField(controller: nameArCtrl, decoration: InputDecoration(labelText: 'الوصف (AR)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (assetNumberCtrl.text.isNotEmpty && nameEnCtrl.text.isNotEmpty) {
                final id = Uuid().v4();
                final asset = Asset(
                  id: id,
                  assetNumber: assetNumberCtrl.text,
                  nameEn: nameEnCtrl.text,
                  projectNumber: projectNumberCtrl.text,
                  equipmentId: equipmentIdCtrl.text,
                  employeeName: employeeNameCtrl.text,
                  employeeId: employeeIdCtrl.text,
                  nameAr: nameArCtrl.text,
                );
                Provider.of<DatabaseService>(context, listen: false).addAsset(asset);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم إضافة الأصل بنجاح')),
                );
              }
            },
            child: Text('حفظ'),
          ),
        ],
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
              final id = Uuid().v4();
              var asset = Asset(
                id: id,
                assetNumber: sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value?.toString() ?? '',
                nameEn: sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value?.toString() ?? '',
                projectNumber: sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value?.toString() ?? '',
                equipmentId: sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value?.toString() ?? '',
                employeeName: sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value?.toString() ?? '',
                employeeId: sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value?.toString() ?? '',
                nameAr: sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value?.toString() ?? '',
              );

              await db.addAsset(asset);
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
  DataCell _buildEditableCell(Asset asset, String field) {
    final isEditing = _editingItems[asset.id] ?? false;

    if (isEditing) {
      final controller = _editControllers[asset.id]?[field];
      return DataCell(
        TextFormField(
          controller: controller,
          decoration: InputDecoration(isDense: true),
        ),
      );
    } else {
      return DataCell(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(_getFieldValue(asset, field)),
        ),
      );
    }
  }

  String _getFieldValue(Asset asset, String field) {
    switch (field) {
      case 'assetNumber': return asset.assetNumber;
      case 'nameEn': return asset.nameEn.isNotEmpty ? asset.nameEn : asset.nameAr;
      case 'projectNumber': return asset.projectNumber;
      case 'equipmentId': return asset.equipmentId;
      case 'employeeName': return asset.employeeName;
      case 'employeeId': return asset.employeeId;
      case 'nameAr': return asset.nameAr.isNotEmpty ? asset.nameAr : asset.nameEn;
      default: return '';
    }
  }
  void _saveChanges(BuildContext context, DatabaseService db) {
    print('دخل دالة الحفظ');
    print('عدد العناصر في التعديل: ${_editingItems.length}');

    final editingAssets = _editingItems.entries.where((e) => e.value).toList();
    print('عدد العناصر المحددة للحفظ: ${editingAssets.length}');

    if (editingAssets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى تحديد عناصر للحفظ')),
      );
      return;
    }

    for (var entry in editingAssets) {
      final assetId = entry.key;
      final controllers = _editControllers[assetId];
      print('حفظ العنصر: $assetId');

      if (controllers != null) {
        print('القيم الجديدة: ${controllers['assetNumber']?.text}');

        final updatedAsset = Asset(
          id: assetId,
          assetNumber: controllers['assetNumber']!.text,
          nameEn: controllers['nameEn']!.text,
          projectNumber: controllers['projectNumber']!.text,
          equipmentId: controllers['equipmentId']!.text,
          employeeName: controllers['employeeName']!.text,
          employeeId: controllers['employeeId']!.text,
          nameAr: controllers['nameAr']!.text,
        );
        db.updateAsset(assetId, updatedAsset);
        print('تم الحفظ في قاعدة البيانات');
      }
    }

    setState(() {
      _editingItems.clear();
      _editControllers.clear();
      _selectedAssetIds.clear();
      _selectAll = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حفظ التعديلات بنجاح')),
    );
  }
  void _sendToMaintenance() {
    if (_selectedAssetIds.isEmpty) return;

    final TextEditingController problemController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إرسال للصيانة'),
        scrollable: true, // ✅ الحل هنا
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل تريد إرسال ${_selectedAssetIds.length} أصل للصيانة؟'),
            SizedBox(height: 16),
            TextField(
              controller: problemController,
              decoration: InputDecoration(
                labelText: 'وصف المشكلة',
                border: OutlineInputBorder(),
                hintText: 'اكتب وصف المشكلة هنا...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createMaintenanceRequests(problemController.text);
            },
            child: Text('إرسال'),
          ),
        ],
      ),
    );
  }


  void _createMaintenanceRequests(String problemDescription) async {
    final db = Provider.of<DatabaseService>(context, listen: false);

    try {
      int successCount = 0;

      for (String assetId in _selectedAssetIds) {
        final asset = db.assets.firstWhere((a) => a.id == assetId);

        final maintenanceRequest = MaintenanceRequest(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // ✅ موجود
          assetId: asset.id,
          assetNumber: asset.assetNumber,
          assetNameEn: asset.nameEn,
          projectNumber: asset.projectNumber,
          equipmentId: asset.equipmentId,
          employeeName: asset.employeeName,
          employeeId: asset.employeeId,
          assetNameAr: asset.nameAr,
          problemDescription: problemDescription.isNotEmpty
              ? problemDescription
              : 'طلب صيانة عامة',
          requestedBy: 'المستخدم الحالي',
          requestedById: 'current_user_id',
          // ❌ ناقص هذين السطرين:
          status: 'pending',
          requestDate: DateTime.now(),
        );

        await db.addMaintenanceRequest(maintenanceRequest);
        successCount++;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إنشاء $successCount طلب صيانة بنجاح'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      setState(() {
        _selectedAssetIds.clear();
        _selectAll = false;
      });

    } catch (e) {
      print('خطأ في إنشاء طلبات الصيانة: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء إنشاء طلبات الصيانة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Widget _buildMaintenanceStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showMaintenanceRequestDetails(MaintenanceRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل طلب الصيانة'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('رقم الأصل:', request.assetNumber),
              _buildDetailRow('اسم الأصل:', request.assetNameAr.isNotEmpty ? request.assetNameAr : request.assetNameEn),
              _buildDetailRow('رقم المشروع:', request.projectNumber),
              _buildDetailRow('رقم المعدة:', request.equipmentId),
              _buildDetailRow('اسم الموظف:', request.employeeName),
              _buildDetailRow('الرقم الوظيفي:', request.employeeId),
              _buildDetailRow('وصف المشكلة:', request.problemDescription),
              _buildDetailRow('الحالة:', request.statusArabic),
              _buildDetailRow('تاريخ الطلب:', request.formattedRequestDate),
              _buildDetailRow('طلب بواسطة:', request.requestedBy),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}


