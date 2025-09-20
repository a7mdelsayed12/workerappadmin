import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/database_service.dart';
import '../../../models/maintenance_request.dart';

class MaintenanceRequestsScreen extends StatefulWidget {
  final String userRole; // 'admin', 'purchasing', 'mechanic', 'worker'

  MaintenanceRequestsScreen({required this.userRole});

  @override
  _MaintenanceRequestsScreenState createState() => _MaintenanceRequestsScreenState();
}

class _MaintenanceRequestsScreenState extends State<MaintenanceRequestsScreen> {
  int _selectedTabIndex = 0;
  List<String> _tabs = [];

  @override
  void initState() {
    super.initState();
    _setupTabs();
  }

  void _setupTabs() {
    switch (widget.userRole) {
      case 'admin':
        _tabs = ['جميع الطلبات', 'في انتظار الموافقة', 'موافق عليها', 'جاري الإصلاح', 'مكتملة', 'مؤكدة'];
        break;
      case 'purchasing':
        _tabs = ['طلبات جديدة', 'موافق عليها', 'مرفوضة'];
        break;
      case 'mechanic':
        _tabs = ['مهامي', 'جاري العمل', 'مكتملة'];
        break;
      case 'worker':
        _tabs = ['طلباتي', 'جاري الإصلاح', 'للتأكيد', 'مؤكدة'];
        break;
      default:
        _tabs = ['جميع الطلبات'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('طلبات الصيانة - ${_getUserRoleText()}'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.userRole == 'worker' || widget.userRole == 'mechanic')
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => _showAddRequestDialog(),
              tooltip: 'طلب صيانة جديد',
            ),
          if (widget.userRole == 'admin')
            IconButton(
              icon: Icon(Icons.file_download),
              onPressed: () => _generateDailyReport(),
              tooltip: 'تحميل التقرير اليومي',
            ),
        ],
      ),
      body: Column(
        children: [
          // شريط التبويب
          Container(
            height: 50,
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tabs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final title = entry.value;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = index),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTabIndex == index ? Colors.orange[600]! : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: _selectedTabIndex == index ? Colors.orange[600] : Colors.grey[600],
                            fontWeight: _selectedTabIndex == index ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // المحتوى
          Expanded(
            child: Consumer<DatabaseService>(
              builder: (context, db, child) {
                final requests = _getFilteredRequests(db);

                if (requests.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    return _buildRequestCard(requests[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getUserRoleText() {
    switch (widget.userRole) {
      case 'admin': return 'الإدارة';
      case 'purchasing': return 'المشتريات';
      case 'mechanic': return 'الميكانيكي';
      case 'worker': return 'العامل';
      default: return 'المستخدم';
    }
  }

  List<MaintenanceRequest> _getFilteredRequests(DatabaseService db) {
    final allRequests = db.maintenanceRequests ?? [];

    switch (widget.userRole) {
      case 'admin':
        switch (_selectedTabIndex) {
          case 0: return allRequests;
          case 1: return allRequests.where((r) => r.status == 'pending').toList();
          case 2: return allRequests.where((r) => r.status == 'purchasing_approved').toList();
          case 3: return allRequests.where((r) => r.status == 'in_progress').toList();
          case 4: return allRequests.where((r) => r.status == 'completed').toList();
          case 5: return allRequests.where((r) => r.status == 'worker_confirmed').toList();
          default: return allRequests;
        }

      case 'purchasing':
        switch (_selectedTabIndex) {
          case 0: return allRequests.where((r) => r.status == 'pending').toList();
          case 1: return allRequests.where((r) => r.status == 'purchasing_approved').toList();
          case 2: return allRequests.where((r) => r.status == 'rejected').toList();
          default: return allRequests;
        }

      case 'mechanic':
        final userId = 'current_mechanic_id'; // يجب الحصول على ID المستخدم الحالي
        switch (_selectedTabIndex) {
          case 0: return allRequests.where((r) => r.status == 'purchasing_approved').toList();
          case 1: return allRequests.where((r) => r.assignedToId == userId && r.status == 'in_progress').toList();
          case 2: return allRequests.where((r) => r.assignedToId == userId && r.status == 'completed').toList();
          default: return allRequests;
        }

      case 'worker':
        final userId = 'current_worker_id'; // يجب الحصول على ID المستخدم الحالي
        switch (_selectedTabIndex) {
          case 0: return allRequests.where((r) => r.requestedById == userId).toList();
          case 1: return allRequests.where((r) => r.requestedById == userId && r.status == 'in_progress').toList();
          case 2: return allRequests.where((r) => r.requestedById == userId && r.status == 'completed').toList();
          case 3: return allRequests.where((r) => r.requestedById == userId && r.status == 'worker_confirmed').toList();
          default: return allRequests;
        }

      default:
        return allRequests;
    }
  }

  Widget _buildRequestCard(MaintenanceRequest request) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRequestDetails(request),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف الأول - رقم الأصل والحالة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.build_circle,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'رقم الأصل: ${request.assetNumber}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue[700],
                            ),
                          ),
                          Text(
                            'ID: ${request.id.substring(0, 8)}...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _buildStatusChip(request.status),
                ],
              ),

              SizedBox(height: 12),

              // معلومات الأصل
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (request.assetNameEn.isNotEmpty) ...[
                      _buildInfoRow('الوصف (EN):', request.assetNameEn),
                      SizedBox(height: 4),
                    ],
                    if (request.assetNameAr.isNotEmpty) ...[
                      _buildInfoRow('الوصف (AR):', request.assetNameAr),
                      SizedBox(height: 4),
                    ],
                    _buildInfoRow('رقم المشروع:', request.projectNumber),
                    SizedBox(height: 4),
                    _buildInfoRow('رقم المعدة:', request.equipmentId),
                  ],
                ),
              ),

              SizedBox(height: 12),

              // وصف المشكلة
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'وصف المشكلة:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.red[700],
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

              // معلومات إضافية
              if (request.assignedTo.isNotEmpty || request.totalCost > 0) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (request.assignedTo.isNotEmpty)
                        _buildInfoRow('مُعيّن لـ:', request.assignedTo),
                      if (request.totalCost > 0) ...[
                        SizedBox(height: 4),
                        _buildInfoRow('التكلفة:', '${request.totalCost} ريال'),
                      ],
                      if (request.partsUsed.isNotEmpty) ...[
                        SizedBox(height: 4),
                        _buildInfoRow('القطع المستخدمة:', request.partsUsed.join(', ')),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 12),
              ],

              // معلومات الطلب
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('طلب بواسطة:', request.requestedBy),
                        SizedBox(height: 4),
                        _buildInfoRow('الموظف:', '${request.employeeName} (${request.employeeId})'),
                        SizedBox(height: 4),
                        _buildInfoRow('تاريخ الطلب:', request.formattedRequestDate),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // الأزرار حسب الدور والحالة
              _buildActionButtons(request),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'في انتظار الموافقة';
        break;
      case 'purchasing_approved':
        color = Colors.blue;
        text = 'موافق عليه من المشتريات';
        break;
      case 'in_progress':
        color = Colors.purple;
        text = 'جاري الإصلاح';
        break;
      case 'completed':
        color = Colors.green;
        text = 'تم الإصلاح';
        break;
      case 'worker_confirmed':
        color = Colors.teal;
        text = 'مؤكد من العامل';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'مرفوض';
        break;
      default:
        color = Colors.grey;
        text = 'غير محدد';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : 'غير محدد',
            style: TextStyle(
              fontSize: 12,
              color: value.isNotEmpty ? Colors.black87 : Colors.grey[500],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(MaintenanceRequest request) {
    List<Widget> buttons = [];

    switch (widget.userRole) {
      case 'admin':
        if (request.status == 'pending') {
          buttons.addAll([
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _approveForPurchasing(request),
                icon: Icon(Icons.check, size: 16),
                label: Text('موافقة للمشتريات', style: TextStyle(fontSize: 10)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _rejectRequest(request),
                icon: Icon(Icons.close, size: 16),
                label: Text('رفض', style: TextStyle(fontSize: 10)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ]);
        }
        break;

      case 'purchasing':
        if (request.status == 'pending') {
          buttons.addAll([
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _purchasingApprove(request),
                icon: Icon(Icons.shopping_cart, size: 16),
                label: Text('موافقة المشتريات', style: TextStyle(fontSize: 10)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ]);
        }
        break;

      case 'mechanic':
        if (request.status == 'purchasing_approved') {
          buttons.add(
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _startRepair(request),
                icon: Icon(Icons.build, size: 16),
                label: Text('بدء الإصلاح', style: TextStyle(fontSize: 10)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          );
        } else if (request.status == 'in_progress') {
          buttons.add(
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _completeRepair(request),
                icon: Icon(Icons.done_all, size: 16),
                label: Text('إنهاء الإصلاح', style: TextStyle(fontSize: 10)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          );
        }
        break;

      case 'worker':
        if (request.status == 'completed') {
          buttons.addAll([
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _confirmRepair(request, true),
                icon: Icon(Icons.thumb_up, size: 16),
                label: Text('تأكيد الإصلاح', style: TextStyle(fontSize: 10)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _confirmRepair(request, false),
                icon: Icon(Icons.thumb_down, size: 16),
                label: Text('لم يتم الإصلاح', style: TextStyle(fontSize: 10)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ]);
        }
        break;
    }

    // زر التفاصيل دائماً موجود
    buttons.addAll([
      if (buttons.isNotEmpty) SizedBox(width: 8),
      ElevatedButton(
        onPressed: () => _showRequestDetails(request),
        child: Text('التفاصيل', style: TextStyle(fontSize: 10)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[600],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        ),
      ),
    ]);

    return Row(children: buttons);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_circle_outlined, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'لا توجد طلبات صيانة',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            'سيظهر هنا جميع طلبات الصيانة',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // دوال الإجراءات
  void _approveForPurchasing(MaintenanceRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('موافقة للمشتريات'),
        content: Text('هل تريد إرسال هذا الطلب إلى قسم المشتريات؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final db = Provider.of<DatabaseService>(context, listen: false);
              final updatedRequest = request.copyWith(
                status: 'purchasing_approved',
                approvedBy: 'اسم المدير', // يجب الحصول على اسم المستخدم الحالي
              );

              db.updateMaintenanceRequest(request.id, updatedRequest);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم إرسال الطلب إلى المشتريات'), backgroundColor: Colors.green),
              );
            },
            child: Text('موافقة'),
          ),
        ],
      ),
    );
  }

  void _purchasingApprove(MaintenanceRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('موافقة المشتريات'),
        content: Text('هل تمت موافقة المشتريات على هذا الطلب؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final db = Provider.of<DatabaseService>(context, listen: false);
              final updatedRequest = request.copyWith(
                status: 'purchasing_approved',
                purchasingApprovedBy: 'اسم موظف المشتريات',
              );

              db.updateMaintenanceRequest(request.id, updatedRequest);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تمت موافقة المشتريات'), backgroundColor: Colors.blue),
              );
            },
            child: Text('موافقة'),
          ),
        ],
      ),
    );
  }

