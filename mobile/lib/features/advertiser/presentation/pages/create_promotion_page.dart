import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/permission_service.dart';
import '../../data/repositories/advertiser_repository.dart';

/// Model for drink/beverage
class DrinkModel {
  final String id;
  final String name;
  final String? imageUrl;
  final String? size; // e.g., "72cl", "33cl"

  DrinkModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.size,
  });

  String get displayName {
    if (size != null && size!.isNotEmpty) {
      return '$name $size';
    }
    return name;
  }
}

/// Page for creating a new promotion
class CreatePromotionPage extends StatefulWidget {
  final String? establishmentId;
  final String? establishmentName;
  final String? enseigneUrl;
  final String? logoUrl;

  const CreatePromotionPage({
    super.key,
    this.establishmentId,
    this.establishmentName,
    this.enseigneUrl,
    this.logoUrl,
  });

  @override
  State<CreatePromotionPage> createState() => _CreatePromotionPageState();
}

class _CreatePromotionPageState extends State<CreatePromotionPage> {
  final _formKey = GlobalKey<FormState>();
  final _formuleController = TextEditingController();
  final AdvertiserRepository _repository = AdvertiserRepository();

  // Mock list of drinks - In production, this would come from API
  final List<DrinkModel> _drinks = [
    DrinkModel(
      id: '1',
      name: 'Primus',
      size: '72cl',
      imageUrl: null, // Will use placeholder
    ),
    DrinkModel(
      id: '2',
      name: 'Primus',
      size: '33cl',
      imageUrl: null,
    ),
    DrinkModel(
      id: '3',
      name: 'Tembo',
      size: '72cl',
      imageUrl: null,
    ),
    DrinkModel(
      id: '4',
      name: 'Tembo',
      size: '33cl',
      imageUrl: null,
    ),
    DrinkModel(
      id: '5',
      name: 'Mützig',
      size: '72cl',
      imageUrl: null,
    ),
    DrinkModel(
      id: '6',
      name: 'Mützig',
      size: '33cl',
      imageUrl: null,
    ),
    DrinkModel(
      id: '7',
      name: 'Turbo King',
      size: '72cl',
      imageUrl: null,
    ),
    DrinkModel(
      id: '8',
      name: 'Turbo King',
      size: '33cl',
      imageUrl: null,
    ),
  ];

