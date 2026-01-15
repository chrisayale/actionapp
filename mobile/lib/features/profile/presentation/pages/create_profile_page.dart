import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../auth/auth_controller.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/permission_service.dart';

class CreateProfilePage extends StatefulWidget {
  final AuthController authController;

  const CreateProfilePage({
    super.key,
    required this.authController,
  });

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage>
    with SingleTickerProviderStateMixin {
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
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;

  late AnimationController _animationController;
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
      begin: const Color(0xFF4CAF50),
      end: const Color(0xFF2196F3),
    ).animate(_animationController);

    // Attribuer le PIN par défaut "1234"
    _setDefaultPin();

    // Afficher le dialogue d'autorisations après 2 secondes
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _showPermissionsDialog();
      }
    });
  }

  void _setDefaultPin() {
    // Pré-remplir les champs PIN avec "1234" par défaut
    const defaultPin = '1234';
    for (int i = 0; i < 4 && i < defaultPin.length; i++) {
      _pinControllers[i].text = defaultPin[i];
      _confirmPinControllers[i].text = defaultPin[i];
    }
  }

  @override
  void dispose() {
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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    
    // Show modern bottom sheet to choose source
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50)
                      .withOpacity(0.2 * _glowAnimation.value),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF4CAF50),
                          const Color(0xFF2196F3),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'Choisir une photo',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Options
                  _buildImageSourceOption(
                    context: context,
                    icon: Icons.photo_library,
                    title: 'Galerie',
                    subtitle: 'Choisir depuis vos photos',
                    color: const Color(0xFF4CAF50),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                  _buildImageSourceOption(
                    context: context,
                    icon: Icons.camera_alt,
                    title: 'Caméra',
                    subtitle: 'Prendre une nouvelle photo',
                    color: const Color(0xFF2196F3),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (source != null) {
      // Vérifier les permissions avant de sélectionner l'image
      bool hasPermission = false;
      
      if (source == ImageSource.camera) {
        // Vérifier la permission de la caméra
        hasPermission = await PermissionService.isCameraPermissionGranted();
        if (!hasPermission) {
          hasPermission = await PermissionService.requestCameraPermission();
        }
      } else if (source == ImageSource.gallery) {
        // Vérifier la permission de la galerie
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
                          ? 'Permission de la caméra requise pour prendre une photo'
                          : 'Permission de la galerie requise pour sélectionner une image',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFFF9800),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              action: SnackBarAction(
                label: 'Paramètres',
                textColor: Colors.white,
                onPressed: () async {
                  await PermissionService.openAppSettings();
                },
              ),
            ),
          );
        }
        return;
      }
      
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 70, // Réduire la qualité pour réduire la taille du fichier
      );

      if (image != null && mounted) {
        // Lire les bytes de l'image (nécessaire pour l'affichage et l'upload)
        try {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImage = image;
            _selectedImageBytes = bytes;
          });
        } catch (e) {
          if (kDebugMode) {
            print('Erreur lors de la lecture de l\'image: $e');
          }
        }
      }
    }
  }

  Widget _buildImageSourceOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color,
                          color.withOpacity(0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3 * _glowAnimation.value),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: color,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  String _getPinValue(List<TextEditingController> controllers) {
    return controllers.map((e) => e.text).join();
  }

  void _onPinChanged(int index, String value, List<TextEditingController> controllers, List<FocusNode> focusNodes, {bool isConfirm = false}) {
    // Move to next field if digit entered
    if (value.length == 1 && index < 3) {
      focusNodes[index + 1].requestFocus();
    }
    // Move to previous field if deleted
    else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }

    // If all fields filled and this is confirm PIN, validate
    if (isConfirm && controllers.every((controller) => controller.text.isNotEmpty)) {
      final pin = _getPinValue(_pinControllers);
      final confirmPin = _getPinValue(_confirmPinControllers);
      if (pin != confirmPin && pin.isNotEmpty) {
        // Show error if PINs don't match
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Les codes PIN ne correspondent pas'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit({bool skip = false}) async {
    if (!skip) {
      // Vérifier le PIN si fourni
      final pin = _getPinValue(_pinControllers);
      final confirmPin = _getPinValue(_confirmPinControllers);
      
      if (pin.isNotEmpty || confirmPin.isNotEmpty) {
        if (pin.length != 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Le code PIN doit contenir 4 chiffres'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        if (pin != confirmPin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Les codes PIN ne correspondent pas'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = widget.authController.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Afficher un dialogue de progression avec style moderne
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.6),
          builder: (context) => PopScope(
            canPop: false,
            child: _buildLoadingDialog(),
          ),
        );
      }

      // Upload photo en arrière-plan après sauvegarde du profil
      // Pour ne pas bloquer la création du profil
      Uint8List? imageBytesToUpload = _selectedImageBytes;
      final String userId = user.uid;

      final pin = _getPinValue(_pinControllers);
      
      // Vérifier si le document existe déjà
      final userDocRef = FirebaseService.firestore.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();
      
      // Sauvegarder le profil dans Firestore (même si incomplet)
      final profileData = <String, dynamic>{
        'phoneNumber': user.phoneNumber ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Ajouter les champs optionnels seulement s'ils ont une valeur
      if (_nameController.text.trim().isNotEmpty) {
        profileData['displayName'] = _nameController.text.trim();
      }
      
      if (_selectedGender != null) {
        profileData['gender'] = _selectedGender;
      }
      
      if (_selectedDateOfBirth != null) {
        profileData['dateOfBirth'] = _selectedDateOfBirth!.toIso8601String();
      }
      
      // Toujours initialiser photoUrl à null par défaut pour garantir que le document existe
      // Si une photo est sélectionnée, elle sera ajoutée après l'upload en arrière-plan
      profileData['photoUrl'] = null;
      
      // Attribuer le PIN par défaut "1234" si aucun PIN n'est fourni
      final pinToSave = pin.isNotEmpty ? pin : '1234';
      profileData['pin'] = pinToSave; // TODO: Hasher le PIN côté backend pour plus de sécurité
      
      // Marquer si c'est le PIN par défaut (temporaire)
      if (pin.isEmpty) {
        profileData['isDefaultPin'] = true;
      }
      
      profileData['profileComplete'] = pinToSave.isNotEmpty && 
                                       _selectedGender != null && 
                                       _selectedDateOfBirth != null;
      
      // Ajouter createdAt seulement si le document n'existe pas
      if (!userDoc.exists) {
        profileData['createdAt'] = FieldValue.serverTimestamp();
      }
      
      // Sauvegarder dans Firestore
      if (kDebugMode) {
        print('💾 Sauvegarde dans Firestore...');
        print('   UID: ${user.uid}');
        print('   Document existe: ${userDoc.exists}');
        print('   Données à sauvegarder: $profileData');
      }
      
      try {
        await userDocRef.set(profileData, SetOptions(merge: true));
        
        if (kDebugMode) {
          print('✅ Profil sauvegardé dans Firestore avec succès');
        }
      } catch (firestoreError) {
        if (kDebugMode) {
          print('❌ Erreur Firestore: $firestoreError');
          print('   Type: ${firestoreError.runtimeType}');
        }
        rethrow; // Re-lancer pour être capturé par le catch global
      }

      // Mettre à jour le displayName dans Firebase Auth si fourni
      if (_nameController.text.trim().isNotEmpty) {
        await user.updateDisplayName(_nameController.text.trim());
      }

      // Fermer le dialogue de progression avant la navigation
      if (mounted) {
        Navigator.of(context).pop(); // Fermer le dialogue de progression
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }

      // Upload photo en arrière-plan (après navigation pour ne pas bloquer)
      if (imageBytesToUpload != null) {
        _uploadPhotoInBackground(userId, imageBytesToUpload);
      }
    } catch (e) {
      if (mounted) {
        // Fermer le dialogue de progression s'il est ouvert
        Navigator.of(context).pop();
        
        // Extraire le message d'erreur de manière plus lisible
        String errorMessage = 'Erreur lors de la sauvegarde';
        if (e.toString().contains('Timeout')) {
          errorMessage = 'Le serveur ne répond pas. Vérifiez votre connexion internet.';
        } else if (e.toString().contains('Exception:')) {
          final exceptionMatch = RegExp(r'Exception:\s*(.+)').firstMatch(e.toString());
          if (exceptionMatch != null) {
            errorMessage = exceptionMatch.group(1) ?? errorMessage;
          } else {
            errorMessage = e.toString().replaceFirst('Exception: ', '');
          }
        } else {
          errorMessage = e.toString();
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
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16,
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: () {
                _handleSubmit(skip: false);
              },
            ),
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
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final padding = size.width * 0.08;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            left: padding,
            right: padding,
            bottom: MediaQuery.of(context).viewInsets.bottom + 80, // Padding supplémentaire pour éviter le chevauchement avec le SnackBar
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: isSmallScreen ? 20 : 40),
                // Header
                _buildHeader(),
                SizedBox(height: isSmallScreen ? 32 : 48),
                // Photo de profil
                _buildPhotoSelector(),
                SizedBox(height: isSmallScreen ? 32 : 48),
                // Formulaire
                _buildForm(),
                SizedBox(height: isSmallScreen ? 32 : 40),
                // Bouton de soumission
                _buildSubmitButton(),
                const SizedBox(height: 16),
                // Bouton Ignorer
                _buildSkipButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4CAF50),
                  const Color(0xFF2196F3),
                  const Color(0xFFFFD700),
                ],
                stops: [
                  0.0,
                  0.5 + (0.1 * _glowAnimation.value),
                  1.0,
                ],
              ).createShader(bounds),
              child: Text(
                'Créer votre profil',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1.2,
                  shadows: [
                    Shadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.5 * _glowAnimation.value),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complétez votre profil pour continuer',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhotoSelector() {
    final size = MediaQuery.of(context).size;
    final photoSize = size.width * 0.3; // Responsive size: 30% of screen width
    final minPhotoSize = 120.0;
    final maxPhotoSize = 160.0;
    final finalPhotoSize = photoSize.clamp(minPhotoSize, maxPhotoSize);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Card(
          elevation: 12,
          shadowColor: (_colorAnimation.value ?? const Color(0xFF4CAF50))
              .withOpacity(0.3 * _glowAnimation.value),
          shape: const CircleBorder(),
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: finalPhotoSize,
              height: finalPhotoSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _selectedImageBytes != null
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey[100]!,
                          Colors.grey[200]!,
                        ],
                      ),
                border: Border.all(
                  color: _selectedImageBytes != null
                      ? (_colorAnimation.value ?? const Color(0xFF4CAF50))
                      : Colors.transparent,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_colorAnimation.value ?? const Color(0xFF4CAF50))
                        .withOpacity(0.3 * _glowAnimation.value),
                    blurRadius: 25,
                    spreadRadius: 5,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFF2196F3)
                        .withOpacity(0.2 * _glowAnimation.value),
                    blurRadius: 20,
                    spreadRadius: 3,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: _selectedImageBytes != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(
                            _selectedImageBytes!,
                            fit: BoxFit.cover,
                          ),
                          // Overlay pour l'icône de changement
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF4CAF50),
                                      const Color(0xFF2196F3),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(finalPhotoSize * 0.12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF4CAF50),
                                  const Color(0xFF45A049),
                                  const Color(0xFF2196F3),
                                ],
                                stops: [
                                  0.0,
                                  0.5 + (0.1 * _glowAnimation.value),
                                  1.0,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4CAF50)
                                      .withOpacity(0.4 * _glowAnimation.value),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add_a_photo,
                              size: finalPhotoSize * 0.3,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: finalPhotoSize * 0.08),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Ajouter une photo',
                              style: GoogleFonts.inter(
                                fontSize: finalPhotoSize * 0.09,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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

  Widget _buildForm() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Column(
          children: [
            // Nom complet (optionnel)
            _buildTextFieldCard(
              controller: _nameController,
              label: 'Nom complet',
              hint: 'Votre nom complet (optionnel)',
              icon: Icons.person_outline,
              required: false,
            ),
            const SizedBox(height: 20),
            // Sexe
            _buildGenderSelector(),
            const SizedBox(height: 20),
            // Date de naissance
            _buildDateOfBirthSelector(),
          ],
        );
      },
    );
  }

  Widget _buildTextFieldCard({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = true,
  }) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: TextFormField(
          controller: controller,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF4CAF50)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            suffixText: required ? null : '(Optionnel)',
            suffixStyle: GoogleFonts.inter(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ce champ est obligatoire';
                  }
                  return null;
                }
              : null,
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, color: Color(0xFF4CAF50)),
                const SizedBox(width: 12),
                Text(
                  'Sexe (optionnel)',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildGenderOption('M', 'Masculin'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGenderOption('F', 'Féminin'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderOption(String value, String label) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4CAF50).withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildDateOfBirthSelector() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: InkWell(
          onTap: _selectDateOfBirth,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF4CAF50)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date de naissance',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedDateOfBirth != null
                            ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                            : 'Sélectionner une date',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _selectedDateOfBirth != null
                              ? Colors.black87
                              : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPINFields({
    required String label,
    required List<TextEditingController> controllers,
    required List<FocusNode> focusNodes,
    required bool isConfirm,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Card(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_outline, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildPINField(
    int index,
    TextEditingController controller,
    FocusNode focusNode, {
    required bool isConfirm,
  }) {
    final isFocused = focusNode.hasFocus;
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: (_colorAnimation.value ?? const Color(0xFF4CAF50))
                          .withOpacity(0.3 * _glowAnimation.value),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
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
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: 0,
              height: 1.2,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey[400]!,
                  width: 2.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey[500]!,
                  width: 2.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _colorAnimation.value ?? const Color(0xFF4CAF50),
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
    return Card(
      elevation: 4,
      shadowColor: const Color(0xFFFF9800).withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFFF9800).withOpacity(0.1),
          border: Border.all(
            color: const Color(0xFFFF9800).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: const Color(0xFFFF9800),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Le code PIN est indispensable si vous souhaitez publier des promotions',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFE65100),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultPinWarningCard() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Card(
          elevation: 4,
          shadowColor: Colors.orange.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.orange.withOpacity(0.1),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PIN temporaire',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Un code PIN par défaut (1234) est attribué. Vous êtes fortement encouragé à le modifier lors de la création d\'annonces.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange[800],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SizedBox(
          width: double.infinity,
          height: 58,
          child: Card(
            elevation: 12,
            shadowColor: const Color(0xFF4CAF50).withOpacity(0.4 * _glowAnimation.value),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF4CAF50),
                    const Color(0xFF45A049),
                    const Color(0xFF2196F3).withOpacity(0.8),
                  ],
                  stops: [
                    0.0,
                    0.5,
                    1.0,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50)
                        .withOpacity(0.5 * _glowAnimation.value),
                    blurRadius: 20,
                    spreadRadius: 4,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: const Color(0xFF2196F3)
                        .withOpacity(0.3 * _glowAnimation.value),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : () => _handleSubmit(skip: false),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Créer le profil',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkipButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: TextButton(
        onPressed: _isLoading ? null : () => _handleSubmit(skip: true),
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Ignorer pour l\'instant',
          style: GoogleFonts.inter(
            color: Colors.grey[600],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Demande toutes les permissions nécessaires
  Future<void> _requestAllPermissions() async {
    try {
      if (kDebugMode) {
        print('🔐 Demande des permissions...');
      }

      // Demander toutes les permissions
      final results = await PermissionService.requestAllPermissions();

      // Afficher un message de résultat
      // Utiliser this.context au lieu du context passé en paramètre pour éviter les erreurs
      if (!mounted) return;
      
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final grantedCount = results.values.where((granted) => granted).length;
      final totalCount = results.length;

      if (grantedCount == totalCount) {
        // Toutes les permissions accordées
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Toutes les autorisations ont été accordées',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
          // Certaines permissions refusées
          final deniedPermissions = <String>[];
          if (!results['camera']!) deniedPermissions.add('Caméra');
          if (!results['photos']!) deniedPermissions.add('Photos');
          if (!results['notifications']!) deniedPermissions.add('Notifications');
          if (!results['location']!) deniedPermissions.add('Localisation GPS');

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Certaines autorisations ont été refusées',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Refusées: ${deniedPermissions.join(", ")}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    await PermissionService.openAppSettings();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Ouvrir les paramètres',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFFF9800),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la demande de permissions: $e');
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Erreur lors de la demande d\'autorisations',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showPermissionsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                // Icon avec animation
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF4CAF50),
                        const Color(0xFF2196F3),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                // Titre
                Text(
                  'Autorisations requises',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  'Pour une meilleure expérience, nous avons besoin de certaines autorisations :',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Liste des permissions
                _buildPermissionItem(
                  icon: Icons.camera_alt,
                  title: 'Caméra',
                  description: 'Pour prendre des photos de profil',
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(height: 16),
                _buildPermissionItem(
                  icon: Icons.photo_library,
                  title: 'Photos',
                  description: 'Pour sélectionner des images depuis votre galerie',
                  color: const Color(0xFF2196F3),
                ),
                const SizedBox(height: 16),
                _buildPermissionItem(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  description: 'Pour recevoir les mises à jour et promotions',
                  color: const Color(0xFFFF9800),
                ),
                const SizedBox(height: 16),
                _buildPermissionItem(
                  icon: Icons.location_on,
                  title: 'Localisation GPS',
                  description: 'Pour vous proposer des promotions et services à proximité',
                  color: const Color(0xFF9C27B0),
                ),
                const SizedBox(height: 32),
                // Bouton Accepter
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      // Demander les permissions
                      await _requestAllPermissions();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Accepter',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Bouton Plus tard
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Plus tard',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingDialog() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50)
                      .withOpacity(0.3 * _glowAnimation.value),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF2196F3)
                      .withOpacity(0.2 * _glowAnimation.value),
                  blurRadius: 25,
                  spreadRadius: 3,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon animé avec gradient
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF4CAF50),
                        const Color(0xFF45A049),
                        const Color(0xFF2196F3),
                      ],
                      stops: [
                        0.0,
                        0.5 + (0.1 * _glowAnimation.value),
                        1.0,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50)
                            .withOpacity(0.5 * _glowAnimation.value),
                        blurRadius: 25,
                        spreadRadius: 5,
                        offset: const Offset(0, 0),
                      ),
                      BoxShadow(
                        color: const Color(0xFF2196F3)
                            .withOpacity(0.3 * _glowAnimation.value),
                        blurRadius: 20,
                        spreadRadius: 3,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_add,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 32),
                // Indicateur de chargement
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _colorAnimation.value ?? const Color(0xFF4CAF50),
                    ),
                    strokeWidth: 4,
                  ),
                ),
                const SizedBox(height: 24),
                // Titre avec gradient
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF4CAF50),
                      const Color(0xFF2196F3),
                      const Color(0xFFFFD700),
                    ],
                    stops: [
                      0.0,
                      0.5 + (0.1 * _glowAnimation.value),
                      1.0,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'Création du profil',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF4CAF50)
                              .withOpacity(0.5 * _glowAnimation.value),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                // Sous-titre
                Text(
                  'Veuillez patienter...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Optimise l'image avant l'upload (réduit la taille si nécessaire)
  Future<Uint8List> _optimizeImage(Uint8List imageBytes) async {
    // Si l'image fait moins de 300KB, on la garde telle quelle
    if (imageBytes.length < 300 * 1024) {
      return imageBytes;
    }
    
    try {
      if (kDebugMode) {
        print('🔄 Compression de l\'image (${(imageBytes.length / 1024).toStringAsFixed(0)}KB -> ...)');
      }
      
      // Compresser l'image à 60% de qualité pour réduire significativement la taille
      final compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        quality: 60,
        format: CompressFormat.jpeg,
      );
      
      if (kDebugMode) {
        print('✅ Image compressée: ${(imageBytes.length / 1024).toStringAsFixed(0)}KB -> ${(compressedBytes.length / 1024).toStringAsFixed(0)}KB');
      }
      
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erreur lors de la compression, utilisation de l\'image originale: $e');
      }
      return imageBytes;
    }
  }

  /// Upload la photo en arrière-plan après la création du profil
  Future<void> _uploadPhotoInBackground(String userId, Uint8List imageBytes) async {
    try {
      if (kDebugMode) {
        print('📤 Début upload photo en arrière-plan...');
        print('   UID: $userId');
        print('   Taille image originale: ${(imageBytes.length / 1024).toStringAsFixed(0)}KB');
      }
      
      // Optimiser l'image avant l'upload
      final optimizedBytes = await _optimizeImage(imageBytes);
      
      if (kDebugMode) {
        print('   Taille image optimisée: ${(optimizedBytes.length / 1024).toStringAsFixed(0)}KB');
      }
      
      final storageRef = FirebaseService.storage
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');
      
      // Les emulators Firebase Storage peuvent être très lents, même pour de petites images
      // Utiliser un timeout généreux de 2 minutes pour tous les cas
      const timeoutDuration = Duration(minutes: 2);
      
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      );
      
      if (kDebugMode) {
        print('   Upload en cours (timeout: ${timeoutDuration.inMinutes}min)...');
        print('   Chemin Storage: profile_pictures/$userId.jpg');
      }
      
      try {
        // Essayer l'upload avec un timeout
        final uploadResult = await storageRef.putData(optimizedBytes, metadata).timeout(
          timeoutDuration,
          onTimeout: () {
            if (kDebugMode) {
              print('   ⚠️ Timeout: L\'upload a pris plus de ${timeoutDuration.inMinutes}min');
              print('   💡 Note: Les emulators Firebase Storage peuvent être très lents');
              print('   💡 Le profil est déjà créé, l\'upload peut être ignoré en développement');
            }
            throw TimeoutException('Upload de la photo a pris trop de temps (>${timeoutDuration.inMinutes}min). '
                'C\'est normal avec les emulators Storage en développement.');
          },
        );
        
        // Attendre que l'upload soit complètement terminé
        uploadResult;
        
        if (kDebugMode) {
          print('   ✅ Upload terminé avec succès');
        }
      } catch (e) {
        if (kDebugMode) {
          print('   ❌ Erreur lors de l\'upload: $e');
          print('   📝 Type d\'erreur: ${e.runtimeType}');
          if (e is TimeoutException) {
            print('   💡 En développement, cette erreur est normale avec les emulators Storage');
            print('   💡 Le profil est déjà créé et fonctionnel sans la photo');
          }
        }
        rethrow;
      }
      
      if (kDebugMode) {
        print('   Récupération de l\'URL...');
      }
      
      final photoUrl = await storageRef.getDownloadURL().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Récupération de l\'URL a pris trop de temps');
        },
      );
      
      if (kDebugMode) {
        print('✅ Photo uploadée avec succès: $photoUrl');
      }
      
      // Mettre à jour le profil dans Firestore avec photoUrl
      // Utiliser set avec merge: true pour éviter les conflits de transaction
      try {
        await FirebaseService.firestore
            .collection('users')
            .doc(userId)
            .set({'photoUrl': photoUrl}, SetOptions(merge: true));
        
        if (kDebugMode) {
          print('✅ Profil mis à jour avec photoUrl dans Firestore');
        }
      } catch (firestoreError) {
        if (kDebugMode) {
          print('⚠️ Erreur lors de la mise à jour Firestore: $firestoreError');
          print('   Type: ${firestoreError.runtimeType}');
          // Si c'est une erreur de transaction, on peut réessayer une fois
          if (firestoreError.toString().contains('AbortError') || 
              firestoreError.toString().contains('transaction')) {
            if (kDebugMode) {
              print('   🔄 Nouvelle tentative de mise à jour...');
            }
            try {
              // Attendre un peu avant de réessayer
              await Future.delayed(const Duration(milliseconds: 500));
              await FirebaseService.firestore
                  .collection('users')
                  .doc(userId)
                  .set({'photoUrl': photoUrl}, SetOptions(merge: true));
              if (kDebugMode) {
                print('✅ Profil mis à jour avec succès après nouvelle tentative');
              }
            } catch (retryError) {
              if (kDebugMode) {
                print('❌ Échec de la nouvelle tentative: $retryError');
                print('   💡 La photo est uploadée mais le profil ne sera pas mis à jour automatiquement');
              }
            }
          }
        }
      }
      
      // Mettre à jour la photo dans Firebase Auth
      try {
        final user = widget.authController.currentUser;
        if (user != null) {
          await user.updatePhotoURL(photoUrl);
          if (kDebugMode) {
            print('✅ Photo mise à jour dans Firebase Auth');
          }
        }
      } catch (authError) {
        if (kDebugMode) {
          print('⚠️ Erreur lors de la mise à jour Auth: $authError');
        }
        // Non bloquant, l'utilisateur peut toujours utiliser l'app
      }
      
      if (kDebugMode) {
        print('✅ Processus d\'upload terminé');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur upload photo en arrière-plan: $e');
        print('   Type: ${e.runtimeType}');
      }
      // L'erreur est silencieuse car le profil a déjà été créé
    }
  }
}

