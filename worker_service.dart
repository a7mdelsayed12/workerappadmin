import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth;

class WorkerService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth.FirebaseAuth _auth = FirebaseAuth.FirebaseAuth.instance;

  // استدعاء طلبات التسجيل المعلقة
  Stream<QuerySnapshot> getPendingRegistrationRequestsStream() {
    return _db
        .collection('registration_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // الموافقة على طلب العامل مع إضافة صلاحيات افتراضية
  Future<void> approveWorkerRequest(String requestId, Map<String, dynamic> requestData) async {
    try {
      // إنشاء صلاحيات افتراضية حسب نوع الوظيفة
      Map<String, Map<String, bool>> defaultPermissions = _getDefaultPermissionsByJobType(
          requestData['job_type'] ?? 'عامل'
      );

      // إضافة المستخدم إلى users collection مع الصلاحيات
      await _db.collection('users').add({
        'uid': requestData['userId'],
        'employee_id': requestData['employee_id'] ?? requestData['employeeId'] ?? '',
        'name': requestData['name'],
        'email': requestData['email'],
        'phone': requestData['phone'],
        'job_type': requestData['job_type'] ?? 'عامل',
        'nationality': requestData['nationality'] ?? '',
        'password': requestData['password'] ?? '123456', // افتراضي إذا لم توجد
        'userType': 'worker',
        'role': 'worker',
        'status': 'approved',
        'permissions': defaultPermissions, // إضافة الصلاحيات الافتراضية
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': _auth.currentUser?.uid ?? 'admin',
      });

      // تحديث حالة الطلب في registration_requests
      await _db.collection('registration_requests').doc(requestId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': _auth.currentUser?.uid ?? 'admin',
      });

      print('تم قبول الطلب وإضافة المستخدم مع صلاحيات افتراضية');
      notifyListeners();
    } catch (e) {
      print('خطأ في قبول الطلب: $e');
      rethrow;
    }
  }

  // رفض طلب العامل
  Future<void> rejectWorkerRequest(String requestId, String userId, String reason) async {
    try {
      await _db.collection('registration_requests').doc(requestId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': _auth.currentUser?.uid ?? 'admin',
        'rejectionReason': reason,
      });

      print('تم رفض الطلب: $reason');
      notifyListeners();
    } catch (e) {
      print('خطأ في رفض الطلب: $e');
      rethrow;
    }
  }

  // إنشاء مستخدم جديد برمجياً
  Future<String> createWorkerProgrammatically({
    required String employeeId,
    required String email,
    required String name,
    required String password,
    required String phone,
    String jobType = 'عامل',
    String nationality = '',
    Map<String, Map<String, bool>>? customPermissions,
  }) async {
    try {
      // التحقق من عدم وجود المستخدم مسبقاً
      final existingUser = await _checkExistingUser(email, employeeId);
      if (existingUser != null) {
        throw Exception('المستخدم موجود بالفعل: $email');
      }

      // الصلاحيات (مخصصة أو افتراضية)
      final permissions = customPermissions ?? _getDefaultPermissionsByJobType(jobType);

      // بيانات المستخدم
      final userData = {
        'employee_id': employeeId,
        'employeeId': employeeId, // للتوافق مع الأنظمة القديمة
        'email': email,
        'name': name,
        'password': password,
        'phone': phone,
        'job_type': jobType,
        'nationality': nationality,
        'status': 'approved',
        'role': 'worker',
        'userType': 'worker',
        'permissions': permissions,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid ?? 'admin',
      };

      // إضافة المستخدم
      final docRef = await _db.collection('users').add(userData);

      print('تم إنشاء المستخدم برمجياً: ${docRef.id}');
      notifyListeners();
      return docRef.id;

    } catch (e) {
      print('خطأ في إنشاء المستخدم: $e');
      rethrow;
    }
  }

  // نقل المستخدمين المعتمدين من registration_requests إلى users
  Future<void> migrateApprovedUsers() async {
    try {
      final approvedRequests = await _db
          .collection('registration_requests')
          .where('status', isEqualTo: 'approved')
          .get();

      int migratedCount = 0;

      for (final doc in approvedRequests.docs) {
        final data = doc.data();

        // التحقق من عدم وجود المستخدم في users collection
        final existingInUsers = await _db
            .collection('users')
            .where('email', isEqualTo: data['email'])
            .limit(1)
            .get();

        if (existingInUsers.docs.isEmpty) {
          await createWorkerProgrammatically(
            employeeId: data['employee_id'] ?? data['employeeId'] ?? '',
            email: data['email'] ?? '',
            name: data['name'] ?? '',
            password: data['password'] ?? '123456',
            phone: data['phone'] ?? '',
            jobType: data['job_type'] ?? 'عامل',
            nationality: data['nationality'] ?? '',
          );

          migratedCount++;
          print('تم نقل المستخدم: ${data['name']}');
        }
      }

      print('تم نقل $migratedCount مستخدم من registration_requests إلى users');
      notifyListeners();
    } catch (e) {
      print('خطأ في نقل المستخدمين: $e');
      rethrow;
    }
  }

  // التحقق من وجود مستخدم موجود
  Future<DocumentSnapshot?> _checkExistingUser(String email, String employeeId) async {
    try {
      // البحث بالإيميل
      final emailQuery = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        return emailQuery.docs.first;
      }

      // البحث بالرقم الوظيفي
      final employeeIdQuery = await _db
          .collection('users')
          .where('employee_id', isEqualTo: employeeId)
          .limit(1)
          .get();

      if (employeeIdQuery.docs.isNotEmpty) {
        return employeeIdQuery.docs.first;
      }

      return null;
    } catch (e) {
      print('خطأ في البحث عن المستخدم: $e');
      return null;
    }
  }

  // الحصول على صلاحيات افتراضية حسب نوع الوظيفة
  Map<String, Map<String, bool>> _getDefaultPermissionsByJobType(String jobType) {
    switch (jobType) {
      case 'مدير منطقة':
      case 'مدير مشروع':
        return {
          'warehouse': {
            'view': true,
            'export': true,
            'import': false,
            'add': true,
            'edit': true,
            'delete': false,
            'approve_requests': true,
            'send_requests': true,
            'share_excel': true,
            'share_pdf': true,
            'share_text': false,
          },
          'assets': {
            'view': true,
            'export': true,
            'import': false,
            'add': true,
            'edit': true,
            'delete': false,
            'share_excel': true,
            'share_pdf': true,
            'share_text': false,
          },
          'users': {
            'view': true,
            'add': false,
            'edit': false,
            'delete': false,
            'approve': false,
            'manage_permissions': false,
          },
          'maintenance': {
            'view': true,
            'add': true,
            'edit': true,
            'delete': false,
            'schedule': true,
          },
          'reports': {
            'view': true,
            'generate': true,
            'export': true,
            'schedule': false,
            'share_excel': true,
            'share_pdf': true,
            'share_text': false,
          },
        };

      case 'مهندس':
        return {
          'warehouse': {
            'view': true,
            'export': false,
            'import': false,
            'add': false,
            'edit': false,
            'delete': false,
            'approve_requests': false,
            'send_requests': true,
            'share_excel': false,
            'share_pdf': false,
            'share_text': false,
          },
          'assets': {
            'view': true,
            'export': false,
            'import': false,
            'add': false,
            'edit': true,
            'delete': false,
            'share_excel': false,
            'share_pdf': false,
            'share_text': false,
          },
          'maintenance': {
            'view': true,
            'add': true,
            'edit': true,
            'delete': false,
            'schedule': true,
          },
          'reports': {
            'view': true,
            'generate': false,
            'export': false,
            'schedule': false,
            'share_excel': false,
            'share_pdf': false,
            'share_text': false,
          },
        };

      case 'أمين المستودع':
        return {
          'warehouse': {
            'view': true,
            'export': true,
            'import': true,
            'add': true,
            'edit': true,
            'delete': false,
            'approve_requests': true,
            'send_requests': true,
            'share_excel': true,
            'share_pdf': true,
            'share_text': true,
          },
          'assets': {
            'view': true,
            'export': false,
            'import': false,
            'add': false,
            'edit': false,
            'delete': false,
            'share_excel': false,
            'share_pdf': false,
            'share_text': false,
          },
          'reports': {
            'view': true,
            'generate': true,
            'export': true,
            'schedule': false,
            'share_excel': true,
            'share_pdf': true,
            'share_text': false,
          },
        };

      case 'محاسب':
        return {
          'warehouse': {
            'view': true,
            'export': true,
            'import': false,
            'add': false,
            'edit': false,
            'delete': false,
            'approve_requests': false,
            'send_requests': false,
            'share_excel': true,
            'share_pdf': true,
            'share_text': false,
          },
          'assets': {
            'view': true,
            'export': true,
            'import': false,
            'add': false,
            'edit': false,
            'delete': false,
            'share_excel': true,
            'share_pdf': true,
            'share_text': false,
          },
          'reports': {
            'view': true,
            'generate': true,
            'export': true,
            'schedule': false,
            'share_excel': true,
            'share_pdf': true,
            'share_text': false,
          },
        };

      case 'مشتريات':
        return {
          'warehouse': {
            'view': true,
            'export': true,
            'import': true,
            'add': true,
            'edit': false,
            'delete': false,
            'approve_requests': false,
            'send_requests': true,
            'share_excel': true,
            'share_pdf': false,
            'share_text': false,
          },
          'assets': {
            'view': true,
            'export': false,
            'import': false,
            'add': false,
            'edit': false,
            'delete': false,
            'share_excel': false,
            'share_pdf': false,
            'share_text': false,
          },
          'reports': {
            'view': true,
            'generate': false,
            'export': true,
            'schedule': false,
            'share_excel': true,
            'share_pdf': false,
            'share_text': false,
          },
        };

      case 'مشرف':
      case 'مراقب':
        return {
          'warehouse': {
            'view': true,
            'export': false,
            'import': false,
            'add': false,
            'edit': false,
            'delete': false,
            'approve_requests': true,
            'send_requests': true,
            'share_excel': false,
            'share_pdf': false,
            'share_text': false,
          },
          'assets': {
            'view': true,
            'export': false,
            'import': false,
            'add': false,
            'edit': false,
            'delete': false,
            'share_excel': false,
            'share_pdf': false,
            'share_text': false,
          },
          'maintenance': {
            'view': true,
            'add': false,
            'edit': false,
            'delete': false,
            'schedule': false,
          },
          'reports': {
            'view': true,
            'generate': false,
            'export': false,
            'schedule': false,
            'share_excel': false,
            'share_pdf': false,
            'share_text': false,
          },
        };

      case 'ميكانيكي':
      case 'سباك':
        return {
          'warehouse': {
            'view': true,
            'export': false,
            'import': false,
            'add': false,
            'edit': false,
            'delete': false,
            'approve_requests': false,
            'send_requests': true,
            'share_excel': false,
            'share_pdf': false,
            'share_text': false,
          },
          'assets': {
            'view': true,
            'export': false,
            'import': false,
            'add': false,
            'edit': false,
            'delete': false,
            'share_excel': false,
            'share_pdf': false,
            'share_text': false,
          },
          'maintenance': {
            'view': true,
            'add': true,
            'edit': true,
            'delete': false,
            'schedule': false,
          },
        };

    // افتراضي للعامل العادي
      default:
        return {
          'warehouse': {
            'view': true,
            'export': false,
            'import': false,
            'add': false,
            'edit': false,
            'delete': false,
            'approve_requests': false,
            'send_requests': true,
            'share_excel': false,
            'share_pdf': false,
            'share_text': false,
          },
          'assets': {
            'view': true,
            'export': false,
            'import': false,
            'add': false,
            'edit': false,
            'delete': false,
            'share_excel': false,
            'share_pdf': false,
            'share_text': false,
          },
          'reports': {
            'view': false,
            'generate': false,
            'export': false,
            'schedule': false,
            'share_excel': false,
            'share_pdf': false,
            'share_text': false,
          },
        };
    }
  }

  // دوال مساعدة إضافية

  // إنشاء Ahmed Elsayed برمجياً (للاختبار)
  Future<void> createAhmedElsayed() async {
    await createWorkerProgrammatically(
      employeeId: '21832',
      email: 'a7medelsayed12@gmail.com',
      name: 'Ahmed Elsayed',
      password: '111111',
      phone: '0558281650',
      jobType: 'مدير مشروع',
      nationality: 'مصري',
    );
  }

  // إنشاء عدة مستخدمين للاختبار
  Future<void> createSampleUsers() async {
    final sampleUsers = [
      {
        'employeeId': '21833',
        'email': 'manager@example.com',
        'name': 'محمد أحمد',
        'password': '123456',
        'phone': '0501234567',
        'jobType': 'مدير منطقة',
        'nationality': 'سعودي',
      },
      {
        'employeeId': '21834',
        'email': 'engineer@example.com',
        'name': 'خالد الفهد',
        'password': '123456',
        'phone': '0507654321',
        'jobType': 'مهندس',
        'nationality': 'سعودي',
      },
      {
        'employeeId': '21835',
        'email': 'warehouse@example.com',
        'name': 'عبدالله السالم',
        'password': '123456',
        'phone': '0509876543',
        'jobType': 'أمين المستودع',
        'nationality': 'سعودي',
      },
    ];

    for (final user in sampleUsers) {
      try {
        await createWorkerProgrammatically(
          employeeId: user['employeeId']!,
          email: user['email']!,
          name: user['name']!,
          password: user['password']!,
          phone: user['phone']!,
          jobType: user['jobType']!,
          nationality: user['nationality']!,
        );

        print('تم إنشاء المستخدم: ${user['name']}');

        // انتظار قصير بين كل مستخدم
        await Future.delayed(Duration(milliseconds: 500));
      } catch (e) {
        print('فشل في إنشاء المستخدم ${user['name']}: $e');
      }
    }
  }
}