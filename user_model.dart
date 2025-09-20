// models/user_model.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String employeeId; // الرقم الوظيفي
  final String name;
  final String email;
  final String phone;
  final String nationality;
  final String profession; // المهنة
  final String role;
  final String password;
  final String status;
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final Map<String, Map<String, bool>>? permissions;

  User({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.phone,
    required this.nationality,
    required this.profession,
    required this.role,
    required this.password,
    this.status = 'pending',
    this.createdAt,
    this.approvedAt,
    this.approvedBy,
    this.permissions,
  });

  // Convert to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'name': name,
      'email': email,
      'phone': phone,
      'nationality': nationality,
      'profession': profession,
      'role': role,
      'password': password,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : Timestamp.now(),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'permissions': permissions,
    };
  }

  // Create from Firestore
  factory User.fromFirestore(Map<String, dynamic> data, String documentId) {
    return User(
      id: documentId,
      employeeId: data['employeeId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      nationality: data['nationality'] ?? '',
      profession: data['profession'] ?? '',
      role: data['role'] ?? '',
      password: data['password'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      approvedBy: data['approvedBy'],
      permissions: data['permissions'] != null
          ? Map<String, Map<String, bool>>.from(
        data['permissions'].map((key, value) => MapEntry(
          key,
          Map<String, bool>.from(value ?? {}),
        )),
      )
          : null,
    );
  }

  // Convert to Map (للاستخدام المحلي)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'name': name,
      'email': email,
      'phone': phone,
      'nationality': nationality,
      'profession': profession,
      'role': role,
      'password': password,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'approvedBy': approvedBy,
      'permissions': permissions,
    };
  }

  // Create from Map (للاستخدام المحلي)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      nationality: json['nationality'] ?? '',
      profession: json['profession'] ?? '',
      role: json['role'] ?? '',
      password: json['password'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
      approvedBy: json['approvedBy'],
      permissions: json['permissions'] != null
          ? Map<String, Map<String, bool>>.from(
        json['permissions'].map((key, value) => MapEntry(
          key,
          Map<String, bool>.from(value ?? {}),
        )),
      )
          : null,
    );
  }

  User copyWith({
    String? id,
    String? employeeId,
    String? name,
    String? email,
    String? phone,
    String? nationality,
    String? profession,
    String? role,
    String? password,
    String? status,
    DateTime? createdAt,
    DateTime? approvedAt,
    String? approvedBy,
    Map<String, Map<String, bool>>? permissions,
  }) {
    return User(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      nationality: nationality ?? this.nationality,
      profession: profession ?? this.profession,
      role: role ?? this.role,
      password: password ?? this.password,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      permissions: permissions ?? this.permissions,
    );
  }

  // Helper method للحصول على الوظيفة باللغة العربية
  String get jobTitle {
    switch (role.toLowerCase()) {
      case 'worker':
        return 'عامل';
      case 'plumber':
        return 'سباك';
      case 'electrician':
        return 'كهربائي';
      case 'manager':
        return 'مدير';
      case 'supervisor':
        return 'مشرف';
      case 'warehouse_keeper':
        return 'أمين مستودع';
      case 'admin':
        return 'مدير النظام';
      case 'technician':
        return 'فني';
      case 'engineer':
        return 'مهندس';
      default:
        return role;
    }
  }

  // Helper method للحصول على لون الحالة
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
      case 'مقبول':
        return Colors.green;
      case 'rejected':
      case 'مرفوض':
        return Colors.red;
      case 'pending':
      case 'منتظر':
        return Colors.orange;
      case 'inactive':
      case 'غير نشط':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  // Helper method للحصول على النص العربي للحالة
  String get statusArabic {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        return 'نشط';
      case 'rejected':
        return 'مرفوض';
      case 'pending':
        return 'منتظر الموافقة';
      case 'inactive':
        return 'غير نشط';
      default:
        return status;
    }
  }

  // Helper method للحصول على الجنسية العربية
  String get nationalityArabic {
    switch (nationality.toLowerCase()) {
      case 'saudi':
      case 'sa':
        return 'سعودي';
      case 'egyptian':
      case 'eg':
        return 'مصري';
      case 'pakistani':
      case 'pk':
        return 'باكستاني';
      case 'indian':
      case 'in':
        return 'هندي';
      case 'bangladeshi':
      case 'bd':
        return 'بنغلاديشي';
      case 'filipino':
      case 'ph':
        return 'فلبيني';
      case 'sri_lankan':
      case 'lk':
        return 'سريلانكي';
      case 'nepalese':
      case 'np':
        return 'نيبالي';
      case 'yemeni':
      case 'ye':
        return 'يمني';
      case 'sudanese':
      case 'sd':
        return 'سوداني';
      default:
        return nationality;
    }
  }

  // Helper method للحصول على أيقونة المهنة
  IconData get professionIcon {
    switch (profession.toLowerCase()) {
      case 'plumber':
      case 'سباك':
        return Icons.plumbing;
      case 'electrician':
      case 'كهربائي':
        return Icons.electrical_services;
      case 'carpenter':
      case 'نجار':
        return Icons.carpenter;
      case 'painter':
      case 'دهان':
        return Icons.format_paint;
      case 'cleaner':
      case 'عامل نظافة':
        return Icons.cleaning_services;
      case 'security':
      case 'أمن':
        return Icons.security;
      case 'driver':
      case 'سائق':
        return Icons.local_shipping;
      case 'mechanic':
      case 'ميكانيكي':
        return Icons.build;
      case 'technician':
      case 'فني':
        return Icons.engineering;
      case 'manager':
      case 'مدير':
        return Icons.manage_accounts;
      default:
        return Icons.work;
    }
  }

  // Helper method للتحقق من الصلاحيات
  bool hasPermission(String module, String action) {
    if (permissions == null) return false;
    return permissions![module]?[action] ?? false;
  }

  // Helper method للحصول على نص تاريخ الإنشاء
  String get createdAtFormatted {
    if (createdAt == null) return 'غير محدد';
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }

  // Helper method للحصول على نص تاريخ الموافقة
  String get approvedAtFormatted {
    if (approvedAt == null) return 'لم تتم الموافقة بعد';
    return '${approvedAt!.day}/${approvedAt!.month}/${approvedAt!.year}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, employeeId: $employeeId, name: $name, role: $role, status: $status)';
  }
}