import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String orders = '/orders';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashPage(),
      login: (context) => const LoginPage(),
      // Add more routes as needed
    };
  }
}

