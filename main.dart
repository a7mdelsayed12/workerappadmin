import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

// Services
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'services/image_service.dart';
import 'services/local_storage_service.dart';
import 'services/repair_service.dart';
import 'services/worker_service.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/assets/assets_management.dart';
import 'screens/admin/users/users_management_screen.dart';
import 'screens/admin/warehouse/warehouse_management.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  final dbService = DatabaseService();
  await dbService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DatabaseService>.value(value: dbService),
        ChangeNotifierProvider<WorkerService>(create: (_) => WorkerService()),
        ChangeNotifierProxyProvider<DatabaseService, AuthService>(
          create: (ctx) => AuthService(ctx.read<DatabaseService>()),
          update: (ctx, db, auth) => auth!..updateDatabaseService(db),
        ),
        ChangeNotifierProvider(create: (_) => ImageService()),
        ChangeNotifierProvider(create: (_) => LocalStorageService()),
        ChangeNotifierProvider(create: (_) => RepairService()),
      ],
      child: MyApp(),
    ),
  );
}



class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      title: 'نظام إدارة المستودع - الأدمن',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
      ),
      home: LoginScreen(),
      routes: {

        // Auth
        '/login': (ctx) => LoginScreen(),
        '/register': (ctx) => RegisterScreen(),

        // Admin
        '/admin_dashboard': (ctx) => AdminDashboard(),
        '/cars_management': (ctx) => CarsManagement(),
        '/pending_requests': (ctx) => UserManagementScreen(),
        '/warehouse': (ctx) => WarehouseManagement(),

      },
    );
  }
}
