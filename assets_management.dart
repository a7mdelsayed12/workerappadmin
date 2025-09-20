import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/database_service.dart';
import '../../../models/asset.dart';
import 'assets_management_screen.dart';
import 'maintenance_requests_screen.dart';



class CarsManagement extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // AppBar متحرك
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leading: null,
            actions: [
              Container(
                margin: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'رجوع',
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[600]!,
                      Colors.purple[600]!,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // أيقونة الأصول
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(height: 10),

                      Text(
                        'إدارة الأصول',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(height: 6),

                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '${_getAssetsCount(db)} أصل مسجل',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // المحتوى الرئيسي
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // كارت إدارة الأصول الرئيسي
                  _buildMainAssetCard(context, db),

                  SizedBox(height: 16),

                  // صف الكروت الثانوية
                  Row(
                    children: [
                      Expanded(
                        child: _buildSecondaryCard(
                          context: context,
                          title: 'طلبات الصيانة',
                          subtitle: _getMaintenanceCount(db),
                          icon: Icons.build_circle,
                          color: Colors.orange[600]!,
                          onTap: () => _navigateToMaintenance(context),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildSecondaryCard(
                          context: context,
                          title: 'التقارير',
                          subtitle: 'عرض الإحصائيات',
                          icon: Icons.analytics,
                          color: Colors.green[600]!,
                          onTap: () => _navigateToReports(context),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // قسم الإحصائيات أو الحالة الفارغة
                  _getAssetsCount(db) > 0 ? _buildStatsSection(db) : _buildEmptyState(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // الكارت الرئيسي لإدارة الأصول
  Widget _buildMainAssetCard(BuildContext context, DatabaseService db) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AssetsViewOnlyScreen()),
        );
      },
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[400]!, Colors.blue[600]!],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue[600]!.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // خلفية مزخرفة
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إدارة الأصول',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'عرض وتعديل جميع الأصول',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_getAssetsCount(db)} عنصر',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // الكروت الثانوية - تم التعديل عليها لمنع الـ Overflow
  Widget _buildSecondaryCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          minHeight: 100, // تحديد حد أدنى للارتفاع
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(12), // تقليل البادنج قليلاً
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center, // توسيط المحتوى رأسيًا
            children: [
              // الصف العلوي (الأيقونة والعنوان)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // النص الفرعي
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                maxLines: 2, // السماح بسطرين للنص الفرعي
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // قسم الإحصائيات
  Widget _buildStatsSection(DatabaseService db) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إحصائيات سريعة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),

          SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'إجمالي الأصول',
                  '${_getAssetsCount(db)}',
                  Icons.inventory,
                  Colors.blue[600]!,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              Expanded(
                child: _buildStatItem(
                  'طلبات الصيانة',
                  '${_getMaintenanceRequestsCount(db)}',
                  Icons.build,
                  Colors.orange[600]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // حالة فارغة عندما لا توجد أصول
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'لا توجد أصول مسجلة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'ابدأ بإضافة أصولك الأولى',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AssetsViewOnlyScreen()),
              );
            },
            icon: Icon(Icons.add),
            label: Text('إضافة أصل'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // الدوال المساعدة الآمنة
  int _getAssetsCount(DatabaseService db) {
    try {
      if (db == null) return 0;
      return db.assets?.length ?? 0;
    } catch (e) {
      print('Error getting assets count: $e');
      return 0;
    }
  }

  String _getMaintenanceCount(DatabaseService db) {
    try {
      int count = _getMaintenanceRequestsCount(db);
      return count > 0 ? '$count طلب' : 'لا توجد طلبات';
    } catch (e) {
      print('Error getting maintenance count: $e');
      return 'لا توجد طلبات';
    }
  }

  int _getMaintenanceRequestsCount(DatabaseService db) {
    try {
      if (db == null) return 0;

      // التحقق الآمن من وجود الخاصية
      dynamic maintenanceRequests;
      try {
        // محاولة الوصول للخاصية بطريقة آمنة
        final dbString = db.toString();
        if (dbString.contains('maintenanceRequests')) {
          maintenanceRequests = db.maintenanceRequests;
        } else {
          return 0; // الخاصية غير موجودة
        }
      } catch (e) {
        return 0;
      }

      if (maintenanceRequests == null) return 0;
      if (maintenanceRequests is List) {
        return maintenanceRequests.length;
      }
      return 0;
    } catch (e) {
      print('Error getting maintenance requests count: $e');
      return 0;
    }
  }

  void _navigateToMaintenance(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MaintenanceRequestsScreen(userRole: 'admin')),
    );
  }



  void _navigateToReports(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('سيتم إضافة شاشة التقارير قريباً'),
        backgroundColor: Colors.green[600],
        duration: Duration(seconds: 2),
      ),
    );
  }
}