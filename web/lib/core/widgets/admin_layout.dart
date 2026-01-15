import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';

class AdminLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const AdminLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSidebarExpanded = true;

  bool get _isMobile => MediaQuery.of(context).size.width < 768;
  bool get _isTablet => MediaQuery.of(context).size.width >= 768 && MediaQuery.of(context).size.width < 1024;

  @override
  Widget build(BuildContext context) {
    if (_isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Administration'),
          backgroundColor: Color.lerp(AppColors.yellowPrimary, AppColors.white, 0.25) ?? AppColors.yellowLight,
          foregroundColor: AppColors.black,
          elevation: 0,
        ),
        drawer: _buildDrawer(context),
        body: widget.child,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Row(
        children: [
          // Modern Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            width: _isSidebarExpanded ? 280 : 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(AppColors.yellowPrimary, AppColors.white, 0.3) ?? AppColors.yellowLight,
                    Color.lerp(AppColors.yellowDark, AppColors.white, 0.4) ?? AppColors.yellowLight,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellowPrimary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Modern Header
                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: AppColors.white,
                            size: 28,
                          ),
                        ),
                        if (_isSidebarExpanded) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Admin Panel',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Action App',
                                  style: TextStyle(
                                    color: AppColors.white.withOpacity(0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Menu Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      children: [
                        _buildMenuItem(
                          context,
                          icon: Icons.dashboard_rounded,
                          label: 'Dashboard',
                          route: AppRoutes.dashboard,
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.people_rounded,
                          label: 'Utilisateurs',
                          route: AppRoutes.users,
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.store_rounded,
                          label: 'Établissements',
                          route: '/establishments',
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.local_offer_rounded,
                          label: 'Promotions',
                          route: '/promotions',
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.bar_chart_rounded,
                          label: 'Rapports',
                          route: AppRoutes.reports,
                        ),
                      ],
                    ),
                  ),
                  // User section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.1),
                      border: Border(
                        top: BorderSide(
                          color: AppColors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return Column(
                          children: [
                            if (_isSidebarExpanded && authProvider.user != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.white,
                                            AppColors.white.withOpacity(0.8),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          authProvider.user!.email!
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: AppColors.yellowPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            authProvider.user!.email ?? 'Admin',
                                            style: const TextStyle(
                                              color: AppColors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Administrateur',
                                            style: TextStyle(
                                              color: AppColors.white.withOpacity(0.8),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.error.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final authProvider =
                                      Provider.of<AuthProvider>(context, listen: false);
                                  await authProvider.signOut();
                                  if (context.mounted) {
                                    Navigator.pushReplacementNamed(
                                        context, AppRoutes.login);
                                  }
                                },
                                icon: const Icon(Icons.logout_rounded, size: 18),
                                label: _isSidebarExpanded
                                    ? const Text('Déconnexion')
                                    : const SizedBox.shrink(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  minimumSize: Size(
                                    _isSidebarExpanded ? double.infinity : 52,
                                    52,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Modern Top AppBar
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: _isTablet ? 20 : 32,
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.yellowPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isSidebarExpanded
                                ? Icons.menu_open_rounded
                                : Icons.menu_rounded,
                            color: AppColors.yellowPrimary,
                            size: 24,
                          ),
                          onPressed: () {
                            setState(() {
                              _isSidebarExpanded = !_isSidebarExpanded;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Administration',
                              style: TextStyle(
                                fontSize: _isTablet ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryLight,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Action App',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.yellowPrimary.withOpacity(0.85),
              AppColors.yellowDark.withOpacity(0.75),
            ],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              height: 140,
              padding: const EdgeInsets.all(20),
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: AppColors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (authProvider.user != null) ...[
                        Text(
                          authProvider.user!.email ?? 'Admin',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Administrateur',
                          style: TextStyle(
                            color: AppColors.white.withOpacity(0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                children: [
                  _buildDrawerMenuItem(
                    context,
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    route: AppRoutes.dashboard,
                  ),
                  _buildDrawerMenuItem(
                    context,
                    icon: Icons.people_rounded,
                    label: 'Utilisateurs',
                    route: AppRoutes.users,
                  ),
                  _buildDrawerMenuItem(
                    context,
                    icon: Icons.store_rounded,
                    label: 'Établissements',
                    route: '/establishments',
                  ),
                  _buildDrawerMenuItem(
                    context,
                    icon: Icons.local_offer_rounded,
                    label: 'Promotions',
                    route: '/promotions',
                  ),
                  _buildDrawerMenuItem(
                    context,
                    icon: Icons.bar_chart_rounded,
                    label: 'Rapports',
                    route: AppRoutes.reports,
                  ),
                ],
              ),
            ),
            // Logout button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await authProvider.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, AppRoutes.login);
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Déconnexion'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    final isActive = widget.currentRoute == route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.white.withOpacity(0.25)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
        border: isActive
            ? Border.all(
                color: AppColors.white.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.white.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isActive ? AppColors.white : AppColors.white.withOpacity(0.8),
            size: 22,
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.white : AppColors.white.withOpacity(0.9),
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
        trailing: isActive
            ? Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, route);
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    final isActive = widget.currentRoute == route;
    final isExpanded = _isSidebarExpanded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.white.withOpacity(0.25)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
        border: isActive
            ? Border.all(
                color: AppColors.white.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushReplacementNamed(context, route);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 16 : 12,
              vertical: 14,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.white.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isActive ? AppColors.white : AppColors.white.withOpacity(0.8),
                    size: 22,
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isActive ? AppColors.white : AppColors.white.withOpacity(0.9),
                        fontSize: 15,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
