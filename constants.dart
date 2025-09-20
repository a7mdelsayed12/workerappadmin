// utils/constants.dart
class AppConstants {
  // Admin credentials
  static const String adminEmployeeId = 'ADMIN001';
  static const String adminPassword = 'admin123';

  // حالات الطلبات
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusCompleted = 'completed';
  static const String statusInProgress = 'in_progress';
  static const String statusCancelled = 'cancelled';

  // أنواع المستخدمين
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';
  static const String roleSupervisor = 'supervisor';
  static const String roleWorker = 'worker';
  static const String rolePlumber = 'plumber';
  static const String roleElectrician = 'electrician';
  static const String roleWarehouseKeeper = 'warehouse_keeper';

  // وحدات القياس للمستودع
  static const List<String> unitOfMeasures = [
    'قطعة',
    'متر',
    'كيلو',
    'لتر',
    'طن',
    'مربع',
    'مكعب',
    'عبوة',
    'صندوق',
    'كيس',
    'علبة',
    'زجاجة',
    'بكرة',
    'لفة',
    'حزمة'
  ];

  // أنواع المعدات والأصول
  static const List<String> vehicleTypes = [
    'car',
    'truck',
    'van',
    'motorcycle',
    'bus',
    'pickup',
    'crane',
    'forklift',
    'excavator',
    'bulldozer'
  ];

  // الوقود
  static const List<String> fuelTypes = [
    'gasoline',
    'diesel',
    'electric',
    'hybrid',
    'lpg',
    'cng'
  ];

  // ألوان المركبات
  static const List<String> vehicleColors = [
    'أبيض',
    'أسود',
    'رمادي',
    'أزرق',
    'أحمر',
    'أخضر',
    'فضي',
    'ذهبي',
    'بني',
    'أصفر'
  ];

  // الماركات
  static const List<String> vehicleBrands = [
    'Toyota',
    'Honda',
    'Ford',
    'Chevrolet',
    'Nissan',
    'Hyundai',
    'Kia',
    'Mercedes-Benz',
    'BMW',
    'Audi',
    'Volkswagen',
    'Mitsubishi',
    'Mazda',
    'Suzuki',
    'Isuzu',
    'Volvo',
    'Scania',
    'MAN',
    'Iveco',
    'DAF'
  ];

  // الأقسام
  static const List<String> departments = [
    'الصيانة',
    'الهندسة',
    'العمليات',
    'الأمن',
    'الإدارة',
    'المشتريات',
    'المالية',
    'الموارد البشرية',
    'تكنولوجيا المعلومات',
    'الجودة'
  ];

  // أنواع الصيانة
  static const List<String> maintenanceTypes = [
    'صيانة دورية',
    'صيانة طارئة',
    'إصلاح عطل',
    'تغيير زيت',
    'فحص عام',
    'إصلاح محرك',
    'إصلاح فرامل',
    'إصلاح إطارات',
    'إصلاح كهرباء',
    'إصلاح تكييف'
  ];

  // أولويات الطلبات
  static const List<String> priorities = [
    'عالية',
    'متوسطة',
    'منخفضة',
    'عاجلة'
  ];

  // دوال مساعدة للترجمة
  static String getArabicRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'مدير النظام';
      case 'manager':
        return 'مدير';
      case 'supervisor':
        return 'مشرف';
      case 'worker':
        return 'عامل';
      case 'plumber':
        return 'سباك';
      case 'electrician':
        return 'كهربائي';
      case 'warehouse_keeper':
        return 'أمين مستودع';
      default:
        return role;
    }
  }

  static String getArabicStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'في الانتظار';
      case 'approved':
        return 'موافق عليه';
      case 'rejected':
        return 'مرفوض';
      case 'completed':
        return 'مكتمل';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }
}