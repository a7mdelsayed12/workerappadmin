import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService extends ChangeNotifier {
  late DatabaseService _dbService;
  bool _isLoading = false;
  User? _currentUser;

  AuthService(DatabaseService db) {
    _dbService = db;
    _loadRememberedUser();
  }

  void updateDatabaseService(DatabaseService db) {
    _dbService = db;
  }

  bool get isLoading => _isLoading;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'Admin' || _currentUser?.id == AppConstants.adminEmployeeId;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  /// تحميل بيانات المستخدم المحفوظة
  Future<void> _loadRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool('rememberMe') ?? false;

    if (remembered) {
      final employeeId = prefs.getString('employeeId');
      final password = prefs.getString('password');

      if (employeeId != null && password != null) {
        // محاولة تسجيل الدخول تلقائياً
        await login(employeeId, password);
      }
    }
  }

  Future<bool> login(String id, String pass) async {
    _setLoading(true);
    try {
      // تسجيل الدخول كأدمن
      if (id == AppConstants.adminEmployeeId && pass == AppConstants.adminPassword) {
        _currentUser = User(
          id: AppConstants.adminEmployeeId,
          employeeId: AppConstants.adminEmployeeId, // أضف هذا
          name: 'Administrator',
          email: 'admin@system.com',
          phone: '0000000000', // أضف هذا
          nationality: 'saudi', // أضف هذا
          profession: 'admin', // أضف هذا
          role: 'Admin',
          password: AppConstants.adminPassword,
          status: 'approved',
        );

        // حفظ بيانات تسجيل الدخول
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('employeeId', id);
        await prefs.setString('password', pass);
        await prefs.setBool('rememberMe', true);

        notifyListeners();
        return true;
      }

      // تسجيل الدخول كمستخدم عادي
      final user = await _dbService.getUserById(id);
      if (user == null || user.password != pass) {
        return false;
      }

      _currentUser = user;

      // حفظ بيانات تسجيل الدخول
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('employeeId', id);
      await prefs.setString('password', pass);
      await prefs.setBool('rememberMe', true);

      notifyListeners();
      return true;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final hist = prefs.getStringList('loginHistory') ?? [];
    final entry = '${prefs.getString('employeeId')}:${prefs.getString('password')}';

    if (prefs.getBool('rememberMe') == true && !hist.contains(entry)) {
      hist.add(entry);
      await prefs.setStringList('loginHistory', hist);
    }

    await prefs.remove('employeeId');
    await prefs.remove('password');
    await prefs.setBool('rememberMe', false);
  }

  /// تسجيل مستخدم جديد
  Future<bool> register(User newUser) async {
    _setLoading(true);
    try {
      // التحقق من عدم وجود مستخدم بنفس الرقم الوظيفي
      final existingUser = await _dbService.getUserById(newUser.id);
      if (existingUser != null) {
        return false; // المستخدم موجود بالفعل
      }

      // إضافة المستخدم إلى قائمة المستخدمين المعلقين
      await _dbService.addPendingUser(newUser);
      return true;
    } finally {
      _setLoading(false);
    }
  }

  /// تغيير كلمة المرور
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null || _currentUser!.password != currentPassword) {
      return false;
    }

    // تحديث كلمة المرور في الذاكرة
    _currentUser = _currentUser!.copyWith(password: newPassword);

    // حفظ كلمة المرور الجديدة
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password', newPassword);

    notifyListeners();
    return true;
  }

  /// التحقق من صلاحية المستخدم
  bool hasPermission(String requiredRole) {
    if (_currentUser == null) return false;
    return _currentUser!.role == requiredRole || _currentUser!.role == 'Admin';
  }

  /// الحصول على تاريخ تسجيلات الدخول السابقة
  Future<List<String>> getLoginHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('loginHistory') ?? [];
  }

  /// مسح تاريخ تسجيلات الدخول
  Future<void> clearLoginHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loginHistory');
    notifyListeners();
  }
}