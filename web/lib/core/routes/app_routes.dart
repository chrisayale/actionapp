import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/create_super_admin_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/users/presentation/pages/users_list_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../widgets/admin_layout.dart';
import '../widgets/initial_route_guard.dart';

class AppRoutes {
  static const String initial = '/';
  static const String login = '/login';
  static const String createSuperAdmin = '/create-super-admin';
  static const String dashboard = '/dashboard';
  static const String users = '/users';
  static const String reports = '/reports';
  static const String establishments = '/establishments';
  static const String promotions = '/promotions';

  static Map<String, WidgetBuilder> get routes {
    return {
      initial: (context) => InitialRouteGuard(),
      login: (context) => const LoginPage(),
      createSuperAdmin: (context) => const CreateSuperAdminPage(),
      dashboard: (context) => _buildProtectedRoute(
        context,
        const DashboardPage(),
        AppRoutes.dashboard,
      ),
      users: (context) => _buildProtectedRoute(
        context,
        const UsersListPage(),
        AppRoutes.users,
      ),
      reports: (context) => _buildProtectedRoute(
        context,
        const ReportsPage(),
        AppRoutes.reports,
      ),
      establishments: (context) => _buildProtectedRoute(
        context,
        const Scaffold(
          body: Center(child: Text('Établissements - À venir')),
        ),
        AppRoutes.establishments,
      ),
      promotions: (context) => _buildProtectedRoute(
        context,
        const Scaffold(
          body: Center(child: Text('Promotions - À venir')),
        ),
        AppRoutes.promotions,
      ),
    };
  }

  static Widget _buildProtectedRoute(
    BuildContext context,
    Widget page,
    String route,
  ) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAdmin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return AdminLayout(
          currentRoute: route,
          child: page,
        );
      },
    );
  }
}




