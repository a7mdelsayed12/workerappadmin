// models/permission_request_model.dart
enum PermissionRequestStatus { pending, approved, rejected }

class PermissionRequest {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userRole;
  final Map<String, Map<String, bool>> requestedPermissions;
  final String reason;
  final DateTime requestDate;
  final PermissionRequestStatus status;
  final String? processedBy;
  final DateTime? processDate;
  final String? rejectionReason;

  PermissionRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.requestedPermissions,
    required this.reason,
    required this.requestDate,
    required this.status,
    this.processedBy,
    this.processDate,
    this.rejectionReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userRole': userRole,
      'requestedPermissions': requestedPermissions,
      'reason': reason,
      'requestDate': requestDate.toIso8601String(),
      'status': status.toString(),
      'processedBy': processedBy,
      'processDate': processDate?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  factory PermissionRequest.fromJson(Map<String, dynamic> json) {
    return PermissionRequest(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      userEmail: json['userEmail'],
      userRole: json['userRole'],
      requestedPermissions: Map<String, Map<String, bool>>.from(
        json['requestedPermissions'].map((key, value) =>
            MapEntry(key, Map<String, bool>.from(value))),
      ),
      reason: json['reason'],
      requestDate: DateTime.parse(json['requestDate']),
      status: PermissionRequestStatus.values
          .firstWhere((e) => e.toString() == json['status']),
      processedBy: json['processedBy'],
      processDate: json['processDate'] != null
          ? DateTime.parse(json['processDate'])
          : null,
      rejectionReason: json['rejectionReason'],
    );
  }
}

// models/user_permissions_model.dart
class UserPermissions {
  final String userId;
  final String userName;
  final String userEmail;
  final String userRole;
  final Map<String, Map<String, bool>> permissions;
  final DateTime lastUpdated;
  final String updatedBy;
  final bool isActive;

  UserPermissions({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.permissions,
    required this.lastUpdated,
    required this.updatedBy,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userRole': userRole,
      'permissions': permissions,
      'lastUpdated': lastUpdated.toIso8601String(),
      'updatedBy': updatedBy,
      'isActive': isActive,
    };
  }

  factory UserPermissions.fromJson(Map<String, dynamic> json) {
    return UserPermissions(
      userId: json['userId'],
      userName: json['userName'],
      userEmail: json['userEmail'],
      userRole: json['userRole'],
      permissions: Map<String, Map<String, bool>>.from(
        json['permissions'].map((key, value) =>
            MapEntry(key, Map<String, bool>.from(value))),
      ),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      updatedBy: json['updatedBy'],
      isActive: json['isActive'] ?? true,
    );
  }
}

// services/permission_service.dart
class PermissionService {
  // موافقة الأدمن على طلب الصلاحيات
  Future<bool> approvePermissionRequest({
    required String requestId,
    required String adminId,
    String? additionalNotes,
  }) async {
    try {
      // 1. جلب بيانات الطلب
      PermissionRequest? request = await getPermissionRequestById(requestId);
      if (request == null) return false;

      // 2. تحديث حالة الطلب إلى مُوافق عليه
      PermissionRequest updatedRequest = PermissionRequest(
        id: request.id,
        userId: request.userId,
        userName: request.userName,
        userEmail: request.userEmail,
        userRole: request.userRole,
        requestedPermissions: request.requestedPermissions,
        reason: request.reason,
        requestDate: request.requestDate,
        status: PermissionRequestStatus.approved,
        processedBy: adminId,
        processDate: DateTime.now(),
        rejectionReason: null,
      );

      // 3. حفظ الطلب المُحدث
      await updatePermissionRequest(updatedRequest);

      // 4. إنشاء أو تحديث صلاحيات المستخدم
      await createOrUpdateUserPermissions(
        userId: request.userId,
        userName: request.userName,
        userEmail: request.userEmail,
        userRole: request.userRole,
        permissions: request.requestedPermissions,
        updatedBy: adminId,
      );

      // 5. إرسال إشعار للمستخدم
      await sendNotificationToUser(
        userId: request.userId,
        title: 'تم الموافقة على طلب الصلاحيات',
        message: 'تم الموافقة على طلب الصلاحيات الخاص بك. يمكنك الآن الوصول للميزات الجديدة.',
      );

      return true;
    } catch (e) {
      print('خطأ في الموافقة على الطلب: $e');
      return false;
    }
  }

