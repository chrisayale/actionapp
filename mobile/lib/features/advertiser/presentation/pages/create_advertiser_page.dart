import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../auth/auth_controller.dart';

/// Multi-step registration form for creating a new advertiser establishment
class CreateAdvertiserPage extends StatefulWidget {
  final AuthController authController;

  const CreateAdvertiserPage({
    super.key,
    required this.authController,
  });

  @override
  State<CreateAdvertiserPage> createState() => _CreateAdvertiserPageState();
}

class _CreateAdvertiserPageState extends State<CreateAdvertiserPage>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form controllers
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Form keys for validation
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  String? _selectedCategory;

  final List<String> _categories = [
    'Restaurant',
    'Bar',
    'Café',
    'Night Club',
    'Hôtel',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().isNotEmpty &&
            _locationController.text.trim().isNotEmpty;
      case 1:
        return _phoneController.text.trim().isNotEmpty;
      case 2:
        return _selectedCategory != null;
      default:
        return false;
    }
  }

  void _continue() {
    switch (_currentStep) {
      case 0:
        if (_step1Key.currentState?.validate() ?? false) {
          _goToStep(1);
        }
        break;
      case 1:
        if (_step2Key.currentState?.validate() ?? false) {
          _goToStep(2);
        }
        break;
      case 2:
        if (_step3Key.currentState?.validate() ?? false) {
          _submitForm();
        }
        break;
    }
  }

  void _goToStep(int step) {
    _animationController.reverse().then((_) {
      setState(() {
        _currentStep = step;
      });
      _animationController.forward();
    });
  }

  void _goBack() {
    if (_currentStep > 0) {
      _animationController.reverse().then((_) {
        setState(() {
          _currentStep--;
        });
        _animationController.forward();
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submitForm() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual submission to backend/Firestore
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Établissement créé avec succès',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            margin: const EdgeInsets.all(AppSpacing.md),
          ),
        );

        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur lors de la création: ${e.toString()}',
                    style: GoogleFonts.inter(),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            margin: const EdgeInsets.all(AppSpacing.md),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(
          'Créer un annonceur',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimaryLight),
          onPressed: _isLoading ? null : _goBack,
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.yellowPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Création en cours...',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Progress indicator
                _buildProgressIndicator(),
                // Content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                      child: _buildStepContent(),
                    ),
                  ),
                ),
                // Bottom navigation
                _buildBottomNavigation(),
              ],
            ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(3, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        decoration: BoxDecoration(
                          color: isCompleted || isCurrent
                              ? AppColors.yellowPrimary
                              : AppColors.gray200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (index < 2) const SizedBox(width: 8),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepLabel(0, 'Informations'),
              _buildStepLabel(1, 'Coordonnées'),
              _buildStepLabel(2, 'Détails'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepLabel(int stepIndex, String label) {
    final isCompleted = stepIndex < _currentStep;
    final isCurrent = stepIndex == _currentStep;
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: isCurrent || isCompleted ? FontWeight.w600 : FontWeight.w400,
        color: isCurrent || isCompleted
            ? AppColors.yellowPrimary
            : AppColors.textTertiaryLight,
      ),
      child: Text(label),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          _buildSectionHeader(
            icon: Icons.business_rounded,
            title: 'Informations de base',
            subtitle: 'Renseignez les informations principales de votre établissement',
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildTextField(
            controller: _nameController,
            label: 'Nom de l\'établissement',
            hint: 'Ex: RDC BAR',
            icon: Icons.store_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer le nom de l\'établissement';
              }
              if (value.trim().length < 3) {
                return 'Le nom doit contenir au moins 3 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildTextField(
            controller: _locationController,
            label: 'Localisation',
            hint: 'Ex: KAVA/GOMBE, Kinshasa',
            icon: Icons.location_on_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer la localisation';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _step2Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          _buildSectionHeader(
            icon: Icons.contact_phone_rounded,
            title: 'Coordonnées',
            subtitle: 'Comment pouvez-vous être contacté ?',
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildTextField(
            controller: _phoneController,
            label: 'Numéro de téléphone',
            hint: '+243 900 000 000',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer un numéro de téléphone';
              }
              final phoneRegex = RegExp(r'^\+?[0-9\s\-]{8,}$');
              if (!phoneRegex.hasMatch(value.trim())) {
                return 'Veuillez entrer un numéro valide';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildTextField(
            controller: _emailController,
            label: 'Email (optionnel)',
            hint: 'contact@exemple.com',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final emailRegex = RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                );
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Veuillez entrer un email valide';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Form(
      key: _step3Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          _buildSectionHeader(
            icon: Icons.info_outline_rounded,
            title: 'Détails supplémentaires',
            subtitle: 'Ajoutez des informations complémentaires',
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildDropdownField(
            label: 'Catégorie',
            hint: 'Sélectionner une catégorie',
            icon: Icons.category_rounded,
            value: _selectedCategory,
            items: _categories,
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez sélectionner une catégorie';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description (optionnel)',
            hint: 'Décrivez votre établissement...',
            icon: Icons.description_rounded,
            maxLines: 5,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.yellowPrimary,
                AppColors.yellowPrimary.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: AppColors.yellowPrimary.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: AppColors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          onChanged: (_) => setState(() {}), // Rebuild to update button state
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: AppColors.textTertiaryLight,
            ),
            prefixIcon: Icon(
              icon,
              color: AppColors.yellowPrimary,
              size: 22,
            ),
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              borderSide: const BorderSide(
                color: AppColors.yellowPrimary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.inputPadding),
          ),
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: AppColors.textTertiaryLight,
            ),
            prefixIcon: Icon(
              icon,
              color: AppColors.yellowPrimary,
              size: 22,
            ),
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              borderSide: const BorderSide(
                color: AppColors.yellowPrimary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.inputPadding),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            onChanged(newValue);
            setState(() {}); // Rebuild to update button state
          },
          validator: validator,
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: AppColors.textTertiaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
        top: AppSpacing.md,
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _goBack,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.gray300,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md + 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_back_ios_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Précédent',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: _currentStep > 0 ? 1 : 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
                  boxShadow: _canContinue
                      ? [
                          BoxShadow(
                            color: AppColors.yellowPrimary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: ElevatedButton(
                  onPressed: _canContinue ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellowPrimary,
                    foregroundColor: AppColors.textPrimaryLight,
                    disabledBackgroundColor: AppColors.gray300,
                    disabledForegroundColor: AppColors.gray500,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md + 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep < 2 ? 'Suivant' : 'Créer',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (_currentStep < 2) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                      ] else ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle_outline, size: 20),
                      ],
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
}
