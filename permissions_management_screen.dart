import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/database_service.dart';
import '../../../models/user_model.dart';
import '../../../utils/constants.dart';

class PermissionsManagementScreen extends StatefulWidget {
  @override
  _PermissionsManagementScreenState createState() => _PermissionsManagementScreenState();
}

class _PermissionsManagementScreenState extends State<PermissionsManagementScreen> {
  String _searchQuery = '';
  Map<String, bool> _expandedCategories = {};
  bool _hasUnsavedChanges = false;

  // خريطة الصلاحيات المؤقتة (قبل الحفظ)
  Map<String, Map<String, Map<String, bool>>> _tempPermissions = {};

  // تعريف فئات الصلاحيات المحدثة
  final Map<String, Map<String, String>> _permissionCategories = {
    'warehouse': {
      'view': 'عرض المستودع',
      'add': 'إضافة عناصر جديدة',
      'edit': 'تعديل العناصر المحددة',
      'delete': 'حذف العناصر المحددة',
      'save': 'حفظ التعديلات',
      'import': 'استيراد من Excel',
      'export': 'تصدير إلى Excel',
      'share_excel': 'مشاركة Excel',
      'share_pdf': 'مشاركة PDF',
      'share_text': 'مشاركة كنص',
      'print': 'طباعة',
      'select_all': 'تحديد الكل',
      'clear_selection': 'إلغاء التحديد',
      'approve_requests': 'الموافقة على طلبات الصرف',
      'send_requests': 'إرسال طلبات الصرف',
      'search_selection': 'تحديد نتائج البحث',
      'show_selected_only': 'عرض المحدد فقط',
    },
    'assets': {
      'view': 'عرض الأصول',
      'add': 'إضافة أصل جديد',
      'edit': 'تعديل الأصول المحددة',
      'delete': 'حذف الأصول المحددة',
      'save': 'حفظ التعديلات',
      'import': 'استيراد من Excel',
      'export': 'تصدير إلى Excel',
      'share_excel': 'مشاركة Excel',
      'share_pdf': 'مشاركة PDF',
      'share_text': 'مشاركة كنص',
      'print': 'طباعة',
      'select_all': 'تحديد الكل',
      'clear_selection': 'إلغاء التحديد',
      'search_selection': 'تحديد نتائج البحث',
      'show_selected_only': 'عرض المحدد فقط',
      'maintenance_requests': 'طلبات الصيانة',
    },
    'users': {
      'view': 'عرض المستخدمين',
      'add': 'إضافة مستخدمين',
      'edit': 'تعديل المستخدمين',
      'delete': 'حذف المستخدمين',
      'approve': 'الموافقة على التسجيل',
      'manage_permissions': 'إدارة الصلاحيات',
      'view_pending': 'عرض طلبات التسجيل المعلقة',
      'reject': 'رفض طلبات التسجيل',
    },
    'maintenance': {
      'view': 'عرض سجلات الصيانة',
      'add': 'إضافة سجلات صيانة',
      'edit': 'تعديل سجلات الصيانة',
      'delete': 'حذف سجلات الصيانة',
      'schedule': 'جدولة الصيانة',
      'approve_requests': 'الموافقة على طلبات الصيانة',
      'reject_requests': 'رفض طلبات الصيانة',
    },
    'reports': {
      'view': 'عرض التقارير',
      'generate': 'إنشاء التقارير',
      'export': 'تصدير التقارير',
      'schedule': 'جدولة التقارير',
      'share_excel': 'مشاركة Excel',
      'share_pdf': 'مشاركة PDF',
      'share_text': 'مشاركة نص',
      'print': 'طباعة التقارير',
    },
    'advanced_operations': {
      'bulk_operations': 'العمليات المجمعة',
      'data_management': 'إدارة البيانات',
      'system_backup': 'النسخ الاحتياطي',
      'system_restore': 'استعادة النظام',
      'export_all_data': 'تصدير جميع البيانات',
      'import_all_data': 'استيراد جميع البيانات',
      'advanced_search': 'البحث المتقدم',
      'filter_management': 'إدارة المرشحات',
    },
  };

  final Map<String, String> _categoryNames = {
    'warehouse': 'إدارة المستودع',
    'assets': 'إدارة الأصول',
    'users': 'إدارة المستخدمين',
    'maintenance': 'إدارة الصيانة',
    'reports': 'التقارير والإحصائيات',
    'advanced_operations': 'العمليات المتقدمة',
  };

