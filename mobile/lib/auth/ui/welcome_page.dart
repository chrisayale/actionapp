import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:country_picker/country_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth_controller.dart';
import 'otp_verification_page.dart';
import '../../core/constants/app_constants.dart';

/// Welcome screen - First screen shown to user with phone input
class WelcomePage extends StatefulWidget {
  final AuthController authController;

  const WelcomePage({
    super.key,
    required this.authController,
  });

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  Country _selectedCountry = Country.parse(AppConstants.defaultCountryCode);
  bool _isLoading = false;
  int _phoneLength = 0;
  final int _maxPhoneLength = 9;
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {
        _phoneLength = _phoneController.text.length;
      });
    });

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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _colorAnimation = ColorTween(
      begin: const Color(0xFFFFD700),
      end: const Color(0xFFFF6B35),
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre numéro de téléphone';
    }
    if (value.length < _maxPhoneLength) {
      return 'Le numéro doit contenir $_maxPhoneLength chiffres';
    }
    return null;
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    widget.authController.clearError();
    setState(() => _isLoading = true);

    final phoneNumber = '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}';
    
    final success = await widget.authController.sendOTP(phoneNumber);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success && widget.authController.verificationId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OTPVerificationPage(
            authController: widget.authController,
            phoneNumber: phoneNumber,
          ),
        ),
      );
    } else {
      final error = widget.authController.errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    error,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
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
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: isSmallScreen ? 40 : 60),
                // Logo with elevation and glow
                _buildLogoCard(),
                SizedBox(height: isSmallScreen ? 32 : 48),
                // Welcome Header
                _buildHeader(),
                SizedBox(height: isSmallScreen ? 32 : 48),
                // Phone Input Card with elevation
                _buildPhoneInputCard(),
                SizedBox(height: isSmallScreen ? 32 : 40),
                // Continue Button with elevation
                _buildContinueButton(),
                SizedBox(height: isSmallScreen ? 32 : 40),
                // Terms and Conditions
                _buildTermsAndConditions(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoCard() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: _colorAnimation.value ?? const Color(0xFFFFD700),
                width: 6,
              ),
              boxShadow: [
                // Vibrant animated glow effect
                BoxShadow(
                  color: (_colorAnimation.value ?? const Color(0xFFFFD700))
                      .withOpacity(_glowAnimation.value),
                  blurRadius: 40,
                  spreadRadius: 8,
                  offset: const Offset(0, 0),
                ),
                // Secondary glow with complementary color
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(_glowAnimation.value * 0.5),
                  blurRadius: 35,
                  spreadRadius: 6,
                  offset: const Offset(0, 0),
                ),
                // Elevation shadow
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/images/logo.png',
                width: 70,
                height: 70,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback si l'image n'existe pas encore
                  return Icon(
                    Icons.local_drink,
                    size: 70,
                    color: _colorAnimation.value ?? const Color(0xFFFFD700),
                  );
                },
              ),
            ),
          ),
        );
      },
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
                'Bienvenue',
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1.2,
                  shadows: [
                    Shadow(
                      color: const Color(0xFFFFD700).withOpacity(0.5 * _glowAnimation.value),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Entrez votre numéro de téléphone\npour continuer',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhoneInputCard() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Card(
          elevation: 12,
          shadowColor: const Color(0xFF4CAF50).withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2196F3).withOpacity(0.1 * _glowAnimation.value),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
        child: Row(
          children: [
            // Country Selector
            _buildCountrySelector(),
            Container(
              width: 1,
              height: 44,
              color: Colors.grey[200],
            ),
            // Phone Input Field
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Numéro de téléphone',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  suffixText: '$_phoneLength/$_maxPhoneLength',
                  suffixStyle: GoogleFonts.inter(
                    color: _phoneLength >= _maxPhoneLength
                        ? const Color(0xFF4CAF50)
                        : Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                maxLength: _maxPhoneLength,
                validator: _validatePhone,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (_phoneLength >= _maxPhoneLength) {
                    _handleContinue();
                  }
                },
              ),
            ),
          ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildCountrySelector() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showCountryPicker(
            context: context,
            favorite: [AppConstants.defaultCountryCode],
            showPhoneCode: true,
            onSelect: (Country country) {
              setState(() {
                _selectedCountry = country;
              });
            },
            countryListTheme: CountryListThemeData(
              flagSize: 25,
              backgroundColor: Colors.white,
              textStyle: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              searchTextStyle: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.black87,
              ),
              inputDecoration: InputDecoration(
                labelText: 'Rechercher un pays',
                hintText: 'Entrez le nom du pays',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF4CAF50),
                    width: 2,
                  ),
                ),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_drop_down,
                color: Colors.grey[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedCountry.flagEmoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 10),
              Text(
                '+${_selectedCountry.phoneCode}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final isEnabled = _phoneLength >= _maxPhoneLength && !_isLoading;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SizedBox(
          width: double.infinity,
          height: 58,
          child: Card(
            elevation: isEnabled ? 12 : 0,
            shadowColor: isEnabled 
                ? const Color(0xFF4CAF50).withOpacity(0.4 * _glowAnimation.value)
                : Colors.grey.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isEnabled
                    ? LinearGradient(
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
                      )
                    : null,
                color: isEnabled ? null : Colors.grey[300],
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.5 * _glowAnimation.value),
                          blurRadius: 20,
                          spreadRadius: 4,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: const Color(0xFF2196F3).withOpacity(0.3 * _glowAnimation.value),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isEnabled ? _handleContinue : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Continuer',
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

  Widget _buildTermsAndConditions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'En continuant, vous acceptez nos '),
            TextSpan(
              text: 'conditions d\'utilisation',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2196F3),
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF2196F3),
                height: 1.5,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // TODO: Ouvrir les conditions d'utilisation
                },
            ),
            const TextSpan(text: ' et notre '),
            TextSpan(
              text: 'politique de confidentialité',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2196F3),
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF2196F3),
                height: 1.5,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // TODO: Ouvrir la politique de confidentialité
                },
            ),
          ],
        ),
      ),
    );
  }
}
