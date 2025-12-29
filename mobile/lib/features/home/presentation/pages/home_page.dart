import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../auth/auth_controller.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class HomePage extends StatefulWidget {
  final AuthController authController;

  const HomePage({
    super.key,
    required this.authController,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  String _selectedCategory = 'Boissons';
  final List<String> _categories = [
    'Boissons',
    'Karaoké',
    'Nourriture',
    'Taxi',
    'Shopping',
    'Divertissement',
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    // Animation controller for vibrant effects
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _colorAnimation = ColorTween(
      begin: const Color(0xFFFFD700), // Jaune
      end: const Color(0xFFFF6B35), // Orange
    ).animate(_animationController);

    // Fade animation for initial load
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondaryLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header jaune avec elevation - FIXE
            _buildHeader(),
            const SizedBox(height: AppSpacing.sm),
            // Catégories avec Cards - FIXE
            _buildCategories(),
            const SizedBox(height: AppSpacing.md),
            // Barre de recherche et filtre avec Cards - FIXE
            _buildSearchAndFilter(),
            const SizedBox(height: AppSpacing.md),
            // Contenu scrollable
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bannière promotionnelle avec Card - SCROLLABLE
                      _buildPromotionBanner(),
                      const SizedBox(height: AppSpacing.sm),
                      // Section À proximité et Annonceur avec Cards - SCROLLABLE
                      _buildProximitySection(),
                      const SizedBox(height: AppSpacing.md),
                      // Liste des établissements - SCROLLABLE
                      _buildEstablishmentsList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Card(
          elevation: 4,
          margin: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(AppSpacing.radiusXLarge),
              bottomRight: Radius.circular(AppSpacing.radiusXLarge),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.sm + 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _colorAnimation.value ?? const Color(0xFFFFD700),
                  const Color(0xFFFF6B35),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppSpacing.radiusXLarge),
                bottomRight: Radius.circular(AppSpacing.radiusXLarge),
              ),
              boxShadow: [
                BoxShadow(
                  color: (_colorAnimation.value ?? const Color(0xFFFFD700))
                      .withOpacity(_glowAnimation.value),
                  blurRadius: 30,
                  spreadRadius: 3,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(_glowAnimation.value * 0.5),
                  blurRadius: 25,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icône de profil avec effet
                Material(
                  color: AppColors.white.withOpacity(0),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.profile);
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: const Icon(Icons.person, color: AppColors.textPrimaryLight, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Logo de l'application avec Card animé
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    border: Border.all(
                      color: _colorAnimation.value ?? const Color(0xFFFFD700),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_colorAnimation.value ?? const Color(0xFFFFD700))
                            .withOpacity(_glowAnimation.value),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(_glowAnimation.value * 0.5),
                        blurRadius: 15,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    child: Image.asset(
                      'assets/images/Logo.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md - 4),
                Text(
                  'Action',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                // Icône grille avec effet
                Material(
                  color: AppColors.white.withOpacity(0),
                  child: InkWell(
                    onTap: () {
                      // TODO: Changer la vue
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: const Icon(Icons.grid_view, color: AppColors.textPrimaryLight, size: 24),
                    ),
                  ),
                ),
                // Icône notification avec badge
                Stack(
                  children: [
                    Material(
                      color: AppColors.white.withOpacity(0),
                      child: InkWell(
                        onTap: () {
                          // TODO: Ouvrir les notifications
                        },
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimaryLight, size: 24),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategories() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category == _selectedCategory;
              
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Material(
                    color: AppColors.white.withOpacity(0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.sm + 4),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFD700) : AppColors.white.withOpacity(0),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
                        ),
                        child: Center(
                          child: Text(
                            category,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.textPrimaryLight : AppColors.textTertiaryLight,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm + 4),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Barre de recherche
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher',
                      hintStyle: GoogleFonts.inter(
                        color: AppColors.textTertiaryLight,
                        fontSize: 14,
                      ),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.2), // Jaune clair
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.search,
                          color: AppColors.textPrimaryLight,
                          size: 18,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4, vertical: AppSpacing.sm + 4),
                    ),
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md - 4),
              // Bouton filtre - gris clair
              Material(
                color: AppColors.gray200, // Gris clair
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                child: InkWell(
                  onTap: () {
                    // TODO: Ouvrir le filtre
                  },
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.tune,
                          color: AppColors.textPrimaryLight,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Trier par',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.textPrimaryLight,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionBanner() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge + 4),
            ),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFFD700), // Jaune
                    _colorAnimation.value ?? const Color(0xFFFF6B35), // Orange
                    const Color(0xFF4CAF50), // Vert
                    const Color(0xFF2196F3), // Bleu
                  ],
                  stops: [
                    0.0,
                    0.33 + (0.1 * _glowAnimation.value),
                    0.66 + (0.1 * _glowAnimation.value),
                    1.0,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge + 4),
                boxShadow: [
                  BoxShadow(
                    color: (_colorAnimation.value ?? const Color(0xFFFFD700))
                        .withOpacity(_glowAnimation.value),
                    blurRadius: 30,
                    spreadRadius: 4,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(_glowAnimation.value * 0.5),
                    blurRadius: 25,
                    spreadRadius: 3,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
          child: Stack(
            children: [
              // Motif de fond décoratif
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFD700).withOpacity(0.15),
                        AppColors.white.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFF6B35).withOpacity(0.2),
                        AppColors.white.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
              // Icône de fond avec effet amélioré
              Positioned(
                right: 15,
                top: 15,
                child: Opacity(
                  opacity: 0.25,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFD700).withOpacity(0.4),
                          const Color(0xFFFFD700).withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      size: 50,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ),
              ),
              // Contenu principal
              Padding(
                  padding: const EdgeInsets.all(AppSpacing.md + 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge PROMOTION amélioré
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFFFD700),
                            const Color(0xFFFF6B35),
                            const Color(0xFFFF6B35).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Card(
                        elevation: 0,
                        color: AppColors.white.withOpacity(0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4, vertical: AppSpacing.xs + 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'PROMOTION',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimaryLight,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm + 6),
                    // Texte principal avec effet amélioré
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.textPrimaryLight,
                              AppColors.gray700,
                              AppColors.textPrimaryLight,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            '2+1=3',
                            style: GoogleFonts.inter(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: AppColors.white,
                              letterSpacing: -1.5,
                              height: 0.95,
                              shadows: [
                                Shadow(
                                  color: AppColors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.black.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'GRATUIT',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryLight,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildProximitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Section "À proximité" - gauche
              Expanded(
                child: Material(
                  color: AppColors.white.withOpacity(0),
                  child: InkWell(
                    onTap: () {
                      // TODO: Ouvrir les promotions à proximité
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        children: [
                          // Carré bleu clair avec icône
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1), // Bleu clair
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFF1976D2), // Bleu foncé
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md - 4),
                          // Textes
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'À proximité',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs / 2),
                                Text(
                                  'Promotions près de vous',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textSecondaryLight,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Séparateur vertical
              Container(
                width: 1,
                height: 40,
                        color: AppColors.gray300,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              // Section "Annonceur" - droite
              Material(
                color: AppColors.white.withOpacity(0),
                child: InkWell(
                  onTap: () {
                    // TODO: Ouvrir la page annonceur
                  },
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.sm + 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700), // Jaune solide
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.business,
                          color: AppColors.textPrimaryLight,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Annonceur',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstablishmentsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Liste des établissements avec design amélioré
          _buildEstablishmentCard(
            name: 'RDC BAR',
            location: 'KAVA/GOMBE, Kinshasa',
            offer: 'Beaufort',
            promotion: '2+1=3',
            price: '3 000 CDF',
            isActive: true,
            distance: '0.5 km',
            rating: 4.5,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildEstablishmentCard(
            name: 'Bistro Le Soleil d\'Or',
            location: 'GOMBE, Kinshasa',
            offer: 'Menu du jour',
            promotion: '1+1=2',
            price: '5 000 CDF',
            isActive: true,
            distance: '1.2 km',
            rating: 4.8,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildEstablishmentCard(
            name: 'Café Central',
            location: 'LINGWALA, Kinshasa',
            offer: 'Café expresso',
            promotion: 'Réduction 20%',
            price: '2 500 CDF',
            isActive: false,
            distance: '2.1 km',
            rating: 4.2,
          ),
        ],
      ),
    );
  }

  Widget _buildEstablishmentCard({
    required String name,
    required String location,
    required String offer,
    required String promotion,
    required String price,
    required bool isActive,
    required String distance,
    required double rating,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (_colorAnimation.value ?? const Color(0xFFFFD700))
                      .withOpacity(_glowAnimation.value * 0.2),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(_glowAnimation.value * 0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: AppColors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () {
                  // TODO: Voir les détails de l'établissement
                },
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Panneau jaune à gauche avec icône animé
                    Container(
                      width: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _colorAnimation.value ?? const Color(0xFFFFD700),
                            const Color(0xFFFF6B35),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_colorAnimation.value ?? const Color(0xFFFFD700))
                                .withOpacity(_glowAnimation.value * 0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                child: Center(
                  child: Icon(
                    Icons.local_drink,
                    size: 50,
                    color: AppColors.gray900,
                  ),
                ),
              ),
              // Panneau blanc à droite avec contenu
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header avec nom et badge Actif
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryLight,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                              ),
                              child: Text(
                                'Actif',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm + 2),
                      // Localisation
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: AppColors.gray500),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              location,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.gray700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Section Offre et Prix côte à côte
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Colonne Offre (gauche)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Offre',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs + 2),
                                Text(
                                  offer,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  promotion,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Colonne Prix (droite)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Prix',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs + 2),
                              Text(
                                price,
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.info,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Boutons d'action
                      Row(
                        children: [
                          // Bouton "Voir plus..."
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // TODO: Voir plus de détails
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF2196F3), width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'Voir plus...',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.info,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm + 2),
                          // Bouton "Je serais là" animé
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _colorAnimation.value ?? const Color(0xFFFFD700),
                                  const Color(0xFFFF6B35),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                              boxShadow: [
                                BoxShadow(
                                  color: (_colorAnimation.value ?? const Color(0xFFFFD700))
                                      .withOpacity(_glowAnimation.value * 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 3),
                                ),
                                BoxShadow(
                                  color: const Color(0xFF4CAF50).withOpacity(_glowAnimation.value * 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: Action "Je serais là"
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.black87,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.sm + 4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.thumb_up, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Je serais là',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
      },
    );
  }
}