  @override
  void initState() {
    super.initState();
    _initializeExpandedCategories();
    _initializeDefaultPermissions();
  }

  void _initializeExpandedCategories() {
    for (String category in _permissionCategories.keys) {
      _expandedCategories[category] = false;
    }
  }

  void _initializeDefaultPermissions() {
    // تهيئة الصلاحيات الافتراضية للمستخدمين الجدد
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = Provider.of<DatabaseService>(context, listen: false);
      final users = db.approvedUsers;

      for (User user in users) {
        if (user.permissions == null || user.permissions!.isEmpty) {
          _setDefaultPermissionsForUser(user);
        }
      }
    });
  }

  void _setDefaultPermissionsForUser(User user) {
    Map<String, Map<String, bool>> defaultPermissions = {};

    // صلاحيات افتراضية حسب الدور
    switch (user.role.toLowerCase()) {
      case 'admin':
      // الأدمن يحصل على جميع الصلاحيات
        _permissionCategories.forEach((category, permissions) {
          defaultPermissions[category] = {};
          permissions.forEach((key, value) {
            defaultPermissions[category]![key] = true;
          });
        });
        break;

      case 'manager':
      // المدير يحصل على معظم الصلاحيات عدا حذف المستخدمين وإدارة النظام
        _permissionCategories.forEach((category, permissions) {
          defaultPermissions[category] = {};
          permissions.forEach((key, value) {
            if (category == 'users' && (key == 'delete' || key == 'manage_permissions')) {
              defaultPermissions[category]![key] = false;
            } else if (category == 'advanced_operations' && (key == 'system_backup' || key == 'system_restore')) {
              defaultPermissions[category]![key] = false;
            } else {
              defaultPermissions[category]![key] = true;
            }
          });
        });
        break;

      case 'supervisor':
      // المشرف يحصل على صلاحيات العرض والتعديل والإضافة
        _permissionCategories.forEach((category, permissions) {
          defaultPermissions[category] = {};
          permissions.forEach((key, value) {
            if (key.contains('view') || key.contains('add') || key.contains('edit') ||
                key.contains('export') || key.contains('share') || key.contains('print')) {
              defaultPermissions[category]![key] = true;
            } else {
              defaultPermissions[category]![key] = false;
            }
          });
        });
        break;

      case 'warehouse_keeper':
      // أمين المستودع يحصل على صلاحيات المستودع فقط
        _permissionCategories.forEach((category, permissions) {
          defaultPermissions[category] = {};
          if (category == 'warehouse') {
            permissions.forEach((key, value) {
              if (key != 'delete' && !key.contains('approve')) {
                defaultPermissions[category]![key] = true;
              } else {
                defaultPermissions[category]![key] = false;
              }
            });
          } else {
            permissions.forEach((key, value) {
              defaultPermissions[category]![key] = false;
            });
          }
        });
        break;

      default:
      // المستخدم العادي يحصل على صلاحيات العرض فقط
        _permissionCategories.forEach((category, permissions) {
          defaultPermissions[category] = {};
          permissions.forEach((key, value) {
            defaultPermissions[category]![key] = key.contains('view');
          });
        });
        break;
    }

    // حفظ الصلاحيات الافتراضية
    _tempPermissions[user.id] = defaultPermissions;
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final users = db.approvedUsers;

    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          return await _showUnsavedChangesDialog();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          centerTitle: true,
          title: Text('إدارة الصلاحيات'),
          backgroundColor: Colors.orange[600],
          foregroundColor: Colors.white,
          elevation: 2,
          automaticallyImplyLeading: false,
          actions: [
            // زر تطبيق الصلاحيات الافتراضية
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                switch (value) {
                  case 'apply_defaults':
                    _applyDefaultPermissionsToAll();
                    break;
                  case 'reset_all':
                    _resetAllPermissions();
                    break;
                  case 'save_template':
                    _savePermissionTemplate();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'apply_defaults',
                  child: Row(
                    children: [
                      Icon(Icons.auto_fix_high, size: 18),
                      SizedBox(width: 8),
                      Text('تطبيق الصلاحيات الافتراضية'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'reset_all',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 18),
                      SizedBox(width: 8),
                      Text('إعادة تعيين الكل'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'save_template',
                  child: Row(
                    children: [
                      Icon(Icons.save_as, size: 18),
                      SizedBox(width: 8),
                      Text('حفظ كقالب'),
                    ],
                  ),
                ),
              ],
            ),
            if (_hasUnsavedChanges)
              IconButton(
                icon: Icon(Icons.save, color: Colors.white),
                onPressed: () => _saveAllPermissions(db),
                tooltip: 'حفظ التغييرات',
              ),
            IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: Column(
          children: [
            // شريط البحث والإحصائيات
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      // الإحصائيات
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCompactStat('المستخدمين', '${users.length}', Icons.people, Colors.blue),
                            _buildCompactStat('المعروض', '${_filterUsers(users).length}', Icons.visibility, Colors.green),
                            _buildCompactStat('معدّل', '${_countUsersWithChanges()}', Icons.edit, Colors.orange),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      // البحث
                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'ابحث في المستخدمين...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey[600]),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                                  : null,
                            ),
                            onChanged: (value) => setState(() => _searchQuery = value),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_hasUnsavedChanges)
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, size: 16, color: Colors.orange[700]),
                          SizedBox(width: 4),
                          Text(
                            'يوجد تغييرات غير محفوظة',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // قائمة المستخدمين
            Expanded(
              child: _filterUsers(users).isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                padding: EdgeInsets.all(8),
                itemCount: _filterUsers(users).length,
                itemBuilder: (context, index) {
                  return _buildUserPermissionCard(_filterUsers(users)[index]);
                },
              ),
            ),
          ],
        ),
        floatingActionButton: _hasUnsavedChanges
            ? FloatingActionButton.extended(
          onPressed: () => _saveAllPermissions(db),
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          icon: Icon(Icons.save),
          label: Text('حفظ التغييرات'),
        )
            : null,
      ),
    );
  }

  Widget _buildUserPermissionCard(User user) {
    final hasChanges = _tempPermissions.containsKey(user.id);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: hasChanges ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasChanges ? BorderSide(color: Colors.orange, width: 2) : BorderSide.none,
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (hasChanges)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'معدّل',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // إضافة زر تطبيق الصلاحيات الافتراضية للمستخدم
            IconButton(
              icon: Icon(Icons.auto_fix_high, size: 18, color: Colors.blue),
              onPressed: () => _applyDefaultPermissionsToUser(user),
              tooltip: 'تطبيق الصلاحيات الافتراضية',
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppConstants.getArabicRole(user.role)} - ${user.email}'),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(user.phone, style: TextStyle(fontSize: 12)),
                Spacer(),
                // عرض عدد الصلاحيات المفعلة
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_getTotalActivePermissions(_getUserPermissions(user))} صلاحية',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Container(
            padding: EdgeInsets.all(14),
            child: Column(
              children: [
                _buildUserPermissionsDetails(user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserPermissionsDetails(User user) {
    final userPermissions = _getUserPermissions(user);

    return Column(
      children: _permissionCategories.entries.map((category) {
        final categoryName = category.key;
        final permissions = category.value;
        final isExpanded = _expandedCategories[categoryName] ?? false;
        final activeCount = _countCategoryPermissions(userPermissions, categoryName);
        final totalCount = permissions.length;

        return Card(
          margin: EdgeInsets.symmetric(vertical: 2),
          child: Column(
            children: [
              ListTile(
                leading: Icon(_getCategoryIcon(categoryName), size: 20, color: _getCategoryColor(categoryName)),
                title: Text(
                  _categoryNames[categoryName] ?? categoryName,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: LinearProgressIndicator(
                  value: totalCount > 0 ? activeCount / totalCount : 0,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(categoryName)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // زر تفعيل/إلغاء جميع صلاحيات الفئة
                    IconButton(
                      icon: Icon(
                        activeCount == totalCount ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 18,
                        color: _getCategoryColor(categoryName),
                      ),
                      onPressed: () => _toggleCategoryPermissions(user.id, categoryName, activeCount != totalCount),
                      tooltip: activeCount == totalCount ? 'إلغاء جميع صلاحيات الفئة' : 'تفعيل جميع صلاحيات الفئة',
                    ),
                    Text(
                      '$activeCount/$totalCount',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                    ),
                  ],
                ),
                onTap: () {
                  setState(() {
                    _expandedCategories[categoryName] = !isExpanded;
                  });
                },
              ),
              if (isExpanded)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: permissions.entries.map((permission) {
                      final permissionKey = permission.key;
                      final permissionName = permission.value;
                      final hasPermission = userPermissions[categoryName]?[permissionKey] ?? false;

                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        title: Text(
                          permissionName,
                          style: TextStyle(fontSize: 13),
                        ),
                        secondary: _getPermissionIcon(permissionKey),
                        value: hasPermission,
                        onChanged: (value) {
                          _updateUserPermission(user.id, categoryName, permissionKey, value ?? false);
                        },
                        activeColor: _getCategoryColor(categoryName),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactStat(String title, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'لم يتم العثور على مستخدمين',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // دوال مساعدة جديدة
  void _applyDefaultPermissionsToUser(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تطبيق الصلاحيات الافتراضية'),
        content: Text('هل تريد تطبيق الصلاحيات الافتراضية للمستخدم ${user.name}؟\nسيتم استبدال جميع الصلاحيات الحالية.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              _setDefaultPermissionsForUser(user);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم تطبيق الصلاحيات الافتراضية للمستخدم ${user.name}')),
              );
            },
            child: Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  void _applyDefaultPermissionsToAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تطبيق الصلاحيات الافتراضية للجميع'),
        content: Text('هل تريد تطبيق الصلاحيات الافتراضية لجميع المستخدمين؟\nسيتم استبدال جميع الصلاحيات الحالية.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final db = Provider.of<DatabaseService>(context, listen: false);
              final users = db.approvedUsers;

              for (User user in users) {
                _setDefaultPermissionsForUser(user);
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم تطبيق الصلاحيات الافتراضية لجميع المستخدمين')),
              );
            },
            child: Text('تطبيق للجميع'),
          ),
        ],
      ),
    );
  }

  void _resetAllPermissions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إعادة تعيين جميع الصلاحيات'),
        content: Text('هل تريد إلغاء جميع الصلاحيات لجميع المستخدمين؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final db = Provider.of<DatabaseService>(context, listen: false);
              final users = db.approvedUsers;

              for (User user in users) {
                Map<String, Map<String, bool>> emptyPermissions = {};
                _permissionCategories.forEach((category, permissions) {
                  emptyPermissions[category] = {};
                  permissions.forEach((key, value) {
                    emptyPermissions[category]![key] = false;
                  });
                });
                _tempPermissions[user.id] = emptyPermissions;
              }

              setState(() {
                _hasUnsavedChanges = true;
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم إعادة تعيين جميع الصلاحيات')),
              );
            },
            child: Text('إعادة تعيين'),
          ),
        ],
      ),
    );
  }

  void _savePermissionTemplate() {
    // يمكن تنفيذ هذه الوظيفة لاحقاً لحفظ قوالب الصلاحيات
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ميزة حفظ القوالب ستكون متاحة قريباً')),
    );
  }

  void _toggleCategoryPermissions(String userId, String category, bool enable) {
    setState(() {
      if (!_tempPermissions.containsKey(userId)) {
        _tempPermissions[userId] = {};
      }
      if (!_tempPermissions[userId]!.containsKey(category)) {
        _tempPermissions[userId]![category] = {};
      }

      _permissionCategories[category]?.forEach((key, value) {
        _tempPermissions[userId]![category]![key] = enable;
      });

      _hasUnsavedChanges = true;
    });
  }

  Icon _getPermissionIcon(String permissionKey) {
    if (permissionKey.contains('view')) return Icon(Icons.visibility, size: 16, color: Colors.blue);
    if (permissionKey.contains('add')) return Icon(Icons.add, size: 16, color: Colors.green);
    if (permissionKey.contains('edit')) return Icon(Icons.edit, size: 16, color: Colors.orange);
    if (permissionKey.contains('delete')) return Icon(Icons.delete, size: 16, color: Colors.red);
    if (permissionKey.contains('save')) return Icon(Icons.save, size: 16, color: Colors.blue);
    if (permissionKey.contains('import')) return Icon(Icons.upload_file, size: 16, color: Colors.purple);
    if (permissionKey.contains('export')) return Icon(Icons.download, size: 16, color: Colors.green);
    if (permissionKey.contains('share')) return Icon(Icons.share, size: 16, color: Colors.orange);
    if (permissionKey.contains('print')) return Icon(Icons.print, size: 16, color: Colors.blue);
    if (permissionKey.contains('select')) return Icon(Icons.check_box, size: 16, color: Colors.purple);
    if (permissionKey.contains('approve')) return Icon(Icons.check_circle, size: 16, color: Colors.green);
    if (permissionKey.contains('reject')) return Icon(Icons.cancel, size: 16, color: Colors.red);
    if (permissionKey.contains('search')) return Icon(Icons.search, size: 16, color: Colors.blue);
    if (permissionKey.contains('show')) return Icon(Icons.filter_list, size: 16, color: Colors.teal);
    if (permissionKey.contains('clear')) return Icon(Icons.clear_all, size: 16, color: Colors.grey);
    if (permissionKey.contains('schedule')) return Icon(Icons.schedule, size: 16, color: Colors.blue);
    if (permissionKey.contains('backup')) return Icon(Icons.backup, size: 16, color: Colors.green);
    if (permissionKey.contains('restore')) return Icon(Icons.restore, size: 16, color: Colors.orange);
    if (permissionKey.contains('bulk')) return Icon(Icons.layers, size: 16, color: Colors.purple);
    if (permissionKey.contains('data')) return Icon(Icons.storage, size: 16, color: Colors.blue);
    if (permissionKey.contains('advanced')) return Icon(Icons.settings, size: 16, color: Colors.grey);
    if (permissionKey.contains('filter')) return Icon(Icons.filter_alt, size: 16, color: Colors.teal);
    if (permissionKey.contains('manage')) return Icon(Icons.admin_panel_settings, size: 16, color: Colors.red);
    if (permissionKey.contains('generate')) return Icon(Icons.auto_awesome, size: 16, color: Colors.green);
    if (permissionKey.contains('maintenance') || permissionKey.contains('requests')) return Icon(Icons.build, size: 16, color: Colors.orange);
    return Icon(Icons.security, size: 16, color: Colors.grey);
  }

  // دوال مساعدة
  List<User> _filterUsers(List<User> users) {
    if (_searchQuery.isEmpty) return users;
    final query = _searchQuery.toLowerCase();
    return users.where((user) =>
    user.name.toLowerCase().contains(query) ||
        user.email.toLowerCase().contains(query) ||
        user.role.toLowerCase().contains(query) ||
        user.phone.toLowerCase().contains(query)).toList();
  }

  Map<String, Map<String, bool>> _getUserPermissions(User user) {
    if (_tempPermissions.containsKey(user.id)) {
      return _tempPermissions[user.id]!;
    }
    return user.permissions ?? {};
  }

  void _updateUserPermission(String userId, String category, String permission, bool value) {
    setState(() {
      if (!_tempPermissions.containsKey(userId)) {
        _tempPermissions[userId] = {};
      }
      if (!_tempPermissions[userId]!.containsKey(category)) {
        _tempPermissions[userId]![category] = {};
      }
      _tempPermissions[userId]![category]![permission] = value;
      _hasUnsavedChanges = true;
    });
  }

  int _countCategoryPermissions(Map<String, Map<String, bool>> userPermissions, String category) {
    final categoryPerms = userPermissions[category] ?? {};
    return categoryPerms.values.where((v) => v).length;
  }

  int _getTotalActivePermissions(Map<String, Map<String, bool>> userPermissions) {
    int total = 0;
    userPermissions.forEach((category, permissions) {
      total += permissions.values.where((v) => v).length;
    });
    return total;
  }

  int _countUsersWithChanges() {
    return _tempPermissions.length;
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'manager':
        return Colors.blue;
      case 'supervisor':
        return Colors.orange;
      case 'warehouse_keeper':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'warehouse':
        return Icons.inventory;
      case 'assets':
        return Icons.directions_car;
      case 'users':
        return Icons.people;
      case 'maintenance':
        return Icons.build;
      case 'reports':
        return Icons.analytics;
      case 'advanced_operations':
        return Icons.settings_applications;
      default:
        return Icons.security;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'warehouse':
        return Colors.green;
      case 'assets':
        return Colors.blue;
      case 'users':
        return Colors.purple;
      case 'maintenance':
        return Colors.orange;
      case 'reports':
        return Colors.teal;
      case 'advanced_operations':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Future<void> _saveAllPermissions(DatabaseService db) async {
    try {
      for (String userId in _tempPermissions.keys) {
        await db.updateUserPermissions(userId, _tempPermissions[userId]!);
      }

      setState(() {
        _tempPermissions.clear();
        _hasUnsavedChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('تم حفظ جميع التغييرات بنجاح'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء حفظ الصلاحيات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تغييرات غير محفوظة'),
        content: Text('يوجد تغييرات غير محفوظة. هل تريد المغادرة بدون حفظ؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('البقاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('المغادرة', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveAllPermissions(Provider.of<DatabaseService>(context, listen: false));
              Navigator.of(context).pop(true);
            },
            child: Text('حفظ والمغادرة'),
          ),
        ],
      ),
    ) ?? false;
  }
}