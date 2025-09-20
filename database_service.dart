import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../models/user_model.dart';
import '../models/warehouse_item.dart';
import '../models/dispatch_request.dart';
import '../../../models/asset.dart';
import '../models/repair_record.dart';
import '../models/request.dart';
import '../pigeon/pigeon.dart'; // المسار الصحيح
import '../models/maintenance_request.dart';



// إضافة Extension لتسهيل firstWhereOrNull
extension FirstWhereOrNullExtension<E> on List<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class DatabaseService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Keys لتخزين البيانات في SharedPreferences
  static const _warehouseItemsKey = 'stored_warehouse_items';
  static const _dispatchRequestsKey = 'stored_dispatch_requests';
  static const _repairRecordsKey = 'stored_repair_records';
  static const _requestsKey = 'stored_requests';

  // ============================
  // المتغيرات الداخلية
  // ============================
  List<Asset> _assets = [];
  List<WarehouseItem> _warehouseItems = [];
  List<User> _users = [];
  List<User> _pendingUsers = [];
  List<User> _approvedUsers = [];
  List<DispatchRequest> _dispatchRequests = [];
  List<RepairRecord> _repairRecords = [];
  List<Request> _requests = [];

  // ============================
  // Getters للبيانات
  // ============================
  List<User> get users => [..._pendingUsers, ..._approvedUsers];
  List<User> get pendingUsers => List.unmodifiable(_pendingUsers);
  List<User> get approvedUsers => List.unmodifiable(_approvedUsers);
  List<WarehouseItem> get warehouseItems => List.unmodifiable(_warehouseItems);
  List<DispatchRequest> get dispatchRequests => List.unmodifiable(_dispatchRequests);
  List<Asset> get assets => List.unmodifiable(_assets);
  List<RepairRecord> get repairRecords => List.unmodifiable(_repairRecords);
  List<Request> get requests => List.unmodifiable(_requests);
  List<MaintenanceRequest> get maintenanceRequests => List.unmodifiable(_maintenanceRequests);


  List<WarehouseItem> get lowStockItems =>
      _warehouseItems.where((item) => item.quantity <= 5).toList();

  List<DispatchRequest> get pendingDispatchRequests =>
      _dispatchRequests.where((r) => r.status == AppConstants.statusPending).toList();

  List<MaintenanceRequest> _maintenanceRequests = [];
  static const _maintenanceRequestsKey = 'stored_maintenance_requests';

  // ============================
  // دوال التحويل من موديل لـ Pigeon
  // ============================
  PigeonAsset toPigeonAsset(Asset asset) {
    return PigeonAsset()
      ..id = asset.id
      ..assetNumber = asset.assetNumber
      ..nameEn = asset.nameEn
      ..nameAr = asset.nameAr
      ..projectNumber = asset.projectNumber
      ..equipmentId = asset.equipmentId
      ..employeeName = asset.employeeName
      ..employeeId = asset.employeeId;
  }

  PigeonWarehouseItem toPigeonWarehouseItem(WarehouseItem item) {
    return PigeonWarehouseItem()
      ..id = item.itemCode
      ..itemCode = item.itemCode
      ..itemName = item.itemName
      ..projectCode = item.projectCode
      ..uom = item.uom
      ..quantity = item.quantity
      ..unitCost = item.unitCost
      ..value = item.value;
  }

  // ============================
  // دوال Pigeon HostApi
  // ============================
  List<PigeonAsset> getAllAssetsForPigeon() {
    return _assets.map(toPigeonAsset).toList();
  }

  PigeonAsset? getAssetByIdForPigeon(String id) {
    final asset = _assets.firstWhereOrNull((a) => a.id == id);
    return asset != null ? toPigeonAsset(asset) : null;
  }

  List<PigeonWarehouseItem> getAllItemsForPigeon() {
    return _warehouseItems.map(toPigeonWarehouseItem).toList();
  }

  PigeonWarehouseItem? getItemByIdForPigeon(String id) {
    final item = _warehouseItems.firstWhereOrNull((i) => i.itemCode == id);
    return item != null ? toPigeonWarehouseItem(item) : null;
  }

  List<PigeonUser> getAllUsersForPigeon() {
    return _users.map((u) => PigeonUser()
      ..id = u.id
      ..name = u.name
      ..email = u.email
      ..status = u.status
    ).toList();
  }

  void approveUserForPigeon(String id) {
    approveUser(id);
  }

  void rejectUserForPigeon(String id) {
    rejectUser(id);
  }

  // ============================
  // تهيئة البيانات
  // ============================
  Future<void> initialize() async {
    await loadAllData();
  }

  Future<void> loadAllData() async {
    try {
      await _loadWarehouseFromPrefs();
      await _loadDispatchRequestsFromPrefs();
      await _loadRepairRecordsFromPrefs();
      await _loadRequestsFromPrefs();
      await loadUsersFromFirebase();
      await loadAssetsFromFirebase();
      await _loadMaintenanceRequestsFromPrefs();

      notifyListeners();
    } catch (e) {
      print('خطأ في تحميل البيانات: $e');
    }
  }

  // دوال التحميل والحفظ:
  Future<void> _loadMaintenanceRequestsFromPrefs() async =>
      await _loadListFromPrefs(_maintenanceRequestsKey, _maintenanceRequests, (json) => MaintenanceRequest.fromJson(json));