  DrinkModel? _selectedDrink;
  Uint8List? _promotionImageBytes;
  String? _defaultImageUrl; // URL de l'image par défaut (enseigne)
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isUnlimited = false; // Promotion continue (sans limite)
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set default image URL if provided
    if (widget.enseigneUrl != null && widget.enseigneUrl!.isNotEmpty) {
      _defaultImageUrl = widget.enseigneUrl;
    }
  }

  @override
  void dispose() {
    _formuleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
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
          imageBytes = await image.readAsBytes();
        } else {
          try {
            imageBytes = await FlutterImageCompress.compressWithFile(
              image.path,
              minWidth: 1200,
              minHeight: 1200,
              quality: 85,
            );
          } catch (compressError) {
            if (kDebugMode) {
              print('Erreur de compression, utilisation de l\'image originale: $compressError');
            }
            imageBytes = await image.readAsBytes();
          }
        }

        if (imageBytes != null) {
          setState(() {
            _promotionImageBytes = imageBytes;
          });
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

  Future<void> _showImageSourceDialog() async {
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
                margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
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
                  _pickImage(ImageSource.gallery);
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
                  _pickImage(ImageSource.camera);
                },
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now().add(const Duration(days: 7))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.yellowPrimary,
              onPrimary: AppColors.textPrimaryLight,
              surface: AppColors.white,
              onSurface: AppColors.textPrimaryLight,
            ),
            dialogBackgroundColor: AppColors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If end date is before new start date, reset it
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Establishment is required
    if (widget.establishmentId == null || widget.establishmentName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'L\'établissement n\'est pas défini',
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
      return;
    }

    // Drink is required
    if (_selectedDrink == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Veuillez sélectionner une boisson',
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
      return;
    }

    // Image is required - either custom image or default enseigne image
    if (_promotionImageBytes == null && (_defaultImageUrl == null || _defaultImageUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Veuillez sélectionner une image pour la promotion',
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
      return;
    }

    // Validation des dates seulement si la promotion n'est pas continue
    if (!_isUnlimited && (_startDate == null || _endDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Veuillez sélectionner les dates de début et de fin',
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
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Si promotion continue, utiliser des dates par défaut
      final startDate = _isUnlimited ? DateTime.now() : _startDate!;
      final endDate = _isUnlimited 
          ? DateTime.now().add(const Duration(days: 365 * 10)) // 10 ans pour "illimité"
          : _endDate!;
      
      // Create promotion via repository
      await _repository.createPromotion(
        establishmentId: widget.establishmentId!,
        establishmentName: widget.establishmentName!,
        establishmentLogoUrl: widget.logoUrl,
        boissonId: _selectedDrink!.id,
        boissonName: _selectedDrink!.displayName,
        boissonImageUrl: _selectedDrink!.imageUrl,
        formule: _formuleController.text.trim(),
        imageBytes: _promotionImageBytes,
        imageUrl: _promotionImageBytes == null ? _defaultImageUrl : null,
        startDate: startDate,
        endDate: endDate,
        isUnlimited: _isUnlimited,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Promotion créée avec succès',
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

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erreur lors de la création de la promotion';
        if (e is Exception) {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        } else {
          errorMessage = e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage,
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
            duration: const Duration(seconds: 5),
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
          'Création de promotion',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.yellowPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimaryLight),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
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
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.md),
                          // Image Preview
                          _buildImagePreview(),
                          const SizedBox(height: AppSpacing.lg),
                          // Establishment Display
                          _buildEstablishmentDisplay(),
                          const SizedBox(height: AppSpacing.lg),
                          // Boisson Field (Dropdown)
                          _buildDrinkDropdown(),
                          const SizedBox(height: AppSpacing.lg),
                          // Formule Field
                          _buildTextField(
                            controller: _formuleController,
                            label: 'Formule',
                            hint: '2+1=3',
                            icon: Icons.calculate_rounded,
                            required: true,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Option Promotion Continue
                          _buildUnlimitedOption(),
                          const SizedBox(height: AppSpacing.lg),
                          // Date Fields (masqués si promotion continue)
                          if (!_isUnlimited)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateField(
                                    label: 'Date de début',
                                    date: _startDate,
                                    onTap: () => _selectDate(true),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: _buildDateField(
                                    label: 'Date de fin',
                                    date: _endDate,
                                    onTap: () => _selectDate(false),
                                  ),
                                ),
                              ],
                            ),
                          if (!_isUnlimited) const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ),
                  // Bottom Actions
                  _buildBottomActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildImagePreview() {
    final hasCustomImage = _promotionImageBytes != null;
    final hasDefaultImage = _defaultImageUrl != null && _defaultImageUrl!.isNotEmpty;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: GestureDetector(
        onTap: _showImageSourceDialog,
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: hasCustomImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Image.memory(
                        _promotionImageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                      ),
                      Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : hasDefaultImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Image.network(
                            _defaultImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }
                              return Container(
                                height: 200,
                                width: double.infinity,
                                color: AppColors.backgroundSecondaryLight,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppColors.yellowPrimary,
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderImage();
                            },
                          ),
                          Positioned(
                            top: AppSpacing.sm,
                            right: AppSpacing.sm,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildPlaceholderImage(),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_rounded,
          color: AppColors.yellowPrimary,
          size: 48,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Appuyez pour ajouter une image',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildEstablishmentDisplay() {
    final hasLogo = widget.logoUrl != null && widget.logoUrl!.isNotEmpty;
    final establishmentName = widget.establishmentName ?? 'Établissement';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                Text(
                  'Établissement',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimaryLight,
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      child: hasLogo
                          ? Image.network(
                              widget.logoUrl!,
                              fit: BoxFit.cover,
                              width: 56,
                              height: 56,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppColors.yellowPrimary,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.backgroundSecondaryLight,
                                  child: Icon(
                                    Icons.store_rounded,
                                    color: AppColors.yellowPrimary,
                                    size: 28,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: AppColors.backgroundSecondaryLight,
                              child: Icon(
                                Icons.store_rounded,
                                color: AppColors.yellowPrimary,
                                size: 28,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          establishmentName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        if (widget.establishmentId != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${widget.establishmentId}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildDrinkDropdown() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                Text(
                  'Boisson',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimaryLight,
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
            DropdownButtonFormField<DrinkModel>(
              value: _selectedDrink,
              dropdownColor: AppColors.white,
              decoration: InputDecoration(
                hintText: 'Sélectionner une boisson',
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textTertiaryLight,
                  fontSize: 14,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_drink_rounded,
                    color: AppColors.yellowPrimary,
                    size: 20,
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 4,
                  vertical: AppSpacing.sm + 4,
                ),
              ),
              items: _drinks.map((drink) {
                return DropdownMenuItem<DrinkModel>(
                  value: drink,
                  child: _buildDrinkItem(drink),
                );
              }).toList(),
              onChanged: (DrinkModel? value) {
                setState(() {
                  _selectedDrink = value;
                });
              },
              validator: (DrinkModel? value) {
                if (value == null) {
                  return 'Veuillez sélectionner une boisson';
                }
                return null;
              },
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                color: AppColors.textTertiaryLight,
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimaryLight,
              ),
              selectedItemBuilder: (BuildContext context) {
                return _drinks.map<Widget>((DrinkModel drink) {
                  return _buildDrinkItem(drink);
                }).toList();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrinkItem(DrinkModel drink) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image placeholder or actual image
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondaryLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.gray200,
              width: 1,
            ),
          ),
          child: drink.imageUrl != null && drink.imageUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    drink.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.local_drink_rounded,
                        color: AppColors.yellowPrimary,
                        size: 20,
                      );
                    },
                  ),
                )
              : Icon(
                  Icons.local_drink_rounded,
                  color: AppColors.yellowPrimary,
                  size: 20,
                ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            drink.displayName,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimaryLight,
            ),
            overflow: TextOverflow.ellipsis,
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
    required bool required,
    bool showImageIcon = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimaryLight,
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
              validator: (value) {
                if (required && (value == null || value.trim().isEmpty)) {
                  return 'Ce champ est requis';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textTertiaryLight,
                  fontSize: 14,
                ),
                prefixIcon: showImageIcon
                    ? Container(
                        margin: const EdgeInsets.all(8),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.local_drink_rounded,
                          color: AppColors.yellowPrimary,
                          size: 20,
                        ),
                      )
                    : Container(
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

  Widget _buildUnlimitedOption() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: _isUnlimited
              ? AppColors.yellowPrimary.withOpacity(0.1)
              : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isUnlimited
                ? AppColors.yellowPrimary.withOpacity(0.3)
                : AppColors.gray300,
            width: _isUnlimited ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: _isUnlimited
                    ? AppColors.yellowPrimary.withOpacity(0.2)
                    : AppColors.backgroundSecondaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Icon(
                Icons.all_inclusive_rounded,
                color: _isUnlimited
                    ? AppColors.yellowPrimary
                    : AppColors.textSecondaryLight,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Promotion continue',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sans limite de date',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isUnlimited,
              onChanged: (value) {
                setState(() {
                  _isUnlimited = value;
                  // Réinitialiser les dates si on désactive
                  if (!value) {
                    _startDate = null;
                    _endDate = null;
                  }
                });
              },
              activeColor: AppColors.yellowPrimary,
              activeTrackColor: AppColors.yellowPrimary.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
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
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 4,
                  vertical: AppSpacing.sm + 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: AppColors.textTertiaryLight,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        date != null ? _formatDate(date) : 'Sélectionner',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: date != null
                              ? AppColors.textPrimaryLight
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
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
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.yellowPrimary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellowPrimary,
                    foregroundColor: AppColors.textPrimaryLight,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Créer',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
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

