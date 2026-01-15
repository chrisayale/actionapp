import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _usersCount = 0;
  int _establishmentsCount = 0;
  int _promotionsCount = 0;
  int _activePromotionsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      // Load users count
      final usersSnapshot =
          await FirebaseService.firestore.collection('users').get();
      final usersCount = usersSnapshot.docs.length;

      // Load establishments count
      final establishmentsSnapshot =
          await FirebaseService.firestore.collection('establishments').get();
      final establishmentsCount = establishmentsSnapshot.docs.length;

      // Load promotions count
      final promotionsSnapshot =
          await FirebaseService.firestore.collection('promotions').get();
      final promotionsCount = promotionsSnapshot.docs.length;

      // Load active promotions count
      final activePromotionsSnapshot = await FirebaseService.firestore
          .collection('promotions')
          .where('isActive', isEqualTo: true)
          .get();
      final activePromotionsCount = activePromotionsSnapshot.docs.length;

      setState(() {
        _usersCount = usersCount;
        _establishmentsCount = establishmentsCount;
        _promotionsCount = promotionsCount;
        _activePromotionsCount = activePromotionsCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    
    // Responsive grid columns
    int crossAxisCount;
    if (isMobile) {
      crossAxisCount = 1;
    } else if (isTablet) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 4;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundLight,
            AppColors.gray50,
          ],
        ),
      ),
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.yellowPrimary),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tableau de bord',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 28 : 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Vue d\'ensemble de votre plateforme',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 14 : 16,
                              color: AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      if (!isMobile)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.yellowPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.yellowPrimary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppColors.yellowDark,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateTime.now().toString().split(' ')[0],
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textPrimaryLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 24 : 32),
                  // Statistics Cards
                  GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: isMobile ? 16 : 20,
                    mainAxisSpacing: isMobile ? 16 : 20,
                    childAspectRatio: isMobile ? 1.2 : 1.0,
                    children: [
                      _buildStatCard(
                        context,
                        title: 'Utilisateurs',
                        value: _usersCount.toString(),
                        icon: Icons.people_outline,
                        gradientColors: [
                          AppColors.info,
                          AppColors.info.withOpacity(0.7),
                        ],
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.users);
                        },
                      ),
                      _buildStatCard(
                        context,
                        title: 'Établissements',
                        value: _establishmentsCount.toString(),
                        icon: Icons.store_outlined,
                        gradientColors: [
                          AppColors.success,
                          AppColors.success.withOpacity(0.7),
                        ],
                        onTap: () {
                          Navigator.pushNamed(context, '/establishments');
                        },
                      ),
                      _buildStatCard(
                        context,
                        title: 'Promotions',
                        value: _promotionsCount.toString(),
                        icon: Icons.local_offer_outlined,
                        gradientColors: [
                          AppColors.warning,
                          AppColors.warning.withOpacity(0.7),
                        ],
                        onTap: () {
                          Navigator.pushNamed(context, '/promotions');
                        },
                      ),
                      _buildStatCard(
                        context,
                        title: 'Promotions actives',
                        value: _activePromotionsCount.toString(),
                        icon: Icons.check_circle_outline,
                        gradientColors: [
                          AppColors.yellowPrimary,
                          AppColors.yellowDark,
                        ],
                        onTap: () {
                          Navigator.pushNamed(context, '/promotions');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.borderLight,
                width: 1,
              ),
            ),
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon and Value Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Container
                    Container(
                      width: isMobile ? 40 : 48,
                      height: isMobile ? 40 : 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors[0].withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: AppColors.white,
                        size: isMobile ? 20 : 24,
                      ),
                    ),
                    // Value Badge
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8 : 10,
                          vertical: isMobile ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              gradientColors[0].withOpacity(0.1),
                              gradientColors[1].withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: gradientColors[0].withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          value,
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 16 : 20,
                            fontWeight: FontWeight.bold,
                            color: gradientColors[0],
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 10 : 12),
                // Title
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 12 : 14,
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isMobile ? 6 : 8),
                // Arrow indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Voir détails',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 10 : 11,
                        color: gradientColors[0],
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 9,
                      color: gradientColors[0],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




