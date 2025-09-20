// lib/screens/admin/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import 'assets/assets_management.dart';
import 'permissions/permissions_management_screen.dart';
import '../../utils/constants.dart';
import 'users/users_management_screen.dart';
import 'warehouse/warehouse_management.dart';
import 'warehouse/warehouse_management_screen.dart';



class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة تحكم الأدمن'),
        centerTitle: true,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            // شاشة إدارة المستخدمين الشاملة (الثلاث وظائف في واحدة)
            _buildCard(
              icon: Icons.people,
              label: 'إدارة المستخدمين',
              badgeCount: databaseService.pendingUsers.length,
              color: Colors.blue[600],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserManagementScreen()),
              ),
            ),

            // إضافة كارد إدارة الصلاحيات الجديد
            _buildCard(
              icon: Icons.security,
              label: 'إدارة الصلاحيات',
              badgeCount: 0, // يمكن إضافة عدد المستخدمين النشطين
              color: Colors.orange[600],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PermissionsManagementScreen()),
              ),
            ),

            _buildCard(
              icon: Icons.inventory_2,
              label: 'إدارة المستودع',
              badgeCount: databaseService.warehouseItems.length,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WarehouseManagement())
                ,
              ),
            ),

            _buildCard(
              icon: Icons.directions_car,
              label: 'إدارة السيارات',
              badgeCount: databaseService.assets.length,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CarsManagement()),
              ),
            ),

            _buildCard(
              icon: Icons.request_page,
              label: 'طلبات الصرف',
              badgeCount: databaseService.dispatchRequests
                  .where((r) => r.status == AppConstants.statusPending)
                  .length,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WarehouseViewOnlyScreen()),

              ),
            ),


            _buildCard(
              icon: Icons.build,
              label: 'سجلات الصيانة',
              badgeCount: 0,
              color: Colors.purple[600],
              onTap: () {
                // يمكن إضافة شاشة سجلات الصيانة لاحقاً
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('سيتم إضافة هذه الميزة قريباً')),
                );
              },
            ),

            _buildCard(
              icon: Icons.analytics,
              label: 'التقارير',
              badgeCount: 0,
              color: Colors.green[600],
              onTap: () {
                // يمكن إضافة شاشة التقارير لاحقاً
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('سيتم إضافة هذه الميزة قريباً')),
                );
              },
            ),

            _buildCard(
              icon: Icons.settings,
              label: 'الإعدادات',
              badgeCount: 0,
              color: Colors.grey[600],
              onTap: () {
                // يمكن إضافة شاشة الإعدادات لاحقاً
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('سيتم إضافة هذه الميزة قريباً')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String label,
    required int badgeCount,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: color ?? Colors.blue[600]),
                  SizedBox(height: 12),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.red,
                  child: Text(
                    '$badgeCount',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}