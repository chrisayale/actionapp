import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';

class AppRoutes {
  static const String login = '/';
  static const String dashboard = '/dashboard';
  static const String users = '/users';
  static const String reports = '/reports';

  static Map<String, WidgetBuilder> get routes {
    return {
      login: (context) => const LoginPage(),
      dashboard: (context) => const DashboardPage(),
      // Add more routes as needed
    };
  }
}

