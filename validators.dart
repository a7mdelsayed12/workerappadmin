// دوال التحقق من صحة البيانات
class AppValidators {

  // التحقق من الرقم الوظيفي
  static String? validateEmployeeId(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال الرقم الوظيفي';  
    }
    if (value.length < 4) {
      return 'الرقم الوظيفي يجب أن يكون 4 أرقام على الأقل';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'الرقم الوظيفي يجب أن يحتوي على أرقام فقط';
    }
    return null;
  }

  // التحقق من الاسم
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال الاسم';
    }
    if (value.length < 3) {
      return 'الاسم يجب أن يكون 3 أحرف على الأقل';
    }
    if (value.length > 50) {
      return 'الاسم يجب أن يكون أقل من 50 حرف';
    }
    return null;
  }

  // التحقق من كلمة المرور
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال كلمة المرور';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  // التحقق من اسم القطعة
  static String? validateItemName(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال اسم القطعة';
    }
    if (value.length < 2) {
      return 'اسم القطعة يجب أن يكون حرفين على الأقل';
    }
    return null;
  }

  // التحقق من الكمية
  static String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال الكمية';
    }

    final quantity = int.tryParse(value);
    if (quantity == null) {
      return 'يرجى إدخال رقم صحيح';
    }

    if (quantity <= 0) {
      return 'الكمية يجب أن تكون أكبر من صفر';
    }

    if (quantity > 999999) {
      return 'الكمية كبيرة جداً';
    }

    return null;
  }

  // التحقق من السعر
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال السعر';
    }

    final price = double.tryParse(value);
    if (price == null) {
      return 'يرجى إدخال سعر صحيح';
    }

    if (price < 0) {
      return 'السعر لا يمكن أن يكون سالب';
    }

    if (price > 999999) {
      return 'السعر كبير جداً';
    }

    return null;
  }

  // التحقق من الوصف
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return null; // الوصف اختياري
    }
    if (value.length > 500) {
      return 'الوصف يجب أن يكون أقل من 500 حرف';
    }
    return null;
  }

  // التحقق من رقم لوحة السيارة
  static String? validatePlateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال رقم اللوحة';
    }
    if (value.length < 3) {
      return 'رقم اللوحة قصير جداً';
    }
    if (value.length > 10) {
      return 'رقم اللوحة طويل جداً';
    }
    return null;
  }

  // التحقق من سنة السيارة
  static String? validateCarYear(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال سنة السيارة';
    }

    final year = int.tryParse(value);
    if (year == null) {
      return 'يرجى إدخال سنة صحيحة';
    }

    final currentYear = DateTime.now().year;
    if (year < 1990 || year > currentYear + 1) {
      return 'سنة السيارة غير صحيحة';
    }

    return null;
  }

  // التحقق من اختيار القائمة المنسدلة
  static String? validateDropdown(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'يرجى اختيار $fieldName';
    }
    return null;
  }
}