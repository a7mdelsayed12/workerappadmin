import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/database_service.dart';
import '../../../models/user_model.dart';

class UsersManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('إدارة المستخدمين'),
          backgroundColor: Colors.orange[600],
          bottom: TabBar(
            tabs: [
              Tab(text: 'طلبات التسجيل (${db.pendingUsers.length})'),
              Tab(text: 'المستخدمين المعتمدين (${db.approvedUsers.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(db.pendingUsers, true, context),
            _buildList(db.approvedUsers, false, context),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<User> users, bool pending, BuildContext context) {
    if (users.isEmpty) {
      return Center(child: Text('لا توجد بيانات'));
    }
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (_, i) {
        final user = users[i];
        return ListTile(
          title: Text(user.name),
          subtitle: Text('${user.role} - ${user.email}'), // استخدام role و email بدلاً من department
          trailing: pending
              ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.check, color: Colors.green),
                onPressed: () =>
                    Provider.of<DatabaseService>(context, listen: false)
                        .approveUser(user.id),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.red),
                onPressed: () =>
                    Provider.of<DatabaseService>(context, listen: false)
                        .rejectUser(user.id),
              ),
            ],
          )
              : null,
        );
      },
    );
  }
}