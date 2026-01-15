import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../auth/auth_controller.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../advertiser/data/models/promotion_model.dart';
import '../../../advertiser/data/repositories/advertiser_repository.dart';
import 'promotion_detail_page.dart';

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
  bool _isGridView = false; // false = liste, true = grille
  final List<String> _categories = [
    'Boissons',
    'Karaoké',
    'Nourriture',
    'Taxi',
    'Shopping',
    'Divertissement',
  ];
  
  StreamSubscription<QuerySnapshot>? _promotionsSubscription;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Color?> _colorAnimation;
  
  // Promotions publiques
  List<PromotionModel> _promotions = [];
  bool _isLoadingPromotions = false;
  final AdvertiserRepository _repository = AdvertiserRepository();
  
  // Contrôleurs pour le dialogue de modification du PIN
  final List<TextEditingController> _pinDialogControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<TextEditingController> _confirmPinDialogControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _pinDialogFocusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );
  final List<FocusNode> _confirmPinDialogFocusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );
  
  // Contrôleurs pour le dialogue de connexion PIN
  final List<TextEditingController> _loginPinControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _loginPinFocusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );
  
  // Contrôleurs pour le dialogue de changement de PIN (avec ancien PIN)
  final List<TextEditingController> _oldPinControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<TextEditingController> _newPinControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<TextEditingController> _confirmNewPinControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _oldPinFocusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );
  final List<FocusNode> _newPinFocusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );
  final List<FocusNode> _confirmNewPinFocusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );

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
    _loadPublicPromotions();
    
    // Écouter les changements Firestore pour rafraîchir automatiquement
    _setupFirestoreListener();
  }
  
  void _setupFirestoreListener() {
    // Écouter les changements dans la collection promotions
    _promotionsSubscription = FirebaseService.firestore
        .collection('promotions')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      // Rafraîchir la liste quand il y a des changements (nouvelle promotion créée, etc.)
      if (mounted) {
        _loadPublicPromotions();
      }
    });
  }
  
  Future<void> _loadPublicPromotions() async {
    setState(() {
      _isLoadingPromotions = true;
    });

    try {
      final promotions = await _repository.getPublicPromotions();
      if (mounted) {
        setState(() {
          _promotions = promotions;
          _isLoadingPromotions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Extraire le message d'erreur de manière plus lisible
        String errorMessage = 'Erreur lors du chargement des promotions';
        if (e.toString().contains('Timeout')) {
          errorMessage = 'Le serveur ne répond pas. Vérifiez votre connexion internet.';
        } else if (e.toString().contains('Exception:')) {
          final exceptionMatch = RegExp(r'Exception:\s*(.+)').firstMatch(e.toString());
          if (exceptionMatch != null) {
            errorMessage = exceptionMatch.group(1) ?? errorMessage;
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            // Use default (fixed) behavior to avoid off‑screen issues
            // when there is a large bottom area (FAB / footer / bottom bar).
            behavior: SnackBarBehavior.fixed,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: () {
                _loadPublicPromotions();
              },
            ),
          ),
        );
        setState(() {
          _isLoadingPromotions = false;
        });
      }
    }
  }

  Future<void> _toggleInterestedCount(PromotionModel promotion) async {
    try {
      final updatedPromotion = await _repository.toggleInterestedCount(promotion.id);
      if (mounted) {
        setState(() {
          final index = _promotions.indexWhere((p) => p.id == promotion.id);
          if (index != -1) {
            _promotions[index] = updatedPromotion;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'action: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _promotionsSubscription?.cancel();
    _animationController.dispose();
    for (var controller in _pinDialogControllers) {
      controller.dispose();
    }
    for (var controller in _confirmPinDialogControllers) {
      controller.dispose();
    }
    for (var node in _pinDialogFocusNodes) {
      node.dispose();
    }
    for (var node in _confirmPinDialogFocusNodes) {
      node.dispose();
    }
    for (var controller in _loginPinControllers) {
      controller.dispose();
    }
    for (var node in _loginPinFocusNodes) {
      node.dispose();
    }
    for (var controller in _oldPinControllers) {
      controller.dispose();
    }
    for (var controller in _newPinControllers) {
      controller.dispose();
    }
    for (var controller in _confirmNewPinControllers) {
      controller.dispose();
    }
    for (var node in _oldPinFocusNodes) {
      node.dispose();
    }
    for (var node in _newPinFocusNodes) {
      node.dispose();
    }
    for (var node in _confirmNewPinFocusNodes) {
      node.dispose();
    }
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
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Icon(
                        _isGridView ? Icons.view_list : Icons.grid_view,
                        color: AppColors.textPrimaryLight,
                        size: 24,
                      ),
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
                        // Actualiser la liste quand on change de catégorie
                        _loadPublicPromotions();
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'À proximité',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimaryLight,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: AppSpacing.xs / 2),
                                Text(
                                  'Promotions près de vous',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textSecondaryLight,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
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
              Flexible(
                child: Material(
                  color: AppColors.white.withOpacity(0),
                  child: InkWell(
                    onTap: () {
                      _handleAnnonceurClick();
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700), // Jaune solide
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.business,
                            color: AppColors.textPrimaryLight,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              'Annonceur',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
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
    if (_isLoadingPromotions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.yellowPrimary),
          ),
        ),
      );
    }

    if (_promotions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Center(
          child: Text(
            'Aucune promotion publique disponible pour le moment.',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_isGridView) {
      return _buildPromotionsGrid(_promotions);
    } else {
      return _buildPromotionsListView(_promotions);
    }
  }
  
  Widget _buildPromotionsListView(List<PromotionModel> promotions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var promotion in promotions) ...[
            _buildPromotionCard(promotion),
            if (promotion != promotions.last) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
  
  /// Format price with currency
  String _formatPrice(PromotionModel promotion) {
    if (promotion.price == null) {
      return 'N/A';
    }
    final formattedPrice = promotion.price!.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
    return '$formattedPrice ${promotion.currency ?? ''}';
  }

  /// Format view count (e.g., 1000 -> "1K", 1500 -> "1.5K")
  String _formatViewCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      final k = count / 1000;
      return k % 1 == 0 ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    } else {
      final m = count / 1000000;
      return m % 1 == 0 ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
    }
  }

  /// Format location string (ville, quartier/commune, avenue, numero)
  String _formatLocation(PromotionLocation location) {
    final parts = <String>[];
    if (location.ville != null && location.ville!.isNotEmpty) {
      parts.add(location.ville!);
    }
    if (location.quartier != null && location.quartier!.isNotEmpty) {
      parts.add(location.quartier!);
    }
    if (location.avenue != null && location.avenue!.isNotEmpty) {
      parts.add(location.avenue!);
    }
    if (location.numero != null && location.numero!.isNotEmpty) {
      parts.add(location.numero!);
    }
    return parts.isNotEmpty ? parts.join(', ') : 'Kinshasa';
  }

  /// Open maps with directions to the location
  Future<void> _openMaps(PromotionLocation? location) async {
    if (location == null || location.latitude == null || location.longitude == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Localisation non disponible'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    // Create Google Maps URL with directions
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Impossible d\'ouvrir Google Maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture de la carte: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildPromotionCard(PromotionModel promotion) {
    final locationText = promotion.location != null
        ? _formatLocation(promotion.location!)
        : 'Kinshasa';
    
    return _buildEstablishmentCard(
      name: promotion.establishmentName,
      location: locationText,
      offer: promotion.boissonName,
      promotion: promotion.formule,
      price: _formatPrice(promotion),
      isActive: promotion.isActive,
      distance: '0 km',
      rating: 4.5,
      imageUrl: promotion.boissonImageUrl, // Utiliser l'image de la boisson
      establishmentLogoUrl: promotion.establishmentLogoUrl,
      interestedCount: promotion.interestedCount,
      viewCount: promotion.viewCount,
      promotionId: promotion.id,
      promotionLocation: promotion.location,
      onInterestedTap: () => _toggleInterestedCount(promotion),
      onLocationTap: () => _openMaps(promotion.location),
      onViewMoreTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PromotionDetailPage(promotion: promotion),
          ),
        );
      },
    );
  }
  
  Widget _buildPromotionsGrid(List<PromotionModel> promotions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.75,
        ),
        itemCount: promotions.length,
        itemBuilder: (context, index) {
          final promotion = promotions[index];
          return _buildPromotionGridCard(promotion);
        },
      ),
    );
  }
  
  Widget _buildPromotionGridCard(PromotionModel promotion) {
    final locationText = promotion.location != null
        ? _formatLocation(promotion.location!)
        : 'Kinshasa';
    
    return _buildEstablishmentGridCard(
      name: promotion.establishmentName,
      location: locationText,
      offer: promotion.boissonName,
      promotion: promotion.formule,
      price: _formatPrice(promotion),
      isActive: promotion.isActive,
      distance: '0 km',
      rating: 4.5,
      imageUrl: promotion.boissonImageUrl, // Utiliser l'image de la boisson
      establishmentLogoUrl: promotion.establishmentLogoUrl,
      interestedCount: promotion.interestedCount,
      viewCount: promotion.viewCount,
      promotionId: promotion.id,
      promotionLocation: promotion.location,
      onInterestedTap: () => _toggleInterestedCount(promotion),
      onLocationTap: () => _openMaps(promotion.location),
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
    String? imageUrl,
    String? establishmentLogoUrl,
    int interestedCount = 0,
    int viewCount = 0,
    String? promotionId,
    PromotionLocation? promotionLocation,
    VoidCallback? onInterestedTap,
    VoidCallback? onLocationTap,
    VoidCallback? onViewMoreTap,
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
                    // Panneau jaune à gauche avec image ou icône animé
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: imageUrl == null || imageUrl.isEmpty
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _colorAnimation.value ?? const Color(0xFFFFD700),
                                      const Color(0xFFFF6B35),
                                    ],
                                  )
                                : null,
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
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                  ),
                                  child: Image.network(
                                    imageUrl,
                                    width: 100,
                                    height: 140,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          Icons.local_drink,
                                          size: 50,
                                          color: AppColors.gray900,
                                        ),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.yellowPrimary),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.local_drink,
                                    size: 50,
                                    color: AppColors.gray900,
                                  ),
                                ),
                        ),
                        // Badge compteur en haut à droite
                        if (interestedCount > 0)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.info,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                interestedCount.toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
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
                          // Nombre de vues (remplace le badge Actif)
                          if (viewCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.visibility,
                                    size: 12,
                                    color: AppColors.textPrimaryLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatViewCount(viewCount),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm + 2),
                      // Localisation cliquable et nombre de vues
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: onLocationTap,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: AppColors.gray500),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (promotionLocation != null) ...[
                                          if (promotionLocation.ville != null && promotionLocation.ville!.isNotEmpty)
                                            Text(
                                              promotionLocation.ville!,
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: AppColors.gray700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          if (promotionLocation.quartier != null && promotionLocation.quartier!.isNotEmpty)
                                            Text(
                                              promotionLocation.quartier!,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppColors.gray600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          if (promotionLocation.avenue != null && promotionLocation.avenue!.isNotEmpty)
                                            Text(
                                              promotionLocation.avenue!,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: AppColors.gray600,
                                              ),
                                            ),
                                          if (promotionLocation.numero != null && promotionLocation.numero!.isNotEmpty)
                                            Text(
                                              'N° ${promotionLocation.numero!}',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: AppColors.gray600,
                                              ),
                                            ),
                                        ] else
                                          Text(
                                            location,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: AppColors.gray700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.directions, size: 16, color: AppColors.info),
                                ],
                              ),
                            ),
                          ),
                          // Nombre de vues
                          if (viewCount > 0) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.visibility, size: 14, color: AppColors.textSecondaryLight),
                            const SizedBox(width: 4),
                            Text(
                              _formatViewCount(viewCount),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
                              onPressed: onViewMoreTap,
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
                          Expanded(
                            child: Container(
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
                                onPressed: onInterestedTap,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.black87,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm + 4,
                                    vertical: AppSpacing.sm + 4,
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
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

  Widget _buildEstablishmentGridCard({
    required String name,
    required String location,
    required String offer,
    required String promotion,
    required String price,
    required bool isActive,
    required String distance,
    required double rating,
    String? imageUrl,
    String? establishmentLogoUrl,
    int interestedCount = 0,
    int viewCount = 0,
    String? promotionId,
    PromotionLocation? promotionLocation,
    VoidCallback? onInterestedTap,
    VoidCallback? onLocationTap,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (_colorAnimation.value ?? const Color(0xFFFFD700))
                      .withOpacity(_glowAnimation.value * 0.2),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: AppColors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {
                  // TODO: Voir les détails de l'établissement
                },
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header avec panneau jaune et icône ou image
                    Container(
                      height: 75,
                      decoration: BoxDecoration(
                        gradient: imageUrl == null || imageUrl.isEmpty
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _colorAnimation.value ?? const Color(0xFFFFD700),
                                  const Color(0xFFFF6B35),
                                ],
                              )
                            : null,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_colorAnimation.value ?? const Color(0xFFFFD700))
                                .withOpacity(_glowAnimation.value * 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          if (imageUrl != null && imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: Image.network(
                                imageUrl,
                                width: double.infinity,
                                height: 85,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.local_drink,
                                      size: 40,
                                      color: AppColors.gray900,
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.yellowPrimary),
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            Center(
                              child: Icon(
                                Icons.local_drink,
                                size: 40,
                                color: AppColors.gray900,
                              ),
                            ),
                          // Nombre de vues (remplace le badge Actif)
                          if (viewCount > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.visibility,
                                      size: 10,
                                      color: AppColors.textPrimaryLight,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _formatViewCount(viewCount),
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Badge compteur en haut à gauche (ou à droite si pas actif)
                          if (interestedCount > 0)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.info,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  interestedCount.toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Contenu
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Nom
                          Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryLight,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          // Localisation cliquable
                          GestureDetector(
                            onTap: onLocationTap,
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, size: 12, color: AppColors.gray500),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    promotionLocation != null
                                        ? (promotionLocation.ville ?? location)
                                        : location,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.directions, size: 12, color: AppColors.info),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          // Promotion et prix
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      promotion,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.info,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      price,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.info,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          // Distance, rating et vues
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 12, color: Color(0xFFFFD700)),
                                  const SizedBox(width: 2),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  if (viewCount > 0) ...[
                                    const Icon(Icons.visibility, size: 12, color: AppColors.textSecondaryLight),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatViewCount(viewCount),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppColors.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    distance,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
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
          ),
        );
      },
    );
  }

  Future<void> _handleAnnonceurClick() async {
    try {
      final user = widget.authController.currentUser;
      if (user == null) {
        _showErrorDialog('Vous devez être connecté pour accéder à cette fonctionnalité.');
        return;
      }

      // Récupérer les données du profil depuis Firestore
      final doc = await FirebaseService.firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        _showErrorDialog('Profil utilisateur introuvable.');
        return;
      }

      final profileData = doc.data();
      final pin = profileData?['pin']?.toString() ?? '';
      final isDefaultPin = profileData?['isDefaultPin'] == true;

      // Vérifier si le PIN est toujours le PIN par défaut
      final bool isStillDefaultPin = isDefaultPin || pin == '1234';

      if (isStillDefaultPin) {
        // Afficher le dialogue pour PIN par défaut
        _showDefaultPinDialog();
      } else {
        // Afficher le dialogue pour PIN modifié
        _showModifiedPinDialog();
      }
    } catch (e) {
      _showErrorDialog('Erreur lors de la vérification: $e');
    }
  }

  void _showDefaultPinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.white,
                    AppColors.offWhite,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warning.withOpacity(0.2 * _glowAnimation.value),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header avec icône animée
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm + 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.warning.withOpacity(0.3 * _glowAnimation.value),
                                blurRadius: 15,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Code PIN par défaut',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryLight,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Message principal
                    Text(
                      'Vous utilisez encore le code PIN par défaut (1234).',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Carte d'avertissement
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.warning.withOpacity(0.15),
                            AppColors.warning.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warning.withOpacity(0.1 * _glowAnimation.value),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.security,
                            color: AppColors.warning,
                            size: 24,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Pour des raisons de sécurité, nous vous recommandons fortement de modifier votre code PIN avant de créer des annonces.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.warning,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Boutons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppColors.gray400,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            ),
                            child: Text(
                              'Annuler',
                              style: GoogleFonts.inter(
                                color: AppColors.gray600,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.warning,
                                  Colors.orange[700]!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.warning.withOpacity(0.4 * _glowAnimation.value),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showModifyPinDialog();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock_reset, color: AppColors.white, size: 20),
                                  const SizedBox(width: AppSpacing.sm),
                                  Flexible(
                                    child: Text(
                                      'Modifier le PIN',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: AppColors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getPinDialogValue(List<TextEditingController> controllers) {
    return controllers.map((e) => e.text).join();
  }

  void _onPinDialogChanged(int index, String value, List<TextEditingController> controllers, List<FocusNode> focusNodes, {bool isConfirm = false}) {
    // Use SchedulerBinding to defer focus changes and avoid web pointer binding issues
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // Move to next field if digit entered
      if (value.length == 1 && index < 3) {
        // Add a small delay to ensure the DOM is ready on web
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && focusNodes[index + 1].canRequestFocus) {
            // Unfocus current field first
            focusNodes[index].unfocus();
            // Then focus next field after a microtask
            Future.microtask(() {
              if (mounted && focusNodes[index + 1].canRequestFocus) {
                focusNodes[index + 1].requestFocus();
              }
            });
          }
        });
      }
      // Move to previous field if deleted
      else if (value.isEmpty && index > 0) {
        // Add a small delay to ensure the DOM is ready on web
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && focusNodes[index - 1].canRequestFocus) {
            // Unfocus current field first
            focusNodes[index].unfocus();
            // Then focus previous field after a microtask
            Future.microtask(() {
              if (mounted && focusNodes[index - 1].canRequestFocus) {
                focusNodes[index - 1].requestFocus();
              }
            });
          }
        });
      }
    });

    // If all fields filled and this is confirm PIN, validate
    if (isConfirm && controllers.every((controller) => controller.text.isNotEmpty)) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final pin = _getPinDialogValue(_pinDialogControllers);
        final confirmPin = _getPinDialogValue(_confirmPinDialogControllers);
        if (pin != confirmPin && pin.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Les codes PIN ne correspondent pas'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      });
    }
  }

  Widget _buildLoginPINField(int index, TextEditingController controller, FocusNode focusNode) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final isFocused = focusNode.hasFocus;
        final size = MediaQuery.of(context).size;
        final dialogPadding = 32.0;
        final availableWidth = size.width - dialogPadding;
        final spacing = 8.0;
        final totalSpacing = spacing * 3;
        final fieldWidth = (availableWidth - totalSpacing) / 4;
        final responsiveFieldSize = fieldWidth.clamp(50.0, 70.0);
        
        return LayoutBuilder(
          builder: (context, constraints) {
            final actualWidth = constraints.maxWidth > 0 
                ? constraints.maxWidth.clamp(50.0, 70.0)
                : responsiveFieldSize;
            final actualHeight = actualWidth * 1.2;
            
            return Container(
              width: actualWidth,
              height: actualHeight,
              margin: EdgeInsets.only(
                right: index < 3 ? spacing : 0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: (_colorAnimation.value ?? const Color(0xFFFFD700))
                              .withOpacity(0.3 * _glowAnimation.value),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.2 * _glowAnimation.value),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.gray300.withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                obscureText: true,
                obscuringCharacter: '●',
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                cursorColor: AppColors.textPrimaryLight,
                cursorWidth: 2,
                style: GoogleFonts.inter(
                  fontSize: actualWidth * 0.55,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                  letterSpacing: 0,
                  height: 1.2,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.gray500,
                      width: 2.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.gray500,
                      width: 2.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _colorAnimation.value ?? const Color(0xFFFFD700),
                      width: 3,
                    ),
                  ),
                ),
                onChanged: (value) => _onLoginPinChanged(index, value),
              ),
            );
          },
        );
      },
    );
  }

  void _onLoginPinChanged(int index, String value) {
    // Use SchedulerBinding to defer focus changes and avoid web pointer binding issues
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // Move to next field if digit entered
      if (value.length == 1 && index < 3) {
        // Add a small delay to ensure the DOM is ready on web
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && _loginPinFocusNodes[index + 1].canRequestFocus) {
            // Unfocus current field first
            _loginPinFocusNodes[index].unfocus();
            // Then focus next field after a microtask
            Future.microtask(() {
              if (mounted && _loginPinFocusNodes[index + 1].canRequestFocus) {
                _loginPinFocusNodes[index + 1].requestFocus();
              }
            });
          }
        });
      }
      // Move to previous field if deleted
      else if (value.isEmpty && index > 0) {
        // Add a small delay to ensure the DOM is ready on web
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && _loginPinFocusNodes[index - 1].canRequestFocus) {
            // Unfocus current field first
            _loginPinFocusNodes[index].unfocus();
            // Then focus previous field after a microtask
            Future.microtask(() {
              if (mounted && _loginPinFocusNodes[index - 1].canRequestFocus) {
                _loginPinFocusNodes[index - 1].requestFocus();
              }
            });
          }
        });
      }
    });
  }

  Widget _buildDialogPINField(int index, TextEditingController controller, FocusNode focusNode, {required bool isConfirm}) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final isFocused = focusNode.hasFocus;
        final size = MediaQuery.of(context).size;
        final dialogPadding = 32.0; // Padding du dialogue (16 * 2)
        final availableWidth = size.width - dialogPadding;
        final spacing = 8.0;
        final totalSpacing = spacing * 3; // 3 espaces entre 4 champs
        final fieldWidth = (availableWidth - totalSpacing) / 4;
        final responsiveFieldSize = fieldWidth.clamp(50.0, 70.0);
        
        return LayoutBuilder(
          builder: (context, constraints) {
            final actualWidth = constraints.maxWidth > 0 
                ? constraints.maxWidth.clamp(50.0, 70.0)
                : responsiveFieldSize;
            final actualHeight = actualWidth * 1.2;
            
            return Container(
              width: actualWidth,
              height: actualHeight,
              margin: EdgeInsets.only(
                right: index < 3 ? spacing : 0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: (_colorAnimation.value ?? const Color(0xFFFFD700))
                              .withOpacity(0.3 * _glowAnimation.value),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.2 * _glowAnimation.value),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.gray300.withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                obscureText: true,
                obscuringCharacter: '●',
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                cursorColor: AppColors.textPrimaryLight,
                cursorWidth: 2,
                style: GoogleFonts.inter(
                  fontSize: actualWidth * 0.55,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                  letterSpacing: 0,
                  height: 1.2,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.gray500,
                      width: 2.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.gray500,
                      width: 2.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _colorAnimation.value ?? const Color(0xFFFFD700),
                      width: 3,
                    ),
                  ),
                ),
                onChanged: (value) => _onPinDialogChanged(
                  index,
                  value,
                  isConfirm ? _confirmPinDialogControllers : _pinDialogControllers,
                  isConfirm ? _confirmPinDialogFocusNodes : _pinDialogFocusNodes,
                  isConfirm: isConfirm,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _savePinDialog() async {
    final pin = _getPinDialogValue(_pinDialogControllers);
    final confirmPin = _getPinDialogValue(_confirmPinDialogControllers);

    if (pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le code PIN doit contenir 4 chiffres'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (pin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les codes PIN ne correspondent pas'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Vérifier si le PIN est le PIN par défaut
    if (pin == '1234') {
      _showDefaultPinRejectedDialog();
      return;
    }

    try {
      final user = widget.authController.currentUser;
      if (user == null) return;

      await FirebaseService.firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'pin': pin,
        'isDefaultPin': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Réinitialiser les champs
      for (var controller in _pinDialogControllers) {
        controller.clear();
      }
      for (var controller in _confirmPinDialogControllers) {
        controller.clear();
      }

      if (mounted) {
        Navigator.pop(context); // Fermer le dialogue de modification
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code PIN modifié avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDefaultPinRejectedDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.white,
                    AppColors.offWhite,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warning.withOpacity(0.2 * _glowAnimation.value),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header avec icône animée
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm + 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.warning.withOpacity(0.3 * _glowAnimation.value),
                                blurRadius: 15,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.block,
                            color: AppColors.warning,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'PIN non autorisé',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryLight,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Message principal
                    Text(
                      'Le code PIN "1234" est le code par défaut et ne peut pas être utilisé comme nouveau code PIN.',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Carte d'information
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.warning.withOpacity(0.15),
                            AppColors.warning.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warning.withOpacity(0.1 * _glowAnimation.value),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.warning,
                            size: 24,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pourquoi ?',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.warning,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Pour des raisons de sécurité, vous devez choisir un code PIN différent du code par défaut. Veuillez choisir un code PIN unique et personnel.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.warning,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Bouton
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.warning,
                              Colors.orange[700]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warning.withOpacity(0.4 * _glowAnimation.value),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Réinitialiser les champs PIN
                            for (var controller in _pinDialogControllers) {
                              controller.clear();
                            }
                            for (var controller in _confirmPinDialogControllers) {
                              controller.clear();
                            }
                            // Remettre le focus sur le premier champ
                            _pinDialogFocusNodes[0].requestFocus();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.refresh, color: AppColors.white, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Réessayer',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.white,
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
        },
      ),
    );
  }

  void _showModifyPinDialog() {
    // Réinitialiser les champs
    for (var controller in _pinDialogControllers) {
      controller.clear();
    }
    for (var controller in _confirmPinDialogControllers) {
      controller.clear();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.white,
                    AppColors.offWhite,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_colorAnimation.value ?? const Color(0xFFFFD700))
                        .withOpacity(0.2 * _glowAnimation.value),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm + 2),
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
                                      .withOpacity(0.3 * _glowAnimation.value),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lock_reset,
                              color: AppColors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Modifier le code PIN',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryLight,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Nouveau PIN
                      Text(
                        'Nouveau code PIN',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          4,
                          (index) => Flexible(
                            child: _buildDialogPINField(
                              index,
                              _pinDialogControllers[index],
                              _pinDialogFocusNodes[index],
                              isConfirm: false,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Confirmer PIN
                      Text(
                        'Confirmer le code PIN',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          4,
                          (index) => Flexible(
                            child: _buildDialogPINField(
                              index,
                              _confirmPinDialogControllers[index],
                              _confirmPinDialogFocusNodes[index],
                              isConfirm: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Boutons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // Réinitialiser les champs
                                for (var controller in _pinDialogControllers) {
                                  controller.clear();
                                }
                                for (var controller in _confirmPinDialogControllers) {
                                  controller.clear();
                                }
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: AppColors.gray400,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                              ),
                              child: Text(
                                'Annuler',
                                style: GoogleFonts.inter(
                                  color: AppColors.gray600,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _colorAnimation.value ?? const Color(0xFFFFD700),
                                    const Color(0xFFFF6B35),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_colorAnimation.value ?? const Color(0xFFFFD700))
                                        .withOpacity(0.4 * _glowAnimation.value),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _savePinDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.save, color: AppColors.white, size: 20),
                                    const SizedBox(width: AppSpacing.sm),
                                    Flexible(
                                      child: Text(
                                        'Sauvegarder',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: AppColors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showModifiedPinDialog() {
    // Réinitialiser les champs de connexion
    for (var controller in _loginPinControllers) {
      controller.clear();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        // Auto-focus sur le premier champ après un court délai
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _loginPinFocusNodes[0].requestFocus();
          }
        });
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.white,
                      AppColors.offWhite,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_colorAnimation.value ?? const Color(0xFFFFD700))
                          .withOpacity(0.2 * _glowAnimation.value),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Header avec icône animée
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm + 2),
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
                                    .withOpacity(0.3 * _glowAnimation.value),
                                blurRadius: 15,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock,
                            color: AppColors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Se connecter avec votre code PIN',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryLight,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Champ Code PIN
                    Text(
                      'Code PIN',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        4,
                        (index) => Flexible(
                          child: _buildLoginPINField(
                            index,
                            _loginPinControllers[index],
                            _loginPinFocusNodes[index],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Boutons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Réinitialiser les champs
                              for (var controller in _loginPinControllers) {
                                controller.clear();
                              }
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppColors.gray400,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            ),
                            child: Text(
                              'Annuler',
                              style: GoogleFonts.inter(
                                color: AppColors.gray600,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _colorAnimation.value ?? const Color(0xFFFFD700),
                                  const Color(0xFFFF6B35),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                              boxShadow: [
                                BoxShadow(
                                  color: (_colorAnimation.value ?? const Color(0xFFFFD700))
                                      .withOpacity(0.4 * _glowAnimation.value),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () => _verifyLoginPin(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.arrow_forward, color: AppColors.white, size: 20),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Continuer',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Bouton discret "Changer le code PIN"
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showChangePinDialog();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        child: Text(
                          'Changer le code PIN',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.gray600,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.gray600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _verifyLoginPin() async {
    final enteredPin = _getPinDialogValue(_loginPinControllers);

    if (enteredPin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer votre code PIN complet'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final user = widget.authController.currentUser;
      if (user == null) return;

      // Récupérer le PIN depuis Firestore
      final doc = await FirebaseService.firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        _showErrorDialog('Profil utilisateur introuvable.');
        return;
      }

      final profileData = doc.data();
      final storedPin = profileData?['pin']?.toString() ?? '';

      if (enteredPin == storedPin) {
        // PIN correct, fermer le dialogue et ouvrir la page annonceur
        for (var controller in _loginPinControllers) {
          controller.clear();
        }
        if (mounted) {
          Navigator.pop(context);
          // Navigate to advertiser management page
          Navigator.pushNamed(context, AppRoutes.advertiserManagement);
        }
      } else {
        // PIN incorrect
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code PIN incorrect. Veuillez réessayer.'),
            backgroundColor: AppColors.error,
          ),
        );
        // Réinitialiser les champs
        for (var controller in _loginPinControllers) {
          controller.clear();
        }
        _loginPinFocusNodes[0].requestFocus();
      }
    } catch (e) {
      _showErrorDialog('Erreur lors de la vérification: $e');
    }
  }

  void _showChangePinDialog() {
    // Réinitialiser tous les champs
    for (var controller in _oldPinControllers) {
      controller.clear();
    }
    for (var controller in _newPinControllers) {
      controller.clear();
    }
    for (var controller in _confirmNewPinControllers) {
      controller.clear();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.white,
                    AppColors.offWhite,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_colorAnimation.value ?? const Color(0xFFFFD700))
                        .withOpacity(0.2 * _glowAnimation.value),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm + 2),
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
                                      .withOpacity(0.3 * _glowAnimation.value),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lock_reset,
                              color: AppColors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Changer le code PIN',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryLight,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Ancien PIN
                      Text(
                        'Ancien code PIN',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          4,
                          (index) => Flexible(
                            child: _buildChangePinField(
                              index,
                              _oldPinControllers[index],
                              _oldPinFocusNodes[index],
                              isOldPin: true,
                              focusNodesList: _oldPinFocusNodes,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Nouveau PIN
                      Text(
                        'Nouveau code PIN',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          4,
                          (index) => Flexible(
                            child: _buildChangePinField(
                              index,
                              _newPinControllers[index],
                              _newPinFocusNodes[index],
                              isOldPin: false,
                              focusNodesList: _newPinFocusNodes,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Confirmer nouveau PIN
                      Text(
                        'Confirmer le nouveau code PIN',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          4,
                          (index) => Flexible(
                            child: _buildChangePinField(
                              index,
                              _confirmNewPinControllers[index],
                              _confirmNewPinFocusNodes[index],
                              isOldPin: false,
                              focusNodesList: _confirmNewPinFocusNodes,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Boutons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // Réinitialiser les champs
                                for (var controller in _oldPinControllers) {
                                  controller.clear();
                                }
                                for (var controller in _newPinControllers) {
                                  controller.clear();
                                }
                                for (var controller in _confirmNewPinControllers) {
                                  controller.clear();
                                }
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: AppColors.gray400,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: 4),
                              ),
                              child: Text(
                                'Annuler',
                                style: GoogleFonts.inter(
                                  color: AppColors.gray600,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _colorAnimation.value ?? const Color(0xFFFFD700),
                                    const Color(0xFFFF6B35),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_colorAnimation.value ?? const Color(0xFFFFD700))
                                        .withOpacity(0.4 * _glowAnimation.value),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _saveChangePin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: 4),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Sauvegarder',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChangePinField(int index, TextEditingController controller, FocusNode focusNode, {required bool isOldPin, required List<FocusNode> focusNodesList}) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final isFocused = focusNode.hasFocus;
        final size = MediaQuery.of(context).size;
        final dialogPadding = 32.0;
        final availableWidth = size.width - dialogPadding;
        final spacing = 8.0;
        final totalSpacing = spacing * 3;
        final fieldWidth = (availableWidth - totalSpacing) / 4;
        final responsiveFieldSize = fieldWidth.clamp(50.0, 70.0);
        
        return LayoutBuilder(
          builder: (context, constraints) {
            final actualWidth = constraints.maxWidth > 0 
                ? constraints.maxWidth.clamp(50.0, 70.0)
                : responsiveFieldSize;
            final actualHeight = actualWidth * 1.2;
            
            return Container(
              width: actualWidth,
              height: actualHeight,
              margin: EdgeInsets.only(
                right: index < 3 ? spacing : 0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: (_colorAnimation.value ?? const Color(0xFFFFD700))
                              .withOpacity(0.3 * _glowAnimation.value),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.2 * _glowAnimation.value),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.gray300.withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                obscureText: true,
                obscuringCharacter: '●',
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                cursorColor: AppColors.textPrimaryLight,
                cursorWidth: 2,
                style: GoogleFonts.inter(
                  fontSize: actualWidth * 0.55,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                  letterSpacing: 0,
                  height: 1.2,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.gray500,
                      width: 2.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.gray500,
                      width: 2.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _colorAnimation.value ?? const Color(0xFFFFD700),
                      width: 3,
                    ),
                  ),
                ),
                onChanged: (value) => _onChangePinChanged(
                  index,
                  value,
                  focusNodesList,
                  isOldPin: isOldPin,
                  isNewPin: !isOldPin && focusNodesList == _newPinFocusNodes,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onChangePinChanged(int index, String value, List<FocusNode> focusNodes, {bool isOldPin = false, bool isNewPin = false}) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // Move to next field if digit entered
      if (value.length == 1 && index < 3) {
        // Add a small delay to ensure the DOM is ready on web
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && focusNodes[index + 1].canRequestFocus) {
            // Unfocus current field first
            focusNodes[index].unfocus();
            // Then focus next field after a microtask
            Future.microtask(() {
              if (mounted && focusNodes[index + 1].canRequestFocus) {
                focusNodes[index + 1].requestFocus();
              }
            });
          }
        });
      }
      // Move to previous field if deleted
      else if (value.isEmpty && index > 0) {
        // Add a small delay to ensure the DOM is ready on web
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && focusNodes[index - 1].canRequestFocus) {
            // Unfocus current field first
            focusNodes[index].unfocus();
            // Then focus previous field after a microtask
            Future.microtask(() {
              if (mounted && focusNodes[index - 1].canRequestFocus) {
                focusNodes[index - 1].requestFocus();
              }
            });
          }
        });
      }
      // Si tous les champs sont remplis, passer au groupe suivant
      else if (value.length == 1 && index == 3) {
        // Vérifier si tous les champs sont remplis
        bool allFilled = true;
        for (int i = 0; i < 4; i++) {
          if (focusNodes[i].hasFocus) {
            // Vérifier le contrôleur correspondant
            TextEditingController? controller;
            if (isOldPin) {
              controller = _oldPinControllers[i];
            } else if (isNewPin) {
              controller = _newPinControllers[i];
            } else {
              controller = _confirmNewPinControllers[i];
            }
            if (controller.text.isEmpty) {
              allFilled = false;
              break;
            }
          }
        }
        
        if (allFilled) {
          // Add a delay before moving to next group
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              // Unfocus current field first
              focusNodes[index].unfocus();
              // Then focus first field of next group after a microtask
              Future.microtask(() {
                if (mounted) {
                  // Passer au groupe suivant
                  if (isOldPin) {
                    _newPinFocusNodes[0].requestFocus();
                  } else if (isNewPin) {
                    _confirmNewPinFocusNodes[0].requestFocus();
                  }
                }
              });
            }
          });
        }
      }
    });
  }

  Future<void> _saveChangePin() async {
    final oldPin = _getPinDialogValue(_oldPinControllers);
    final newPin = _getPinDialogValue(_newPinControllers);
    final confirmNewPin = _getPinDialogValue(_confirmNewPinControllers);

    if (oldPin.length != 4 || newPin.length != 4 || confirmNewPin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tous les champs doivent être remplis'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (newPin != confirmNewPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les nouveaux codes PIN ne correspondent pas'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (newPin == '1234') {
      _showDefaultPinRejectedDialog();
      return;
    }

    try {
      final user = widget.authController.currentUser;
      if (user == null) return;

      // Vérifier l'ancien PIN
      final doc = await FirebaseService.firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        _showErrorDialog('Profil utilisateur introuvable.');
        return;
      }

      final profileData = doc.data();
      final storedPin = profileData?['pin']?.toString() ?? '';

      if (oldPin != storedPin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ancien code PIN incorrect'),
            backgroundColor: AppColors.error,
          ),
        );
        // Réinitialiser seulement l'ancien PIN
        for (var controller in _oldPinControllers) {
          controller.clear();
        }
        _oldPinFocusNodes[0].requestFocus();
        return;
      }

      // Sauvegarder le nouveau PIN
      await FirebaseService.firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'pin': newPin,
        'isDefaultPin': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Réinitialiser tous les champs
      for (var controller in _oldPinControllers) {
        controller.clear();
      }
      for (var controller in _newPinControllers) {
        controller.clear();
      }
      for (var controller in _confirmNewPinControllers) {
        controller.clear();
      }

      if (mounted) {
        Navigator.pop(context); // Fermer le dialogue de changement
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code PIN modifié avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Code PIN configuré',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre code PIN a été modifié avec succès.',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Vous pouvez maintenant créer des annonces en toute sécurité.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.success,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(
                color: AppColors.gray600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Ouvrir la page annonceur
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
            ),
            child: Text(
              'Continuer',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