  // إنشاء أو تحديث صلاحيات المستخدم
  Future<bool> createOrUpdateUserPermissions({
    required String userId,
    required String userName,
    required String userEmail,
    required String userRole,
    required Map<String, Map<String, bool>> permissions,
    required String updatedBy,
  }) async {
    try {
      // التحقق من وجود صلاحيات سابقة للمستخدم
      UserPermissions? existingPermissions = await getUserPermissions(userId);

      if (existingPermissions != null) {
        // دمج الصلاحيات الجديدة مع الموجودة
        Map<String, Map<String, bool>> mergedPermissions = Map.from(existingPermissions.permissions);

        permissions.forEach((module, modulePermissions) {
          if (mergedPermissions.containsKey(module)) {
            mergedPermissions[module]!.addAll(modulePermissions);
          } else {
            mergedPermissions[module] = modulePermissions;
          }
        });

        UserPermissions updatedPermissions = UserPermissions(
          userId: userId,
          userName: userName,
          userEmail: userEmail,
          userRole: userRole,
          permissions: mergedPermissions,
          lastUpdated: DateTime.now(),
          updatedBy: updatedBy,
          isActive: true,
        );

        return await updateUserPermissions(updatedPermissions);
      } else {
        // إنشاء صلاحيات جديدة
        UserPermissions newPermissions = UserPermissions(
          userId: userId,
          userName: userName,
          userEmail: userEmail,
          userRole: userRole,
          permissions: permissions,
          lastUpdated: DateTime.now(),
          updatedBy: updatedBy,
          isActive: true,
        );

        return await createUserPermissions(newPermissions);
      }
    } catch (e) {
      print('خطأ في إنشاء/تحديث الصلاحيات: $e');
      return false;
    }
  }

  // جلب صلاحيات المستخدم للعرض في التطبيق
  Future<UserPermissions?> getUserPermissionsForApp(String userId) async {
    try {
      UserPermissions? permissions = await getUserPermissions(userId);

      if (permissions != null && permissions.isActive) {
        return permissions;
      }

      return null;
    } catch (e) {
      print('خطأ في جلب صلاحيات المستخدم: $e');
      return null;
    }
  }

  // التحقق من صلاحية معينة للمستخدم
  Future<bool> hasPermission({
    required String userId,
    required String module,
    required String permission,
  }) async {
    try {
      UserPermissions? userPermissions = await getUserPermissionsForApp(userId);

      if (userPermissions == null) return false;

      return userPermissions.permissions[module]?[permission] ?? false;
    } catch (e) {
      print('خطأ في التحقق من الصلاحية: $e');
      return false;
    }
  }

  // جلب جميع المستخدمين مع صلاحياتهم (للأدمن)
  Future<List<UserPermissions>> getAllUsersPermissions() async {
    try {
      // هنا تستدعي API أو قاعدة البيانات لجلب جميع الصلاحيات
      return await fetchAllUsersPermissions();
    } catch (e) {
      print('خطأ في جلب صلاحيات جميع المستخدمين: $e');
      return [];
    }
  }

  // Methods التي تحتاج تنفيذها حسب قاعدة البيانات المستخدمة
  Future<PermissionRequest?> getPermissionRequestById(String requestId) async {
    // تنفيذ جلب الطلب من قاعدة البيانات
    throw UnimplementedError();
  }

  Future<bool> updatePermissionRequest(PermissionRequest request) async {
    // تنفيذ تحديث الطلب في قاعدة البيانات
    throw UnimplementedError();
  }

  Future<UserPermissions?> getUserPermissions(String userId) async {
    // تنفيذ جلب صلاحيات المستخدم من قاعدة البيانات
    throw UnimplementedError();
  }

  Future<bool> createUserPermissions(UserPermissions permissions) async {
    // تنفيذ إنشاء صلاحيات جديدة في قاعدة البيانات
    throw UnimplementedError();
  }

  Future<bool> updateUserPermissions(UserPermissions permissions) async {
    // تنفيذ تحديث الصلاحيات في قاعدة البيانات
    throw UnimplementedError();
  }

  Future<List<UserPermissions>> fetchAllUsersPermissions() async {
    // تنفيذ جلب جميع صلاحيات المستخدمين من قاعدة البيانات
    throw UnimplementedError();
  }

  Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
  }) async {
    // تنفيذ إرسال الإشعار للمستخدم
    throw UnimplementedError();
  }
}