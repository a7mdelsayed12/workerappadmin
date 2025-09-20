import 'package:flutter/material.dart';

// دوال مساعدة للتطبيق
class AppHelpers {

  // تنسيق التاريخ
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // تنسيق التاريخ والوقت
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // تنسيق الأرقام مع فواصل
  static String formatNumber(double number) {
    return number.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  // عرض رسالة نجاح
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // عرض رسالة خطأ
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // عرض رسالة تحذير
  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // حوار التأكيد
  static Future<bool?> showConfirmDialog(
      BuildContext context,
      String title,
      String content,
      ) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          actions: [
            TextButton(
              child: Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: Text('تأكيد'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  // التحقق من المخزون المنخفض
  static bool isLowStock(int current, int initial) {
    return current <= (initial * 0.2);
  }

  // إنشاء ID فريد
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // تحويل حالة النص
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}