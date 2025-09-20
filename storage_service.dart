// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  List<String> _loginHistory = [];

  @override
  void initState() {
    super.initState();
    _loadCredentials();
    _loadLoginHistory();
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId   = prefs.getString('employeeId') ?? '';
    final savedPass = prefs.getString('password')   ?? '';
    final remember  = prefs.getBool('rememberMe')   ?? false;

    if (remember) {
      _employeeIdController.text = savedId;
      _passwordController.text   = savedPass;
      setState(() => _rememberMe = true);
    }
  }

  Future<void> _loadLoginHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loginHistory = prefs.getStringList('loginHistory') ?? [];
    });
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('المستخدمون السابقون'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _loginHistory.length,
            itemBuilder: (_, i) {
              final parts = _loginHistory[i].split(':');
              final id   = parts[0];
              final pass = parts[1];
              return ListTile(
                title: Text(id),
                onTap: () {
                  _employeeIdController.text = id;
                  _passwordController.text   = pass;
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _saveCredentials(bool success) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe && success) {
      await prefs.setString('employeeId', _employeeIdController.text.trim());
      await prefs.setString('password', _passwordController.text);
      await prefs.setBool('rememberMe', true);
    } else {
      await prefs.remove('employeeId');
      await prefs.remove('password');
      await prefs.setBool('rememberMe', false);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.login(
      _employeeIdController.text.trim(),
      _passwordController.text,
    );

    if (success) {
      await _saveCredentials(true);
      // إضافة إلى سجل الدخول التاريخي
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('loginHistory') ?? [];
      final entry = '${_employeeIdController.text.trim()}:${_passwordController.text}';
      if (!history.contains(entry)) {
        history.add(entry);
        await prefs.setStringList('loginHistory', history);
      }
      Navigator.pushReplacementNamed(context, '/admin_dashboard');
    } else {
      await _saveCredentials(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('رقم وظيفي أو كلمة مرور خاطئة'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('تسجيل الدخول'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            tooltip: 'سجلّ المستخدمين السابقين',
            onPressed: _showHistoryDialog,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.admin_panel_settings, size: 80, color: Colors.blue[600]),
                    SizedBox(height: 16),
                    Text('نظام إدارة المستودع', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('لوحة تحكم الأدمن', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    SizedBox(height: 32),

                    TextFormField(
                      controller: _employeeIdController,
                      decoration: InputDecoration(
                        labelText: 'الرقم الوظيفي',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true, fillColor: Colors.grey[50],
                      ),
                      validator: (value) =>
                      (value == null || value.isEmpty) ? 'يرجى إدخال الرقم الوظيفي' : null,
                    ),
                    SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true, fillColor: Colors.grey[50],
                      ),
                      validator: (value) =>
                      (value == null || value.isEmpty) ? 'يرجى إدخال كلمة المرور' : null,
                    ),
                    SizedBox(height: 16),

                    CheckboxListTile(
                      title: Text('تذكرني'),
                      value: _rememberMe,
                      onChanged: (val) => setState(() => _rememberMe = val ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    SizedBox(height: 24),

                    Consumer<AuthService>(
                      builder: (context, authService, child) {
                        return SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: authService.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: authService.isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text('تسجيل الدخول', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      child: Text('ليس لديك حساب؟ طلب تسجيل جديد'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