  void _startRepair(MaintenanceRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('بدء الإصلاح'),
        content: Text('هل تريد بدء العمل على هذا الطلب؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final db = Provider.of<DatabaseService>(context, listen: false);
              final updatedRequest = request.copyWith(
                status: 'in_progress',
                assignedTo: 'اسم الميكانيكي الحالي',
                assignedToId: 'معرف الميكانيكي',
              );

              db.updateMaintenanceRequest(request.id, updatedRequest);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم بدء الإصلاح'), backgroundColor: Colors.purple),
              );
            },
            child: Text('بدء العمل'),
          ),
        ],
      ),
    );
  }

  void _completeRepair(MaintenanceRequest request) {
    final TextEditingController repairDetailsController = TextEditingController();
    final TextEditingController partsUsedController = TextEditingController();
    final TextEditingController costController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إنهاء الإصلاح'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: repairDetailsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'تفاصيل الإصلاح',
                  border: OutlineInputBorder(),
                  hintText: 'تم استبدال المحرك...',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: partsUsedController,
                decoration: InputDecoration(
                  labelText: 'القطع المستخدمة',
                  border: OutlineInputBorder(),
                  hintText: 'محرك, مسامير, زيت',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'التكلفة الإجمالية (ريال)',
                  border: OutlineInputBorder(),
                  hintText: '500',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (repairDetailsController.text.isNotEmpty) {
                final db = Provider.of<DatabaseService>(context, listen: false);
                final partsUsed = partsUsedController.text.split(',').map((e) => e.trim()).toList();
                final cost = double.tryParse(costController.text) ?? 0.0;

                final updatedRequest = request.copyWith(
                  status: 'completed',
                  completedDate: DateTime.now(),
                  repairDetails: repairDetailsController.text,
                  partsUsed: partsUsed,
                  totalCost: cost,
                );

                db.updateMaintenanceRequest(request.id, updatedRequest);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم إنهاء الإصلاح بنجاح'), backgroundColor: Colors.green),
                );
              }
            },
            child: Text('إنهاء الإصلاح'),
          ),
        ],
      ),
    );
  }

  void _confirmRepair(MaintenanceRequest request, bool isWorking) {
    final String statusText = isWorking ? 'تأكيد أن الإصلاح نجح' : 'الإبلاغ عن عدم نجاح الإصلاح';
    final String buttonText = isWorking ? 'تأكيد' : 'لم يتم الإصلاح';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(statusText),
        content: Text(isWorking
            ? 'هل تؤكد أن المشكلة تم حلها بنجاح؟'
            : 'هل تؤكد أن المشكلة لم يتم حلها؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final db = Provider.of<DatabaseService>(context, listen: false);
              final updatedRequest = request.copyWith(
                status: isWorking ? 'worker_confirmed' : 'in_progress',
                workerConfirmed: isWorking,
                workerConfirmedDate: isWorking ? DateTime.now() : null,
              );

              db.updateMaintenanceRequest(request.id, updatedRequest);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isWorking ? 'تم تأكيد نجاح الإصلاح' : 'تم الإبلاغ عن عدم نجاح الإصلاح'),
                  backgroundColor: isWorking ? Colors.green : Colors.orange,
                ),
              );
            },
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  void _rejectRequest(MaintenanceRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('رفض الطلب'),
        content: Text('هل أنت متأكد من رفض طلب الصيانة هذا؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final db = Provider.of<DatabaseService>(context, listen: false);
              final updatedRequest = request.copyWith(status: 'rejected');

              db.updateMaintenanceRequest(request.id, updatedRequest);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم رفض الطلب'), backgroundColor: Colors.red),
              );
            },
            child: Text('رفض'),
          ),
        ],
      ),
    );
  }

  void _showRequestDetails(MaintenanceRequest request) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تفاصيل طلب الصيانة',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  _buildDetailSection('معلومات الأصل', [
                    _buildDetailRow('رقم الأصل:', request.assetNumber),
                    _buildDetailRow('الوصف (EN):', request.assetNameEn),
                    _buildDetailRow('الوصف (AR):', request.assetNameAr),
                    _buildDetailRow('رقم المشروع:', request.projectNumber),
                    _buildDetailRow('رقم المعدة:', request.equipmentId),
                  ]),

                  _buildDetailSection('معلومات الطلب', [
                    _buildDetailRow('وصف المشكلة:', request.problemDescription),
                    _buildDetailRow('طلب بواسطة:', request.requestedBy),
                    _buildDetailRow('الموظف:', '${request.employeeName} (${request.employeeId})'),
                    _buildDetailRow('تاريخ الطلب:', request.formattedRequestDate),
                  ]),

                  if (request.approvedBy.isNotEmpty || request.purchasingApprovedBy.isNotEmpty)
                    _buildDetailSection('معلومات الموافقات', [
                      if (request.approvedBy.isNotEmpty)
                        _buildDetailRow('وافق عليه:', request.approvedBy),
                      if (request.purchasingApprovedBy.isNotEmpty)
                        _buildDetailRow('موافقة المشتريات:', request.purchasingApprovedBy),
                    ]),

                  if (request.assignedTo.isNotEmpty || request.repairDetails.isNotEmpty)
                    _buildDetailSection('معلومات الإصلاح', [
                      if (request.assignedTo.isNotEmpty)
                        _buildDetailRow('مُعيّن لـ:', request.assignedTo),
                      if (request.completedDate != null)
                        _buildDetailRow('تاريخ الإنجاز:', request.completedDate.toString().substring(0, 16)),
                      if (request.repairDetails.isNotEmpty)
                        _buildDetailRow('تفاصيل الإصلاح:', request.repairDetails),
                      if (request.partsUsed.isNotEmpty)
                        _buildDetailRow('القطع المستخدمة:', request.partsUsed.join(', ')),
                      if (request.totalCost > 0)
                        _buildDetailRow('التكلفة:', '${request.totalCost} ريال'),
                    ]),

                  if (request.workerConfirmed)
                    _buildDetailSection('معلومات التأكيد', [
                      _buildDetailRow('تأكيد العامل:', request.workerConfirmed ? 'تم التأكيد' : 'لم يتم التأكيد'),
                      if (request.workerConfirmedDate != null)
                        _buildDetailRow('تاريخ التأكيد:', request.workerConfirmedDate.toString().substring(0, 16)),
                    ]),

                  SizedBox(height: 16),

                  Center(child: _buildStatusChip(request.status)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue[700]),
          ),
          SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'غير محدد',
              style: TextStyle(fontSize: 13, color: value.isNotEmpty ? Colors.black87 : Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRequestDialog() {
    final TextEditingController assetNumberController = TextEditingController();
    final TextEditingController problemController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('طلب صيانة جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: assetNumberController,
                decoration: InputDecoration(
                  labelText: 'رقم الأصل',
                  border: OutlineInputBorder(),
                  hintText: 'أدخل رقم الأصل',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: problemController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'وصف المشكلة',
                  border: OutlineInputBorder(),
                  hintText: 'اشرح المشكلة بالتفصيل...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (assetNumberController.text.isNotEmpty && problemController.text.isNotEmpty) {
                final db = Provider.of<DatabaseService>(context, listen: false);
                final newRequest = MaintenanceRequest(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  assetId: assetNumberController.text,
                  assetNumber: assetNumberController.text,
                  assetNameEn: '',
                  projectNumber: '',
                  equipmentId: '',
                  employeeName: 'اسم المستخدم الحالي',
                  employeeId: 'معرف المستخدم',
                  assetNameAr: '',
                  problemDescription: problemController.text,
                  requestedBy: 'اسم المستخدم الحالي',
                  requestedById: 'معرف المستخدم',
                  status: 'pending',
                  requestDate: DateTime.now(),
                );

                db.addMaintenanceRequest(newRequest);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم إرسال طلب الصيانة بنجاح'), backgroundColor: Colors.green),
                );
              }
            },
            child: Text('إرسال الطلب'),
          ),
        ],
      ),
    );
  }

  void _generateDailyReport() {
    final DateTime today = DateTime.now();
    final db = Provider.of<DatabaseService>(context, listen: false);
    final allRequests = db.maintenanceRequests ?? [];

    final todayRequests = allRequests.where((request) {
      return request.requestDate.day == today.day &&
          request.requestDate.month == today.month &&
          request.requestDate.year == today.year;
    }).toList();

    final completedToday = allRequests.where((request) {
      return request.completedDate != null &&
          request.completedDate!.day == today.day &&
          request.completedDate!.month == today.month &&
          request.completedDate!.year == today.year;
    }).toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'التقرير اليومي',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),

                  Text(
                    'تاريخ: ${today.day}/${today.month}/${today.year}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),

                  SizedBox(height: 20),

                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard('طلبات جديدة', todayRequests.length.toString(), Colors.blue),
                            _buildStatCard('تم إنجازها', completedToday.length.toString(), Colors.green),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard('قيد التنفيذ', allRequests.where((r) => r.status == 'in_progress').length.toString(), Colors.orange),
                            _buildStatCard('مؤكدة', allRequests.where((r) => r.status == 'worker_confirmed').length.toString(), Colors.teal),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  if (completedToday.isNotEmpty) ...[
                    Text(
                      'الأعمال المكتملة اليوم:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    ...completedToday.map((request) => Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('أصل رقم: ${request.assetNumber}', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('المشكلة: ${request.problemDescription}'),
                            Text('الإصلاح: ${request.repairDetails}'),
                            if (request.partsUsed.isNotEmpty)
                              Text('القطع: ${request.partsUsed.join(', ')}'),
                            if (request.totalCost > 0)
                              Text('التكلفة: ${request.totalCost} ريال'),
                            Text('المُصلح: ${request.assignedTo}'),
                          ],
                        ),
                      ),
                    )).toList(),
                  ],

                  SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('سيتم إضافة وظيفة تحميل التقرير قريباً')),
                            );
                          },
                          icon: Icon(Icons.download),
                          label: Text('تحميل التقرير'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('سيتم إضافة وظيفة مشاركة التقرير قريباً')),
                            );
                          },
                          icon: Icon(Icons.share),
                          label: Text('مشاركة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}