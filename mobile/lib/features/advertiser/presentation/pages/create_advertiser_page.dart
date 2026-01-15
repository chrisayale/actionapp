import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../auth/auth_controller.dart';
import '../../../../core/services/permission_service.dart';
import '../../data/repositories/advertiser_repository.dart';

/// Multi-step registration form for creating a new advertiser establishment
class CreateAdvertiserPage extends StatefulWidget {
  final AuthController authController;

  const CreateAdvertiserPage({super.key, required this.authController});

  @override
  State<CreateAdvertiserPage> createState() => _CreateAdvertiserPageState();
}

class _CreateAdvertiserPageState extends State<CreateAdvertiserPage>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final AdvertiserRepository _repository = AdvertiserRepository();

  // Form controllers
  final _nameController = TextEditingController();
  final _quartierController = TextEditingController();
  final _avenueController = TextEditingController();
  final _numeroController = TextEditingController();

  // Form keys for validation
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  // Dropdown values
  String? _selectedType;
  String? _selectedVille;

  // Image files
  Uint8List? _logoImageBytes;
  Uint8List? _enseigneImageBytes;
  Uint8List? _documentImageBytes;

  // Location
  double? _latitude;
  double? _longitude;

  // Lists
  final List<String> _establishmentTypes = [
    'Bar',
    'Terrasse',
    'Restaurant',
    'Club',
    'Hôtel',
    'Café',
    'Autre',
  ];

  final List<String> _villes = [
    'Kinshasa',
    'Lubumbashi',
    'Mbuji-Mayi',
    'Kisangani',
    'Kananga',
    'Bukavu',
    'Goma',
    'Matadi',
    'Kolwezi',
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
    _quartierController.dispose();
    _avenueController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    switch (_currentStep) {
      case 0:
        return _selectedType != null &&
            _nameController.text.trim().isNotEmpty &&
            _logoImageBytes != null &&
            _enseigneImageBytes != null;
      case 1:
        return _selectedVille != null &&
            _quartierController.text.trim().isNotEmpty &&
            _avenueController.text.trim().isNotEmpty &&
            _numeroController.text.trim().isNotEmpty &&
            _latitude != null &&
            _longitude != null;
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

  Future<void> _pickImage(
    ImageSource source,
    Function(Uint8List) onImagePicked,
  ) async {
    // Check permissions
    bool hasPermission = false;
    if (source == ImageSource.camera) {
      hasPermission = await PermissionService.isCameraPermissionGranted();
      if (!hasPermission) {
        hasPermission = await PermissionService.requestCameraPermission();
      }
    } else {
      hasPermission = await PermissionService.isPhotoLibraryPermissionGranted();
      if (!hasPermission) {
        hasPermission = await PermissionService.requestPhotoLibraryPermission();
      }
    }

    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    source == ImageSource.camera
                        ? 'Permission de la caméra requise'
                        : 'Permission de la galerie requise',
                    style: GoogleFonts.inter(),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
          ),
        );
      }
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: kIsWeb ? null : 1200,
        maxHeight: kIsWeb ? null : 1200,
      );

      if (image != null) {
        Uint8List? imageBytes;

        if (kIsWeb) {
          // Sur le web, lire directement les bytes sans compression
          imageBytes = await image.readAsBytes();
        } else {
          // Sur mobile, compresser l'image
          try {
            imageBytes = await FlutterImageCompress.compressWithFile(
              image.path,
              minWidth: 1200,
              minHeight: 1200,
              quality: 85,
            );
          } catch (compressError) {
            if (kDebugMode) {
              print(
                'Erreur de compression, utilisation de l\'image originale: $compressError',
              );
            }
            // En cas d'erreur de compression, utiliser l'image originale
            imageBytes = await image.readAsBytes();
          }
        }

        if (imageBytes != null) {
          onImagePicked(imageBytes);
          setState(() {});
        }
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
                    'Erreur lors de la sélection: ${e.toString()}',
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
          ),
        );
      }
    }
  }

  Future<void> _showImageSourceDialog(Function(Uint8List) onImagePicked) async {
    await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXLarge),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.md,
                ),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'Choisir une source',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.info),
                ),
                title: Text(
                  'Galerie',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Choisir depuis vos photos',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, onImagePicked);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.success),
                ),
                title: Text(
                  'Caméra',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Prendre une nouvelle photo',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, onImagePicked);
                },
              ),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickLocation() async {
    // Request location permission
    bool hasPermission = await PermissionService.isLocationPermissionGranted();
    if (!hasPermission) {
      hasPermission = await PermissionService.requestLocationPermission();
    }

    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Permission de localisation requise',
                    style: GoogleFonts.inter(),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
          ),
        );
      }
      return;
    }

    // Mock implementation - show dialog for location picker
    // In a real app, you would open a map picker here
    final result = await showDialog<Map<String, double>>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon and title
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.yellowPrimary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.radiusXLarge),
                    topRight: Radius.circular(AppSpacing.radiusXLarge),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.yellowPrimary,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMedium,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.yellowPrimary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.map_rounded,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Localisation',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: AppColors.textPrimaryLight,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fonctionnalité de sélection de carte',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'À implémenter.\n\nPour l\'instant, utilisez un point de localisation par défaut.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.textSecondaryLight,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.gray300,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMedium,
                            ),
                          ),
                        ),
                        child: Text(
                          'Annuler',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMedium,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.yellowPrimary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            // Mock coordinates (Kinshasa center)
                            Navigator.pop(context, {
                              'latitude': -4.3276,
                              'longitude': 15.3136,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.yellowPrimary,
                            foregroundColor: AppColors.textPrimaryLight,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMedium,
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Utiliser la localisation',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
      });
    }
  }

  Future<void> _submitForm() async {
    if (kDebugMode) {
      print('🚀 [CreateAdvertiserPage] Form submission started');
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_logoImageBytes == null || _enseigneImageBytes == null) {
        throw Exception('Logo et image enseigne sont requis');
      }

      if (_latitude == null || _longitude == null) {
        throw Exception('Localisation requise');
      }

      if (kDebugMode) {
        print(
          '✅ [CreateAdvertiserPage] Validation passed, calling repository...',
        );
      }

      await _repository.createEstablishment(
        type: _selectedType!,
        name: _nameController.text.trim(),
        logoImageBytes: _logoImageBytes!,
        enseigneImageBytes: _enseigneImageBytes!,
        documentImageBytes: _documentImageBytes,
        ville: _selectedVille!,
        quartier: _quartierController.text.trim(),
        avenue: _avenueController.text.trim(),
        numero: _numeroController.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
      );

      if (kDebugMode) {
        print('✅ [CreateAdvertiserPage] Establishment created successfully');
      }

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
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        // Extract a user-friendly error message
        String errorMessage = e.toString();
        
        // If it's a timeout or connection error, show a simplified message
        if (errorMessage.contains('Timeout') || 
            errorMessage.contains('Impossible de se connecter')) {
          errorMessage = 'Impossible de se connecter au serveur.\n\n'
              '⚠️ Solution: Configurez le firewall Windows.\n'
              'Voir: backend\\QUICK_FIX.md';
        } else {
          // For other errors, show the first line only
          final lines = errorMessage.split('\n');
          errorMessage = lines.isNotEmpty ? lines[0] : errorMessage;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Erreur lors de la création',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                if (errorMessage.contains('firewall') || 
                    errorMessage.contains('Timeout'))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '💡 Ouvrez PowerShell en tant qu\'administrateur et exécutez:\n'
                      '   .\\backend\\add_firewall_rule.ps1',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 8),
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
      backgroundColor: AppColors.backgroundSecondaryLight,
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
                _buildProgressIndicator(),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(
                        AppSpacing.screenHorizontal,
                      ),
                      child: _buildStepContent(),
                    ),
                  ),
                ),
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
            children: List.generate(2, (index) {
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
                    if (index < 1) const SizedBox(width: 8),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: _buildStepLabel(0, 'Établissement'),
              ),
              Flexible(
                child: _buildStepLabel(1, 'Localisation'),
              ),
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
        fontSize: 13,
        fontWeight: isCurrent || isCompleted
            ? FontWeight.w600
            : FontWeight.w400,
        color: isCurrent || isCompleted
            ? AppColors.yellowPrimary
            : AppColors.textTertiaryLight,
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
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
            title: 'Informations de l\'établissement',
            subtitle: 'Renseignez les informations principales',
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildDropdownField(
            label: 'Type d\'établissement',
            hint: 'Sélectionner un type',
            icon: Icons.category_rounded,
            value: _selectedType,
            items: _establishmentTypes,
            required: true,
            onChanged: (value) {
              setState(() {
                _selectedType = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez sélectionner un type d\'établissement';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildTextField(
            controller: _nameController,
            label: 'Nom de l\'établissement',
            hint: 'Ex: RDC BAR',
            icon: Icons.store_rounded,
            required: true,
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
          _buildImagePickerField(
            label: 'Logo',
            icon: Icons.image_rounded,
            imageBytes: _logoImageBytes,
            required: true,
            onImagePicked: (bytes) {
              setState(() {
                _logoImageBytes = bytes;
              });
            },
            validator: () {
              if (_logoImageBytes == null) {
                return 'Veuillez sélectionner un logo';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildImagePickerField(
            label: 'Image marque / enseigne',
            icon: Icons.storefront_rounded,
            imageBytes: _enseigneImageBytes,
            required: true,
            onImagePicked: (bytes) {
              setState(() {
                _enseigneImageBytes = bytes;
              });
            },
            validator: () {
              if (_enseigneImageBytes == null) {
                return 'Veuillez sélectionner une image d\'enseigne';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildImagePickerField(
            label: 'Document',
            subtitle: 'RCCM / ID National / Patente',
            icon: Icons.description_rounded,
            imageBytes: _documentImageBytes,
            required: false,
            onImagePicked: (bytes) {
              setState(() {
                _documentImageBytes = bytes;
              });
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
            icon: Icons.location_on_rounded,
            title: 'Informations de localisation',
            subtitle: 'Où se trouve votre établissement ?',
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildDropdownField(
            label: 'Ville',
            hint: 'Sélectionner une ville',
            icon: Icons.location_city_rounded,
            value: _selectedVille,
            items: _villes,
            required: true,
            onChanged: (value) {
              setState(() {
                _selectedVille = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez sélectionner une ville';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildTextField(
            controller: _quartierController,
            label: 'Quartier / Commune',
            hint: 'Ex: GOMBE',
            icon: Icons.apartment_rounded,
            required: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer le quartier/commune';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildTextField(
            controller: _avenueController,
            label: 'Avenue',
            hint: 'Ex: Avenue de la République',
            icon: Icons.signpost_rounded,
            required: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer l\'avenue';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildTextField(
            controller: _numeroController,
            label: 'Numéro',
            hint: 'Ex: 123',
            icon: Icons.numbers_rounded,
            keyboardType: TextInputType.number,
            required: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer le numéro';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildLocationPickerField(),
          const SizedBox(height: AppSpacing.lg),
          _buildInfoCard(),
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
          child: Icon(icon, color: AppColors.white, size: 24),
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
    required bool required,
    String? Function(String?)? validator,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (required) ...[
                  const SizedBox(width: 4),
                  Text(
                    '*',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textTertiaryLight,
                  fontSize: 14,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.yellowPrimary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.textPrimaryLight,
                    size: 18,
                  ),
                ),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 4,
                  vertical: AppSpacing.sm + 4,
                ),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required bool required,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (required) ...[
                  const SizedBox(width: 4),
                  Text(
                    '*',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: value,
              dropdownColor: AppColors.white,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textTertiaryLight,
                  fontSize: 14,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.yellowPrimary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.textPrimaryLight,
                    size: 18,
                  ),
                ),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 4,
                  vertical: AppSpacing.sm + 4,
                ),
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                onChanged(newValue);
                setState(() {});
              },
              validator: validator,
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                color: AppColors.textTertiaryLight,
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerField({
    required String label,
    String? subtitle,
    required IconData icon,
    required Uint8List? imageBytes,
    required bool required,
    required Function(Uint8List) onImagePicked,
    String? Function()? validator,
  }) {
    final errorMessage = validator?.call();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (required) ...[
                  const SizedBox(width: 4),
                  Text(
                    '*',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () => _showImageSourceDialog(onImagePicked),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  border: Border.all(
                    color: errorMessage != null
                        ? AppColors.error
                        : AppColors.gray200.withOpacity(0.5),
                    width: errorMessage != null ? 2 : 1,
                  ),
                ),
                child: imageBytes == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: AppColors.yellowPrimary, size: 48),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Appuyez pour sélectionner',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMedium,
                        ),
                        child: Image.memory(
                          imageBytes,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 150,
                        ),
                      ),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                errorMessage,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPickerField() {
    final hasLocation = _latitude != null && _longitude != null;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Localisation sur la carte',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickLocation,
                icon: Icon(
                  hasLocation ? Icons.check_circle : Icons.map_rounded,
                  size: 20,
                ),
                label: Text(
                  hasLocation
                      ? 'Localisation définie'
                      : 'Prendre la localisation sur la carte',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasLocation
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.yellowPrimary,
                  foregroundColor: hasLocation
                      ? AppColors.success
                      : AppColors.textPrimaryLight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                    side: hasLocation
                        ? const BorderSide(color: AppColors.success, width: 1.5)
                        : BorderSide.none,
                  ),
                  elevation: 0,
                ),
              ),
            ),
            if (_latitude != null && _longitude != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Lat: $_latitude, Long: $_longitude',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.info.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.info,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conseil',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Il est conseillé de prendre la localisation sur la carte lorsque vous êtes physiquement sur votre lieu de travail.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimaryLight,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusXLarge,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_ios_rounded, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Précédent',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
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
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusXLarge,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _currentStep < 1 ? 'Suivant' : 'Créer',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (_currentStep < 1) ...[
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
