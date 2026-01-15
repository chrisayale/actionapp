import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../../auth/auth_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/firebase_service.dart';

class ProfilePage extends StatefulWidget {
  final AuthController authController;

  const ProfilePage({super.key, required this.authController});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  late Animation<Color?> _colorAnimation;

  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<TextEditingController> _confirmPinControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );
  final List<FocusNode> _confirmPinFocusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  Uint8List? _selectedImageBytes;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();

    // Animation controller for vibrant effects
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: const Color(0xFFFFD700),
      end: const Color(0xFFFF6B35),
    ).animate(_animationController);

    _loadProfileData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var controller in _confirmPinControllers) {
      controller.dispose();
    }
    for (var node in _pinFocusNodes) {
      node.dispose();
    }
    for (var node in _confirmPinFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = widget.authController.currentUser;
      if (user == null) return;

      final doc = await FirebaseService.firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _profileData = doc.data();
          _nameController.text = _profileData?['displayName'] ?? '';
          _selectedGender = _profileData?['gender'];
          _currentPhotoUrl = _profileData?['photoUrl'] ?? user.photoURL;

          if (_profileData?['dateOfBirth'] != null) {
            final timestamp = _profileData!['dateOfBirth'];
            if (timestamp is Timestamp) {
              _selectedDateOfBirth = timestamp.toDate();
            }
          }

          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final Uint8List? compressed =
            await FlutterImageCompress.compressWithFile(
              image.path,
              minWidth: 800,
              minHeight: 800,
              quality: 85,
            );

        if (compressed != null) {
          setState(() {
            _selectedImageBytes = compressed;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<String?> _uploadPhoto(String userId, Uint8List imageBytes) async {
    try {
      final ref = FirebaseService.storage
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      await ref.putData(imageBytes);
      return await ref.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    }
  }

  String _getPinValue(List<TextEditingController> controllers) {
    return controllers.map((e) => e.text).join();
  }

  void _onPinChanged(
    int index,
    String value,
    List<TextEditingController> controllers,
    List<FocusNode> focusNodes, {
    bool isConfirm = false,
  }) {
    // Use SchedulerBinding to defer focus changes and avoid web pointer binding issues
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Move to next field if digit entered
      if (value.length == 1 && index < 3) {
        Future.microtask(() {
          if (mounted && focusNodes[index + 1].canRequestFocus) {
            focusNodes[index + 1].requestFocus();
          }
        });
      }
      // Move to previous field if deleted
      else if (value.isEmpty && index > 0) {
        Future.microtask(() {
          if (mounted && focusNodes[index - 1].canRequestFocus) {
            focusNodes[index - 1].requestFocus();
          }
        });
      }
    });

    // If all fields filled and this is confirm PIN, validate
    if (isConfirm &&
        controllers.every((controller) => controller.text.isNotEmpty)) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final pin = _getPinValue(_pinControllers);
        final confirmPin = _getPinValue(_confirmPinControllers);
        if (pin != confirmPin && pin.isNotEmpty) {
          // Show error if PINs don't match
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

  Future<void> _saveProfile() async {
    // Vérifier le PIN si fourni
    final pin = _getPinValue(_pinControllers);
    final confirmPin = _getPinValue(_confirmPinControllers);

    if (pin.isNotEmpty || confirmPin.isNotEmpty) {
      if (pin.length != 4) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Le code PIN doit contenir 4 chiffres'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      if (pin != confirmPin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Les codes PIN ne correspondent pas'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      // Vérifier si le PIN est le PIN par défaut
      if (pin == '1234') {
        if (mounted) {
          _showDefaultPinRejectedDialog();
        }
        return;
      }
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = widget.authController.currentUser;
      if (user == null) return;

      final Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_nameController.text.trim().isNotEmpty) {
        updateData['displayName'] = _nameController.text.trim();
        await user.updateDisplayName(_nameController.text.trim());
      }

      if (_selectedGender != null) {
        updateData['gender'] = _selectedGender;
      }

      if (_selectedDateOfBirth != null) {
        updateData['dateOfBirth'] = Timestamp.fromDate(_selectedDateOfBirth!);
      }

      // Ajouter le PIN si fourni (sera hashé côté backend)
      if (pin.isNotEmpty) {
        updateData['pin'] =
            pin; // TODO: Hasher le PIN côté backend pour plus de sécurité
        // Supprimer le flag isDefaultPin si l'utilisateur modifie le PIN
        updateData['isDefaultPin'] = FieldValue.delete();
      }

      String? photoUrl = _currentPhotoUrl;
      if (_selectedImageBytes != null) {
        photoUrl = await _uploadPhoto(user.uid, _selectedImageBytes!);
        if (photoUrl != null) {
          updateData['photoUrl'] = photoUrl;
          await user.updatePhotoURL(photoUrl);
        }
      }

      await FirebaseService.firestore
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      await _loadProfileData();

      setState(() {
        _isEditing = false;
        _isSaving = false;
        _selectedImageBytes = null;
        // Réinitialiser les champs PIN
        for (var controller in _pinControllers) {
          controller.clear();
        }
        for (var controller in _confirmPinControllers) {
          controller.clear();
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
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

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        title: Text(
          'Supprimer le compte',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.error,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.',
          style: GoogleFonts.inter(color: AppColors.textSecondaryLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(
                color: AppColors.gray600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Supprimer',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final user = widget.authController.currentUser;
        if (user == null) return;

        // Supprimer les données Firestore
        await FirebaseService.firestore
            .collection('users')
            .doc(user.uid)
            .delete();

        // Supprimer la photo de profil du Storage
        if (_currentPhotoUrl != null) {
          try {
            final ref = FirebaseService.storage
                .ref()
                .child('profile_pictures')
                .child('${user.uid}.jpg');
            await ref.delete();
          } catch (e) {
            // Ignorer l'erreur si le fichier n'existe pas
          }
        }

        // Supprimer le compte Firebase Auth
        await user.delete();

        // Déconnexion
        await widget.authController.signOut();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        title: Text(
          'Déconnexion',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: GoogleFonts.inter(color: AppColors.textSecondaryLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(
                color: AppColors.gray600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Déconnexion',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await widget.authController.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authController.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      // Header avec avatar
                      _buildProfileHeader(user),
                      const SizedBox(height: AppSpacing.xl),
                      // Informations utilisateur
                      _buildUserInfoCard(user),
                      const SizedBox(height: AppSpacing.lg),
                      // Boutons d'action
                      _buildActionButtons(),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader(User? user) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Column(
          children: [
            // Avatar avec glow animé
            GestureDetector(
              onTap: _isEditing ? _pickImage : null,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _colorAnimation.value ?? const Color(0xFFFFD700),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_colorAnimation.value ?? const Color(0xFFFFD700))
                          .withOpacity(_glowAnimation.value),
                      blurRadius: 40,
                      spreadRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                    BoxShadow(
                      color: const Color(
                        0xFF4CAF50,
                      ).withOpacity(_glowAnimation.value * 0.5),
                      blurRadius: 35,
                      spreadRadius: 6,
                      offset: const Offset(0, 0),
                    ),
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.15),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 68,
                      backgroundColor: AppColors.gray100,
                      backgroundImage: _selectedImageBytes != null
                          ? MemoryImage(_selectedImageBytes!)
                          : (_currentPhotoUrl != null
                                    ? NetworkImage(_currentPhotoUrl!)
                                    : null)
                                as ImageProvider?,
                      child:
                          _selectedImageBytes == null &&
                              _currentPhotoUrl == null
                          ? Icon(
                              Icons.person,
                              size: 70,
                              color:
                                  _colorAnimation.value ??
                                  const Color(0xFFFFD700),
                            )
                          : null,
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Nom utilisateur avec gradient
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFD700),
                  const Color(0xFFFF6B35),
                  const Color(0xFF4CAF50),
                  const Color(0xFF2196F3),
                ],
                stops: [
                  0.0,
                  0.33 + (0.1 * _glowAnimation.value),
                  0.66 + (0.1 * _glowAnimation.value),
                  1.0,
                ],
              ).createShader(bounds),
              child: Text(
                _isEditing
                    ? 'Modifier le profil'
                    : (user?.displayName ??
                          _profileData?['displayName'] ??
                          user?.phoneNumber?.replaceRange(0, 4, '****') ??
                          'Utilisateur'),
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  letterSpacing: -0.5,
                  height: 1.2,
                  shadows: [
                    Shadow(
                      color: const Color(
                        0xFFFFD700,
                      ).withOpacity(0.5 * _glowAnimation.value),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserInfoCard(User? user) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Card(
          elevation: 12,
          shadowColor: const Color(0xFF4CAF50).withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF2196F3,
                  ).withOpacity(0.1 * _glowAnimation.value),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_isEditing) ...[
                  _buildEditableField(
                    label: 'Nom complet',
                    controller: _nameController,
                    icon: Icons.person,
                    color: const Color(0xFF2196F3),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildGenderSelector(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDateOfBirthSelector(),
                ] else ...[
                  _buildInfoRow(
                    icon: Icons.person,
                    label: 'Nom',
                    value:
                        user?.displayName ??
                        _profileData?['displayName'] ??
                        'Non renseigné',
                    color: const Color(0xFF2196F3),
                  ),
                  if (_profileData?['gender'] != null) ...[
                    const Divider(height: AppSpacing.xl),
                    _buildInfoRow(
                      icon: _profileData!['gender'] == 'M'
                          ? Icons.male
                          : Icons.female,
                      label: 'Genre',
                      value: _profileData!['gender'] == 'M' ? 'Homme' : 'Femme',
                      color: const Color(0xFFFF6B35),
                    ),
                  ],
                  if (_selectedDateOfBirth != null ||
                      _profileData?['dateOfBirth'] != null) ...[
                    const Divider(height: AppSpacing.xl),
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Date de naissance',
                      value: _formatDate(
                        _selectedDateOfBirth ??
                            (_profileData?['dateOfBirth'] is Timestamp
                                ? (_profileData!['dateOfBirth'] as Timestamp)
                                      .toDate()
                                : null),
                      ),
                      color: const Color(0xFF4CAF50),
                    ),
                  ],
                  const Divider(height: AppSpacing.xl),
                  _buildInfoRow(
                    icon: Icons.phone,
                    label: 'Téléphone',
                    value: user?.phoneNumber ?? 'Non renseigné',
                    color: const Color(0xFF4CAF50),
                  ),
                  if (user?.email != null) ...[
                    const Divider(height: AppSpacing.xl),
                    _buildInfoRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: user!.email!,
                      color: const Color(0xFF2196F3),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: color),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: color, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ce champ est requis';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genre',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(child: _buildGenderOption('M', 'Homme', Icons.male)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _buildGenderOption('F', 'Femme', Icons.female)),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String value, String label, IconData icon) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF6B35).withOpacity(0.1)
              : AppColors.gray50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B35) : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFF6B35) : AppColors.gray500,
              size: 18,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFFFF6B35)
                      : AppColors.textSecondaryLight,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateOfBirthSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date de naissance',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate:
                  _selectedDateOfBirth ??
                  DateTime.now().subtract(const Duration(days: 365 * 20)),
              firstDate: DateTime(1950),
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: const Color(0xFFFFD700),
                      onPrimary: AppColors.white,
                      surface: AppColors.white,
                      onSurface: AppColors.textPrimaryLight,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _selectedDateOfBirth = picked;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: const Color(0xFF4CAF50),
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  _formatDate(_selectedDateOfBirth),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _selectedDateOfBirth != null
                        ? AppColors.textPrimaryLight
                        : AppColors.textTertiaryLight,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: AppColors.gray500),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Column(
          children: [
            if (_isEditing) ...[
              // Bouton Sauvegarder
              SizedBox(
                width: double.infinity,
                height: 58,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _colorAnimation.value ?? const Color(0xFFFFD700),
                        const Color(0xFFFF6B35),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_colorAnimation.value ?? const Color(0xFFFFD700))
                                .withOpacity(_glowAnimation.value),
                        blurRadius: 20,
                        spreadRadius: 4,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: const Color(
                          0xFF4CAF50,
                        ).withOpacity(_glowAnimation.value * 0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLarge,
                        ),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.save,
                                color: AppColors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Sauvegarder',
                                style: GoogleFonts.inter(
                                  color: AppColors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Bouton Annuler
              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _selectedImageBytes = null;
                      // Réinitialiser les champs PIN
                      for (var controller in _pinControllers) {
                        controller.clear();
                      }
                      for (var controller in _confirmPinControllers) {
                        controller.clear();
                      }
                      _loadProfileData();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.gray400, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusLarge,
                      ),
                    ),
                  ),
                  child: Text(
                    'Annuler',
                    style: GoogleFonts.inter(
                      color: AppColors.gray600,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Bouton Modifier
              SizedBox(
                width: double.infinity,
                height: 58,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2196F3),
                        const Color(0xFF4CAF50),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF2196F3,
                        ).withOpacity(0.3 * _glowAnimation.value),
                        blurRadius: 20,
                        spreadRadius: 4,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLarge,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.edit,
                          color: AppColors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Modifier le profil',
                          style: GoogleFonts.inter(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Bouton Supprimer le compte
              SizedBox(
                width: double.infinity,
                height: 58,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.error, Colors.red[700]!],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withOpacity(
                          0.4 * _glowAnimation.value,
                        ),
                        blurRadius: 20,
                        spreadRadius: 4,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _deleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLarge,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.delete_forever,
                          color: AppColors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Supprimer le compte',
                          style: GoogleFonts.inter(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Bouton Déconnexion
              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton(
                  onPressed: _handleLogout,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.gray400, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusLarge,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.logout,
                        color: AppColors.gray600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Déconnexion',
                        style: GoogleFonts.inter(
                          color: AppColors.gray600,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sélectionner une date';
    return '${date.day}/${date.month}/${date.year}';
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
                  colors: [AppColors.white, AppColors.offWhite],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warning.withOpacity(
                      0.2 * _glowAnimation.value,
                    ),
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
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMedium,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.warning.withOpacity(
                                  0.3 * _glowAnimation.value,
                                ),
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
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLarge,
                        ),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warning.withOpacity(
                              0.1 * _glowAnimation.value,
                            ),
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
                            colors: [AppColors.warning, Colors.orange[700]!],
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLarge,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warning.withOpacity(
                                0.4 * _glowAnimation.value,
                              ),
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
                            for (var controller in _pinControllers) {
                              controller.clear();
                            }
                            for (var controller in _confirmPinControllers) {
                              controller.clear();
                            }
                            // Remettre le focus sur le premier champ
                            _pinFocusNodes[0].requestFocus();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusLarge,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.refresh,
                                color: AppColors.white,
                                size: 20,
                              ),
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

  Widget _buildPINFields({
    required String label,
    required List<TextEditingController> controllers,
    required List<FocusNode> focusNodes,
    required bool isConfirm,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            4,
            (index) => _buildPINField(
              index,
              controllers[index],
              focusNodes[index],
              isConfirm: isConfirm,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPINField(
    int index,
    TextEditingController controller,
    FocusNode focusNode, {
    required bool isConfirm,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final isFocused = focusNode.hasFocus;
        return Container(
          width: 60,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
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
                      color: const Color(
                        0xFF4CAF50,
                      ).withOpacity(0.2 * _glowAnimation.value),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
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
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
              letterSpacing: 0,
              height: 1.2,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                borderSide: BorderSide(color: AppColors.gray400, width: 2.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                borderSide: BorderSide(color: AppColors.gray400, width: 2.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                borderSide: BorderSide(
                  color: _colorAnimation.value ?? const Color(0xFFFFD700),
                  width: 3,
                ),
              ),
            ),
            onChanged: (value) => _onPinChanged(
              index,
              value,
              isConfirm ? _confirmPinControllers : _pinControllers,
              isConfirm ? _confirmPinFocusNodes : _pinFocusNodes,
              isConfirm: isConfirm,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPINInfoCard() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Card(
          elevation: 4,
          shadowColor: AppColors.warning.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              color: AppColors.warning.withOpacity(0.1),
              border: Border.all(
                color: AppColors.warning.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Le code PIN est indispensable si vous souhaitez publier des promotions',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.warning,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
