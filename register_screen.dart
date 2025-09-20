import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/constants.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String _selectedRole = '';
  String _selectedNationality = '';
  String _selectedProfession = '';
  bool _isLoading = false;

  final List<String> _roles = [
    'مدير منطقة',
    'مدير مشروع',
    'مهندس',
    'مراقب',
    'عامل',
    'فني',
    'سائق',
    'أمين مستودع',
  ];

  final List<String> _nationalities = [
    'سعودي',
    'مصري',
    'باكستاني',
    'هندي',
    'بنغلاديشي',
    'فلبيني',
    'سريلانكي',
    'نيبالي',
    'يمني',
    'سوداني',
    'أخرى',
  ];

  final List<String> _professions = [
    'سباك',
    'كهربائي',
    'نجار',
    'دهان',
    'عامل نظافة',
    'أمن',
    'سائق',
    'ميكانيكي',
    'فني',
    'مدير',
    'مهندس',
    'أخرى',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('طلب تسجيل جديد'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Icon(Icons.person_add, size: 60, color: Colors.blue[600]),
                  SizedBox(height: 16),
                  Text('طلب انضمام للنظام',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('سيتم مراجعة طلبك من قبل الأدمن',
                      style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 32),

                  // الرقم الوظيفي
                  TextFormField(
                    controller: _employeeIdController,
                    decoration: InputDecoration(
                      labelText: 'الرقم الوظيفي',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'يرجى إدخال الرقم الوظيفي';
                      if (v.length < 4) return 'يجب أن يكون 4 أرقام على الأقل';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // الاسم الكامل
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'الاسم الكامل',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'يرجى إدخال الاسم';
                      if (v.length < 3) return 'يجب أن يكون 3 أحرف على الأقل';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // البريد الإلكتروني
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                      if (!v.contains('@')) return 'بريد إلكتروني غير صحيح';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // رقم الهاتف
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف',
                      prefixIcon: Icon(Icons.phone),
                      hintText: '+966xxxxxxxxx',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'يرجى إدخال رقم الهاتف';
                      if (v.length < 10) return 'رقم هاتف غير صحيح';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // الجنسية
                  DropdownButtonFormField<String>(
                    value: _selectedNationality.isEmpty ? null : _selectedNationality,
                    decoration: InputDecoration(
                      labelText: 'الجنسية',
                      prefixIcon: Icon(Icons.flag),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: _nationalities
                        .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedNationality = v ?? ''),
                    validator: (v) => (v == null || v.isEmpty) ? 'يرجى اختيار الجنسية' : null,
                  ),
                  SizedBox(height: 16),

                  // المهنة
                  DropdownButtonFormField<String>(
                    value: _selectedProfession.isEmpty ? null : _selectedProfession,
                    decoration: InputDecoration(
                      labelText: 'المهنة',
                      prefixIcon: Icon(Icons.work),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: _professions
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedProfession = v ?? ''),
                    validator: (v) => (v == null || v.isEmpty) ? 'يرجى اختيار المهنة' : null,
                  ),
                  SizedBox(height: 16),

                  // المسمى الوظيفي
                  DropdownButtonFormField<String>(
                    value: _selectedRole.isEmpty ? null : _selectedRole,
                    decoration: InputDecoration(
                      labelText: 'المسمى الوظيفي',
                      prefixIcon: Icon(Icons.assignment_ind),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: _roles
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedRole = v ?? ''),
                    validator: (v) => (v == null || v.isEmpty) ? 'يرجى الاختيار' : null,
                  ),
                  SizedBox(height: 16),

                  // كلمة المرور
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'يرجى إدخال كلمة المرور';
                      if (v.length < 6) return 'يجب 6 أحرف على الأقل';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // تأكيد كلمة المرور
                  TextFormField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'يرجى التأكيد';
                      if (v != _passwordController.text) return 'غير متطابقة';
                      return null;
                    },
                  ),
                  SizedBox(height: 32),

                  // زر الإرسال
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('إرسال طلب التسجيل',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('لديك حساب؟ تسجيل دخول'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // إنشاء المستخدم الجديد مع كل الحقول المطلوبة
      final newUser = User(
        id: '', // سيتم إنشاء ID تلقائياً في Firebase
        employeeId: _employeeIdController.text.trim(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        nationality: _selectedNationality,
        profession: _selectedProfession,
        role: _selectedRole,
        password: _passwordController.text,
        status: 'pending', // حالة منتظر الموافقة
        createdAt: DateTime.now(),
      );

      // إرسال طلب التسجيل إلى Firebase
      await Provider.of<DatabaseService>(context, listen: false)
          .addPendingUser(newUser);

      // حفظ بيانات الاعتماد في SharedPreferences للمراجعة اللاحقة
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastEmployeeId', newUser.employeeId);
      await prefs.setString('registrationStatus', 'pending');

      // إشعار نجاح الإرسال
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('تم إرسال طلب التسجيل بنجاح'),
                    Text(
                      'سيتم مراجعة طلبك خلال 24 ساعة',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      // العودة لشاشة تسجيل الدخول
      Navigator.pop(context);

    } catch (e) {
      print('خطأ في التسجيل: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('فشل إرسال الطلب. يرجى المحاولة مرة أخرى'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}