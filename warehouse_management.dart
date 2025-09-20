import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/database_service.dart';
import 'warehouse_management_screen.dart';

class WarehouseManagement extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('إدارة المستودع'),
        backgroundColor: Colors.green[600],
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green[50]!,
              Colors.blue[50]!,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // أيقونة المستودع مع تأثير
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.green[200]!,
                              Colors.green[100]!,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green[200]!.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(16),
                        child: Icon(
                          Icons.inventory_2,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(height: 16),

                      // العنوان
                      Text(
                        'إدارة المستودع والمواد',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 8),

                      // عداد العناصر
                      Text(
                        'إجمالي العناصر المسجلة: ${db.warehouseItems.length}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      // عداد المخزون المنخفض
                      if (db.lowStockItems.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(top: 8),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red[300]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning, size: 16, color: Colors.red[700]),
                              SizedBox(width: 4),
                              Text(
                                'تحذير: ${db.lowStockItems.length} عنصر بمخزون منخفض',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                      SizedBox(height: 32),


                      SizedBox(height: 16),

                      // زر عرض المواد والصرف فقط
                      _buildButton(
                        context: context,
                        text: 'عرض المواد والصرف فقط',
                        description: 'عرض، بحث، تصدير بدون تعديل',
                        icon: Icons.visibility,
                        color: Colors.green[600]!,
                        onPressed: db.warehouseItems.isEmpty ? null : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => WarehouseViewOnlyScreen()),
                          );
                        },
                      ),

                      SizedBox(height: 24),

                      // إحصائيات سريعة
                      if (db.warehouseItems.isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildQuickStat(
                                'إجمالي العناصر',
                                '${db.warehouseItems.length}',
                                Icons.inventory,
                                Colors.blue,
                              ),
                              _buildQuickStat(
                                'مخزون منخفض',
                                '${db.lowStockItems.length}',
                                Icons.warning,
                                Colors.red,
                              ),
                              _buildQuickStat(
                                'طلبات معلقة',
                                '${db.pendingDispatchRequests.length}',
                                Icons.pending_actions,
                                Colors.orange,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // دالة بناء الأزرار
  Widget _buildButton({
    required BuildContext context,
    required String text,
    required String description,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: onPressed != null
            ? [
          BoxShadow(
            color: color.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ]
            : [],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? color : Colors.grey[400],
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 70),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: onPressed != null ? 4 : 0,
        ),
        onPressed: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String title, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            height: 1.2,
          ),
        ),
      ],
    );
  }
}