// دوال إدارة طلبات الصيانة:
  Future<void> addMaintenanceRequest(MaintenanceRequest request) async {
    _maintenanceRequests.add(request);
    await _saveListToPrefs(_maintenanceRequestsKey, _maintenanceRequests);
    notifyListeners();
  }

  Future<void> updateMaintenanceRequest(String requestId, MaintenanceRequest updatedRequest) async {
    final index = _maintenanceRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _maintenanceRequests[index] = updatedRequest;
      await _saveListToPrefs(_maintenanceRequestsKey, _maintenanceRequests);
      notifyListeners();
    }
  }

// موافقة مسؤول الحركة
  Future<void> approveMaintenanceRequest(String requestId, String comment) async {
    final index = _maintenanceRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _maintenanceRequests[index] = _maintenanceRequests[index].copyWith(
        status: 'approved',
        approvedBy: 'اسم المدير',
      );
      await _saveListToPrefs(_maintenanceRequestsKey, _maintenanceRequests);
      notifyListeners();
    }
  }

// إنهاء الميكانيكي للطلب
  Future<void> completeMaintenanceRequest(String requestId, String comment) async {
    final index = _maintenanceRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _maintenanceRequests[index] = _maintenanceRequests[index].copyWith(
        status: 'completed',
        notes: comment,
        completedDate: DateTime.now(),
      );
      await _saveListToPrefs(_maintenanceRequestsKey, _maintenanceRequests);
      notifyListeners();
    }
  }

