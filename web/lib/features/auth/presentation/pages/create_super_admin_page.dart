import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../providers/auth_provider.dart' as auth_provider;

class CreateSuperAdminPage extends StatefulWidget {
  const CreateSuperAdminPage({super.key});

  @override
  State<CreateSuperAdminPage> createState() => _CreateSuperAdminPageState();
}

class _CreateSuperAdminPageState extends State<CreateSuperAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isChecking = true;
  bool _hasAdmin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAdminExists();
  }

  Future<void> _checkAdminExists() async {
    try {
      final hasAdmin = await _authRepository.hasAdmin();
      setState(() {
        _hasAdmin = hasAdmin;
        _isChecking = false;
      });
      
      if (hasAdmin && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      setState(() {
        _hasAdmin = false;
        _isChecking = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? _validatePasswordMatch(String? value) {
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'operation-not-allowed':
          return 'L\'authentification par email/mot de passe n\'est pas activée dans Firebase.\n\n'
              'Pour résoudre ce problème :\n'
              '1. Allez sur https://console.firebase.google.com\n'
              '2. Sélectionnez votre projet\n'
              '3. Allez dans "Authentication" > "Sign-in method"\n'
              '4. Activez "Email/Password"\n'
              '5. Cliquez sur "Save"\n'
              '6. Réessayez de créer le super administrateur';
        case 'email-already-in-use':
          return 'Cet email est déjà utilisé par un autre compte.';
        case 'invalid-email':
          return 'L\'adresse email n\'est pas valide.';
        case 'weak-password':
          return 'Le mot de passe est trop faible. Utilisez au moins 6 caractères.';
        case 'network-request-failed':
          return 'Erreur de connexion réseau. Vérifiez votre connexion internet.';
        case 'too-many-requests':
          return 'Trop de tentatives. Veuillez patienter quelques instants avant de réessayer.';
        default:
          return error.message ?? 'Une erreur est survenue lors de la création du compte.';
      }
    }
    
    final errorString = error.toString();
    if (errorString.contains('operation-not-allowed')) {
      return 'L\'authentification par email/mot de passe n\'est pas activée dans Firebase.\n\n'
          'Pour résoudre ce problème :\n'
          '1. Allez sur https://console.firebase.google.com\n'
          '2. Sélectionnez votre projet\n'
          '3. Allez dans "Authentication" > "Sign-in method"\n'
          '4. Activez "Email/Password"\n'
          '5. Cliquez sur "Save"\n'
          '6. Réessayez de créer le super administrateur';
    }
    
    return errorString.replaceFirst('Exception: ', '').replaceFirst('FirebaseAuthException: ', '');
  }

  Future<void> _createSuperAdmin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userCredential = await FirebaseService.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (userCredential?.user != null) {
        await FirebaseService.firestore
            .collection('users')
            .doc(userCredential!.user!.uid)
            .set({
          'email': _emailController.text.trim(),
          'displayName': _nameController.text.trim(),
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
        await authProvider.signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = _getErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (_isChecking) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.yellowPrimary,
                AppColors.yellowDark,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
            ),
          ),
        ),
      );
    }

    if (_hasAdmin) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.yellowPrimary,
                AppColors.yellowDark,
              ],
            ),
          ),
          child: const Center(
            child: Text(
              'Un administrateur existe déjà',
              style: TextStyle(color: AppColors.black, fontSize: 18),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.yellowPrimary,
              AppColors.yellowDark,
              AppColors.yellowAccent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 20 : 40),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  elevation: 24,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(isMobile ? 32 : 48),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo
                          Center(
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppColors.yellowLight,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.yellowPrimary.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.admin_panel_settings,
                                    size: 60,
                                    color: AppColors.yellowPrimary,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Title
                          Text(
                            'Création du Super Administrateur',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 26 : 32,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          
                          // Subtitle
                          Text(
                            'Première configuration de la plateforme',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 14 : 16,
                              color: AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          
                          // Error message
                          if (_error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.error.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.error_outline_rounded,
                                          color: AppColors.error,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Erreur de configuration',
                                          style: GoogleFonts.inter(
                                            color: AppColors.error,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _error!,
                                    style: GoogleFonts.inter(
                                      color: AppColors.error,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      height: 1.5,
                                    ),
                                  ),
                                  if (_error!.contains('console.firebase.google.com')) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.yellowLight,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.yellowPrimary.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            color: AppColors.yellowDark,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Après avoir activé l\'authentification, rechargez cette page.',
                                              style: GoogleFonts.inter(
                                                color: AppColors.black,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          // Name field
                          TextFormField(
                            controller: _nameController,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppColors.textPrimaryLight,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Nom complet',
                              labelStyle: GoogleFonts.inter(
                                color: AppColors.textSecondaryLight,
                              ),
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: AppColors.yellowPrimary,
                              ),
                              filled: true,
                              fillColor: AppColors.gray50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.borderLight,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.borderLight,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.yellowPrimary,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.error,
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.error,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Le nom est requis';
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 20),
                          
                          // Email field
                          TextFormField(
                            controller: _emailController,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppColors.textPrimaryLight,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: GoogleFonts.inter(
                                color: AppColors.textSecondaryLight,
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppColors.yellowPrimary,
                              ),
                              filled: true,
                              fillColor: AppColors.gray50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.borderLight,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.borderLight,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.yellowPrimary,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.error,
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.error,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: Validators.email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 20),
                          
                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppColors.textPrimaryLight,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              labelStyle: GoogleFonts.inter(
                                color: AppColors.textSecondaryLight,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: AppColors.yellowPrimary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.textSecondaryLight,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: AppColors.gray50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.borderLight,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.borderLight,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.yellowPrimary,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.error,
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.error,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: Validators.password,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 20),
                          
                          // Confirm password field
                          TextFormField(
                            controller: _confirmPasswordController,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppColors.textPrimaryLight,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Confirmer le mot de passe',
                              labelStyle: GoogleFonts.inter(
                                color: AppColors.textSecondaryLight,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: AppColors.yellowPrimary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.textSecondaryLight,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: AppColors.gray50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.borderLight,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.borderLight,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.yellowPrimary,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.error,
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.error,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: _validatePasswordMatch,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _createSuperAdmin(),
                          ),
                          const SizedBox(height: 32),
                          
                          // Submit button
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.yellowPrimary,
                                  AppColors.yellowDark,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.yellowPrimary.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _createSuperAdmin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.black,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Créer le Super Administrateur',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.black,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
