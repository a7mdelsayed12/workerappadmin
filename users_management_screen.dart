import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: Icon(Icons.pending_actions),
              text: 'طلبات معلقة',
            ),
            Tab(icon: Icon(Icons.check_circle), text: 'مقبولين'),
            Tab(icon: Icon(Icons.cancel), text: 'مرفوضين'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingUsersTab(),
          _buildApprovedUsersTab(),
          _buildRejectedUsersTab(),
        ],
      ),
    );
  }

  // تبويب الطلبات المعلقة - من requests collection
  Widget _buildPendingUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests') // تغيير من users إلى requests
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا توجد طلبات معلقة',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final requestData = request.data() as Map<String, dynamic>;
            return _buildPendingRequestCard(request.id, requestData);
          },
        );
      },
    );
  }

  // تبويب المستخدمين المقبولين - من users collection
  Widget _buildApprovedUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs ?? [];

        if (users.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا يوجد مستخدمين مقبولين',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final userData = user.data() as Map<String, dynamic>;
            return _buildApprovedUserCard(user.id, userData);
          },
        );
      },
    );
  }

  // تبويب المستخدمين المرفوضين - من users collection (في حالة وجود مرفوضين محفوظين)
  Widget _buildRejectedUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('status', isEqualTo: 'rejected')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs ?? [];

        if (users.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا يوجد طلبات مرفوضة',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final userData = user.data() as Map<String, dynamic>;
            return _buildRejectedUserCard(user.id, userData);
          },
        );
      },
    );
  }

  // كارد الطلب المعلق (من requests collection)
  Widget _buildPendingRequestCard(String requestId, Map<String, dynamic> requestData) {
    final name = requestData['name'] ?? 'غير محدد';
    final email = requestData['email'] ?? 'غير محدد';
    final phone = requestData['phone'] ?? 'غير محدد';
    final profession = requestData['profession'] ?? requestData['role'] ?? 'غير محدد';
    final nationality = requestData['nationality'] ?? 'غير محدد';
    final employeeId = requestData['employeeId'] ?? 'غير محدد';
    final requestDate = requestData['requestDate'] as Timestamp?;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange[100],
                  child: Text(name[0], style: TextStyle(color: Colors.orange[700])),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('طلب جديد', style: TextStyle(color: Colors.orange[700], fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Details
            _buildDetailRow(Icons.badge, 'الرقم الوظيفي', employeeId),
            _buildDetailRow(Icons.email, 'البريد الإلكتروني', email),
            _buildDetailRow(Icons.phone, 'رقم الهاتف', phone),
            _buildDetailRow(Icons.work, 'المهنة', profession),
            _buildDetailRow(Icons.flag, 'الجنسية', nationality),
            if (requestDate != null)
              _buildDetailRow(Icons.schedule, 'تاريخ التقديم', _formatDate(requestDate.toDate())),

            SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveRequest(requestId, requestData),
                    icon: Icon(Icons.check),
                    label: Text('موافقة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectRequest(requestId, name),
                    icon: Icon(Icons.close),
                    label: Text('رفض'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedUserCard(String userId, Map<String, dynamic> userData) {
    final name = userData['name'] ?? 'غير محدد';
    final email = userData['email'] ?? 'غير محدد';
    final profession = userData['profession'] ?? userData['role'] ?? 'غير محدد';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green[100],
                  child: Text(name[0], style: TextStyle(color: Colors.green[700])),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('مقبول', style: TextStyle(color: Colors.green[700], fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editUser(userId, userData);
                    } else if (value == 'delete') {
                      _deleteUser(userId, name);
                    } else if (value == 'block') {
                      _blockUser(userId, name);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text('تعديل')])),
                    PopupMenuItem(value: 'block', child: Row(children: [Icon(Icons.block, color: Colors.orange), SizedBox(width: 8), Text('حظر')])),
                    PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('حذف')])),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildDetailRow(Icons.email, 'البريد الإلكتروني', email),
            _buildDetailRow(Icons.work, 'المسمى الوظيفي', profession),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedUserCard(String userId, Map<String, dynamic> userData) {
    final name = userData['name'] ?? 'غير محدد';
    final email = userData['email'] ?? 'غير محدد';
    final rejectionReason = userData['rejectionReason'] ?? 'غير محدد';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.red[100],
                  child: Text(name[0], style: TextStyle(color: Colors.red[700])),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('مرفوض', style: TextStyle(color: Colors.red[700], fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.restore, color: Colors.blue),
                  onPressed: () => _restoreUser(userId, name),
                  tooltip: 'استعادة المستخدم',
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildDetailRow(Icons.email, 'البريد الإلكتروني', email),
            _buildDetailRow(Icons.info, 'سبب الرفض', rejectionReason),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey[800]))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // موافقة على طلب - نقل من requests إلى users
  Future<void> _approveRequest(String requestId, Map<String, dynamic> requestData) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 1. إنشاء المستخدم في users collection
      await FirebaseFirestore.instance
          .collection('users')
          .add({
        'employeeId': requestData['employeeId'] ?? '',
        'name': requestData['name'] ?? '',
        'email': requestData['email'] ?? '',
        'phone': requestData['phone'] ?? '',
        'nationality': requestData['nationality'] ?? '',
        'profession': requestData['profession'] ?? requestData['role'] ?? '',
        'role': requestData['role'] ?? requestData['profession'] ?? '',
        'status': 'approved',
        'createdAt': requestData['requestDate'] ?? FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': 'Admin',
        'permissions': {
          'assets': {'view': false, 'edit': false},
          'warehouse': {'dispense': false, 'add': false, 'edit': false},
          'reports': {'view': false}
        },
      });

      // 2. حذف الطلب من requests collection
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .delete();

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم قبول ${requestData['name']} بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الموافقة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // رفض طلب - حذف من requests
  Future<void> _rejectRequest(String requestId, String name) async {
    final TextEditingController reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('رفض الطلب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('سبب رفض $name:'),
            SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'اكتب سبب الرفض...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('رفض', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // حذف الطلب من requests
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم رفض طلب $name'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الرفض: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editUser(String userId, Map<String, dynamic> userData) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('سيتم إضافة ميزة التعديل قريباً')),
    );
  }

  Future<void> _deleteUser(String userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف المستخدم'),
        content: Text('هل أنت متأكد من حذف $name؟\nهذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حذف $name'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الحذف: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _blockUser(String userId, String name) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'status': 'blocked',
        'blockedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حظر $name'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الحظر: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restoreUser(String userId, String name) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'status': 'approved',
        'restoredAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم استعادة $name'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الاستعادة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}