// دوال الفلترة
  List<MaintenanceRequest> get pendingMaintenanceRequests =>
      _maintenanceRequests.where((r) => r.status == 'pending').toList();

  List<MaintenanceRequest> get approvedMaintenanceRequests =>
      _maintenanceRequests.where((r) => r.status == 'approved').toList();

  List<MaintenanceRequest> get completedMaintenanceRequests =>
      _maintenanceRequests.where((r) => r.status == 'completed').toList();

  // ============================
  // Firebase: Users & Assets & Requests
  // ============================

  /// تحميل المستخدمين والطلبات من Firebase
  Future<void> loadUsersFromFirebase() async {
    try {
      _pendingUsers.clear();
      _approvedUsers.clear();

      print('جاري تحميل الطلبات من Firebase...');

      // 1. تحميل الطلبات من requests collection
      QuerySnapshot requestsSnapshot = await _firestore
          .collection('requests')
          .orderBy('requestDate', descending: true)
          .get();

      print('تم العثور على ${requestsSnapshot.docs.length} طلب');

      for (var doc in requestsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String status = data['status'] ?? 'pending';

        print('طلب: ${data['name']}, الحالة: $status');

        User user = User(
          id: doc.id,
          employeeId: data['employeeId'] ?? '',
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          nationality: data['nationality'] ?? '',
          profession: data['profession'] ?? '',
          role: data['role'] ?? '',
          password: '',
          status: status,
          createdAt: data['requestDate'] != null
              ? (data['requestDate'] as Timestamp).toDate()
              : DateTime.now(),
          approvedAt: data['approvalDate'] != null
              ? (data['approvalDate'] as Timestamp).toDate()
              : null,
          approvedBy: data['approvedBy'],
          permissions: null,
        );

        if (status == 'pending') {
          _pendingUsers.add(user);
        }
      }

      // 2. تحميل المستخدمين المعتمدين من users collection
      QuerySnapshot approvedSnapshot = await _firestore
          .collection('users')
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .get();

      for (var doc in approvedSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        _approvedUsers.add(User(
          id: doc.id,
          employeeId: data['employeeId'] ?? '',
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          nationality: data['nationality'] ?? '',
          profession: data['profession'] ?? '',
          role: data['role'] ?? '',
          password: '',
          status: 'approved',
          createdAt: data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
          approvedAt: data['approvedAt'] != null
              ? (data['approvedAt'] as Timestamp).toDate()
              : null,
          approvedBy: data['approvedBy'],
          permissions: data['permissions'] != null
              ? Map<String, Map<String, bool>>.from(data['permissions']
              .map((key, value) => MapEntry(key, Map<String, bool>.from(value))))
              : null,
        ));
      }

      _users.clear();
      _users.addAll([..._pendingUsers, ..._approvedUsers]);

      print('تم تحميل ${_pendingUsers.length} طلب منتظر و ${_approvedUsers.length} مستخدم مقبول');

    } catch (e) {
      print('خطأ في تحميل المستخدمين من Firebase: $e');
    }
  }

  Future<void> loadAssetsFromFirebase() async {
    try {
      _assets.clear();
      QuerySnapshot snapshot = await _firestore.collection('assets').orderBy('assetNumber').get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        _assets.add(Asset(
          id: doc.id,
          assetNumber: data['assetNumber'] ?? '',
          nameEn: data['nameEn'] ?? '',
          projectNumber: data['projectNumber'] ?? '',
          equipmentId: data['equipmentId'] ?? '',
          employeeName: data['employeeName'] ?? '',
          employeeId: data['employeeId'] ?? '',
          nameAr: data['nameAr'] ?? '',
        ));
      }

      print('تم تحميل ${_assets.length} أصل من Firebase');
    } catch (e) {
      print('خطأ في تحميل الأصول من Firebase: $e');
    }
  }

  // ============================
  // SharedPreferences: Load & Save
  // ============================
  Future<void> _loadWarehouseFromPrefs() async =>
      await _loadListFromPrefs(_warehouseItemsKey, _warehouseItems, (json) => WarehouseItem.fromJson(json));

  Future<void> _loadDispatchRequestsFromPrefs() async =>
      await _loadListFromPrefs(_dispatchRequestsKey, _dispatchRequests, (json) => DispatchRequest.fromJson(json));

  Future<void> _loadRepairRecordsFromPrefs() async =>
      await _loadListFromPrefs(_repairRecordsKey, _repairRecords, (json) => RepairRecord.fromJson(json));

  Future<void> _loadRequestsFromPrefs() async =>
      await _loadListFromPrefs(_requestsKey, _requests, (json) => Request.fromJson(json));

  Future<void> _loadListFromPrefs<T>(
      String key, List<T> list, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        list
          ..clear()
          ..addAll(jsonList.map((j) => fromJson(j as Map<String, dynamic>)));
      }
    } catch (e) {
      print('خطأ في تحميل $key: $e');
    }
  }

  Future<void> _saveListToPrefs<T>(String key, List<T> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(list.map((item) {
        if (item is WarehouseItem) return item.toJson();
        if (item is DispatchRequest) return item.toJson();
        if (item is RepairRecord) return item.toJson();
        if (item is Request) return item.toJson();
        if (item is MaintenanceRequest) return item.toJson();
        return {};
      }).toList());

      await prefs.setString(key, jsonString);
    } catch (e) {
      print('خطأ في حفظ $key: $e');
    }
  }

  // ========== إدارة المستخدمين والطلبات ==========

  /// الموافقة على طلب من requests collection ونقله إلى users
  Future<void> approveUser(String requestId) async {
    try {
      // 1. الحصول على بيانات الطلب
      DocumentSnapshot requestDoc = await _firestore
          .collection('requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('الطلب غير موجود');
      }

      Map<String, dynamic> requestData = requestDoc.data() as Map<String, dynamic>;

      // 2. إنشاء المستخدم في users collection
      await _firestore.collection('users').add({
        'employeeId': requestData['employeeId'] ?? '',
        'name': requestData['name'] ?? '',
        'email': requestData['email'] ?? '',
        'phone': requestData['phone'] ?? '',
        'nationality': requestData['nationality'] ?? '',
        'profession': requestData['profession'] ?? '',
        'role': requestData['role'] ?? '',
        'password': '',
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

      // 3. حذف الطلب من requests
      await _firestore.collection('requests').doc(requestId).delete();

      // 4. إعادة تحميل البيانات
      await loadUsersFromFirebase();

      print('تم قبول الطلب ونقل المستخدم إلى users');

    } catch (e) {
      print('خطأ في قبول المستخدم: $e');
      rethrow;
    }
  }

  /// رفض طلب من requests collection
  Future<void> rejectUser(String requestId) async {
    try {
      // حذف الطلب من requests
      await _firestore.collection('requests').doc(requestId).delete();

      // إعادة تحميل البيانات
      await loadUsersFromFirebase();

      print('تم رفض الطلب وحذفه');

    } catch (e) {
      print('خطأ في رفض المستخدم: $e');
      rethrow;
    }
  }

  Future<void> addUser(User user) async {
    await addPendingUser(user);
  }

  Future<void> addPendingUser(User u) async {
    try {
      await _firestore.collection('requests').add({
        'employeeId': u.employeeId,
        'name': u.name,
        'email': u.email,
        'phone': u.phone,
        'nationality': u.nationality,
        'profession': u.profession,
        'role': u.role,
        'status': 'pending',
        'requestDate': FieldValue.serverTimestamp(),
        'description': 'طلب تسجيل جديد',
      });

      await loadUsersFromFirebase();
    } catch (e) {
      print('خطأ في إضافة المستخدم: $e');
      rethrow;
    }
  }

  Future<void> updateUser(String userId, User updatedUser) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'name': updatedUser.name,
        'email': updatedUser.email,
        'role': updatedUser.role,
        'phone': updatedUser.phone,
        'nationality': updatedUser.nationality,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadUsersFromFirebase();
    } catch (e) {
      print('خطأ في تحديث المستخدم: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      await loadUsersFromFirebase();
    } catch (e) {
      print('خطأ في حذف المستخدم: $e');
      rethrow;
    }
  }

  // ========== إدارة عناصر المستودع (SharedPreferences) ==========
  Future<void> addWarehouseItem(WarehouseItem item) async {
    final existingIndex = _warehouseItems.indexWhere((i) => i.itemCode == item.itemCode);
    if (existingIndex != -1) {
      final existingItem = _warehouseItems[existingIndex];
      _warehouseItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + item.quantity,
        value: (existingItem.quantity + item.quantity) * item.unitCost,
      );
    } else {
      _warehouseItems.add(item);
    }

    await _saveListToPrefs(_warehouseItemsKey, _warehouseItems);
    notifyListeners();
  }

  Future<void> updateWarehouseItem(String itemCode, WarehouseItem updatedItem) async {
    final index = _warehouseItems.indexWhere((item) => item.itemCode == itemCode);
    if (index != -1) {
      _warehouseItems[index] = updatedItem;
      await _saveListToPrefs(_warehouseItemsKey, _warehouseItems);
      notifyListeners();
    }
  }

  Future<void> deleteWarehouseItem(String itemCode) async {
    _warehouseItems.removeWhere((i) => i.itemCode == itemCode);
    await _saveListToPrefs(_warehouseItemsKey, _warehouseItems);
    notifyListeners();
  }

  Future<void> updateWarehouseItemQuantity(String itemCode, double newQuantity) async {
    final index = _warehouseItems.indexWhere((item) => item.itemCode == itemCode);
    if (index != -1) {
      final item = _warehouseItems[index];
      _warehouseItems[index] = item.copyWith(
        quantity: newQuantity,
        value: newQuantity * item.unitCost,
      );
      await _saveListToPrefs(_warehouseItemsKey, _warehouseItems);
      notifyListeners();
    }
  }

  // ========== إدارة طلبات التوزيع (SharedPreferences) ==========
  Future<void> addDispatchRequest(DispatchRequest r) async {
    _dispatchRequests.add(r);
    await _saveListToPrefs(_dispatchRequestsKey, _dispatchRequests);
    notifyListeners();
  }

  Future<void> approveDispatchRequest(String id, int quantity) async {
    final index = _dispatchRequests.indexWhere((req) => req.id == id);
    if (index != -1) {
      final request = _dispatchRequests[index];
      final item = await getWarehouseItemByCode(request.itemId);

      if (item != null && item.quantity >= quantity) {
        _dispatchRequests[index] = request.copyWith(
          status: AppConstants.statusApproved,
          approvedQuantity: quantity,
        );

        await updateWarehouseItemQuantity(request.itemId, item.quantity - quantity);
        await _saveListToPrefs(_dispatchRequestsKey, _dispatchRequests);
        notifyListeners();
      } else {
        throw Exception('الكمية المطلوبة غير متوفرة في المستودع');
      }
    }
  }

  Future<void> rejectDispatchRequest(String id, String reason) async {
    final index = _dispatchRequests.indexWhere((req) => req.id == id);
    if (index != -1) {
      _dispatchRequests[index] = _dispatchRequests[index].copyWith(
        status: AppConstants.statusRejected,
        rejectionReason: reason,
      );
      await _saveListToPrefs(_dispatchRequestsKey, _dispatchRequests);
      notifyListeners();
    }
  }

  // ========== إدارة الأصول (Firebase) ==========
  Future<void> addAsset(Asset v) async {
    try {
      await _firestore.collection('assets').doc(v.id).set({
        'assetNumber': v.assetNumber,
        'nameEn': v.nameEn,
        'projectNumber': v.projectNumber,
        'equipmentId': v.equipmentId,
        'employeeName': v.employeeName,
        'employeeId': v.employeeId,
        'nameAr': v.nameAr,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _assets.add(v);
      notifyListeners();
    } catch (e) {
      print('خطأ في إضافة الأصل: $e');
      rethrow;
    }
  }

  Future<void> addAssets(List<Asset> list) async {
    try {
      WriteBatch batch = _firestore.batch();

      for (Asset v in list) {
        DocumentReference docRef = _firestore.collection('assets').doc(v.id);
        batch.set(docRef, {
          'assetNumber': v.assetNumber,
          'nameEn': v.nameEn,
          'projectNumber': v.projectNumber,
          'equipmentId': v.equipmentId,
          'employeeName': v.employeeName,
          'employeeId': v.employeeId,
          'nameAr': v.nameAr,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      _assets.addAll(list);
      notifyListeners();
    } catch (e) {
      print('خطأ في إضافة الأصول: $e');
      rethrow;
    }
  }

  Future<void> updateAsset(String assetId, Asset updatedAsset) async {
    try {
      await _firestore.collection('assets').doc(assetId).update({
        'assetNumber': updatedAsset.assetNumber,
        'nameEn': updatedAsset.nameEn,
        'projectNumber': updatedAsset.projectNumber,
        'equipmentId': updatedAsset.equipmentId,
        'employeeName': updatedAsset.employeeName,
        'employeeId': updatedAsset.employeeId,
        'nameAr': updatedAsset.nameAr,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final index = _assets.indexWhere((v) => v.id == assetId);
      if (index != -1) {
        _assets[index] = updatedAsset;
        notifyListeners();
      }
    } catch (e) {
      print('خطأ في تحديث الأصل: $e');
      rethrow;
    }
  }

  Future<void> removeAsset(String id) async {
    try {
      await _firestore.collection('assets').doc(id).delete();
      _assets.removeWhere((v) => v.id == id);
      notifyListeners();
    } catch (e) {
      print('خطأ في حذف الأصل: $e');
      rethrow;
    }
  }

  // ========== إدارة سجلات الصيانة ==========
  Future<void> addRepairRecord(RepairRecord record) async {
    _repairRecords.add(record);
    await _saveListToPrefs(_repairRecordsKey, _repairRecords);
    notifyListeners();
  }

  Future<void> updateRepairRecord(String recordId, RepairRecord updatedRecord) async {
    final index = _repairRecords.indexWhere((r) => r.id == recordId);
    if (index != -1) {
      _repairRecords[index] = updatedRecord;
      await _saveListToPrefs(_repairRecordsKey, _repairRecords);
      notifyListeners();
    }
  }

  List<RepairRecord> getRepairRecordsByAsset(String assetId) {
    return _repairRecords.where((r) => r.assetId == assetId).toList();
  }

  // ========== إدارة الطلبات العامة ==========
  Future<void> addRequest(Request request) async {
    _requests.add(request);
    await _saveListToPrefs(_requestsKey, _requests);
    notifyListeners();
  }

  Future<void> updateRequest(String requestId, Request updatedRequest) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index] = updatedRequest;
      await _saveListToPrefs(_requestsKey, _requests);
      notifyListeners();
    }
  }

  // ========== دوال مساعدة ==========
  Future<User?> getUserById(String id) async {
    try {
      return users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Asset?> getAssetById(String id) async {
    try {
      return _assets.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<WarehouseItem?> getWarehouseItemByCode(String itemCode) async {
    try {
      return _warehouseItems.firstWhere((item) => item.itemCode == itemCode);
    } catch (_) {
      return null;
    }
  }

  Future<DispatchRequest?> getDispatchRequestById(String id) async {
    try {
      return _dispatchRequests.firstWhere((req) => req.id == id);
    } catch (_) {
      return null;
    }
  }

  // ========== البحث والفلترة ==========
  List<WarehouseItem> searchWarehouseItems(String query) {
    if (query.isEmpty) return _warehouseItems;

    final lowercaseQuery = query.toLowerCase();
    return _warehouseItems.where((item) =>
    item.itemCode.toLowerCase().contains(lowercaseQuery) ||
        item.itemName.toLowerCase().contains(lowercaseQuery) ||
        item.itemNameAr.toLowerCase().contains(lowercaseQuery) ||
        item.projectCode.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  List<Asset> searchAssets(String query) {
    if (query.isEmpty) return _assets;

    final lowerQuery = query.toLowerCase();
    return _assets.where((asset) =>
    asset.assetNumber.toLowerCase().contains(lowerQuery) ||
        asset.nameEn.toLowerCase().contains(lowerQuery) ||
        asset.nameAr.toLowerCase().contains(lowerQuery) ||
        asset.employeeName.toLowerCase().contains(lowerQuery) ||
        asset.employeeId.toLowerCase().contains(lowerQuery) ||
        asset.projectNumber.toLowerCase().contains(lowerQuery) ||
        asset.equipmentId.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  List<WarehouseItem> getLowStockItems([double threshold = 5.0]) {
    return _warehouseItems.where((item) => item.quantity <= threshold).toList();
  }

  // ========== إدارة الصلاحيات ==========
  Future<void> updateUserPermissions(
      String userId,
      Map<String, Map<String, bool>> permissions
      ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'permissions': permissions,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final index = _approvedUsers.indexWhere((user) => user.id == userId);
      if (index != -1) {
        _approvedUsers[index] = _approvedUsers[index].copyWith(permissions: permissions);
        notifyListeners();
      }

    } catch (e) {
      print('خطأ في تحديث الصلاحيات: $e');
      rethrow;
    }
  }

  Future<Map<String, Map<String, bool>>?> getUserPermissions(String userId) async {
    try {
      final user = users.firstWhere((u) => u.id == userId);
      return user.permissions;
    } catch (e) {
      return null;
    }
  }

  Future<bool> checkUserPermission(
      String userId,
      String category,
      String permission
      ) async {
    try {
      Map<String, Map<String, bool>>? permissions = await getUserPermissions(userId);

      if (permissions != null &&
          permissions.containsKey(category) &&
          permissions[category]!.containsKey(permission)) {
        return permissions[category]![permission] ?? false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // ========== إحصائيات عامة ==========
  Map<String, int> getStatistics() {
    return {
      'totalUsers': users.length,
      'pendingUsers': pendingUsers.length,
      'totalAssets': assets.length,
      'totalWarehouseItems': warehouseItems.length,
      'lowStockItems': lowStockItems.length,
      'pendingDispatchRequests': pendingDispatchRequests.length,
      'totalRepairRecords': repairRecords.length,
    };
  }

  // ========== تصدير واستيراد البيانات ==========
  Map<String, dynamic> exportData() {
    return {
      'warehouseItems': _warehouseItems.map((i) => i.toJson()).toList(),
      'dispatchRequests': _dispatchRequests.map((r) => r.toJson()).toList(),
      'repairRecords': _repairRecords.map((r) => r.toJson()).toList(),
      'requests': _requests.map((r) => r.toJson()).toList(),
      'maintenanceRequests': _maintenanceRequests.map((r) => r.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    try {
      if (data.containsKey('warehouseItems')) {
        final warehouseList = data['warehouseItems'] as List;
        _warehouseItems.clear();
        _warehouseItems.addAll(warehouseList.map((i) => WarehouseItem.fromJson(i)));
        await _saveListToPrefs(_warehouseItemsKey, _warehouseItems);
      }

      if (data.containsKey('dispatchRequests')) {
        final dispatchList = data['dispatchRequests'] as List;
        _dispatchRequests.clear();
        _dispatchRequests.addAll(dispatchList.map((r) => DispatchRequest.fromJson(r)));
        await _saveListToPrefs(_dispatchRequestsKey, _dispatchRequests);
      }

      if (data.containsKey('repairRecords')) {
        final repairList = data['repairRecords'] as List;
        _repairRecords.clear();
        _repairRecords.addAll(repairList.map((r) => RepairRecord.fromJson(r)));
        await _saveListToPrefs(_repairRecordsKey, _repairRecords);
      }

      if (data.containsKey('requests')) {
        final requestsList = data['requests'] as List;
        _requests.clear();
        _requests.addAll(requestsList.map((r) => Request.fromJson(r)));
        await _saveListToPrefs(_requestsKey, _requests);
      }
      if (data.containsKey('maintenanceRequests')) {
        final maintenanceList = data['maintenanceRequests'] as List;
        _maintenanceRequests.clear();
        _maintenanceRequests.addAll(maintenanceList.map((r) => MaintenanceRequest.fromJson(r)));
        await _saveListToPrefs(_maintenanceRequestsKey, _maintenanceRequests);
      }

      notifyListeners();
    } catch (e) {
      print('خطأ في استيراد البيانات: $e');
      throw Exception('فشل في استيراد البيانات: $e');
    }
  }

  /// إعادة تحميل البيانات من Firebase
  Future<void> refreshData() async {
    await loadUsersFromFirebase();
    await loadAssetsFromFirebase();
    notifyListeners();
  }

  /// مسح جميع البيانات (لأغراض التطوير)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    _pendingUsers.clear();
    _approvedUsers.clear();
    _warehouseItems.clear();
    _dispatchRequests.clear();
    _assets.clear();
    _repairRecords.clear();
    _requests.clear();
    _maintenanceRequests.clear();
    await prefs.remove(_warehouseItemsKey);
    await prefs.remove(_dispatchRequestsKey);
    await prefs.remove(_repairRecordsKey);
    await prefs.remove(_requestsKey);
    await prefs.remove(_maintenanceRequestsKey);

    notifyListeners();
  }

  /// فحص الاتصال بـ Firebase
  Future<bool> testFirebaseConnection() async {
    try {
      await _firestore.collection('requests').limit(1).get();
      print('الاتصال بـ Firebase يعمل بشكل صحيح');
      return true;
    } catch (e) {
      print('فشل الاتصال بـ Firebase: $e');
      return false;
    }
  }

  /// إضافة طلب تجريبي للاختبار
  Future<void> addTestRequest() async {
    try {
      await _firestore.collection('requests').add({
        'employeeId': 'TEST${DateTime.now().millisecondsSinceEpoch}',
        'name': 'مستخدم تجريبي ${DateTime.now().hour}:${DateTime.now().minute}',
        'email': 'test_${DateTime.now().millisecondsSinceEpoch}@example.com',
        'phone': '0501234567',
        'nationality': 'سعودي',
        'profession': 'مطور',
        'role': 'مطور',
        'status': 'pending',
        'requestDate': FieldValue.serverTimestamp(),
        'description': 'طلب تجريبي للاختبار',
      });

      await loadUsersFromFirebase();
      print('تم إضافة طلب تجريبي بنجاح');
    } catch (e) {
      print('خطأ في إضافة الطلب التجريبي: $e');
      rethrow;
    }
  }
}