import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/repositories/auth_repository.dart';
import 'otp_verification_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authRepository = AuthRepository();
  Country _selectedCountry = Country.parse('CD'); // RDC par défaut
  bool _isLoading = false;
  int _phoneLength = 0;
  final int _maxPhoneLength = 9;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String value) {
    setState(() {
      _phoneLength = value.length;
    });
  }

  Future<void> _handleContinue() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final phoneNumber =
            '+${_selectedCountry.phoneCode}${_phoneController.text}';
        await _authRepository.sendOTP(phoneNumber);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationPage(
                phoneNumber: phoneNumber,
                verificationId: _authRepository.verificationId!,
              ),
            ),
          );
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
                      'Erreur: ${e.toString()}',
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
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre numéro de téléphone';
    }
    if (value.length < 9) {
      return 'Le numéro doit contenir 9 chiffres';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final padding = size.width * 0.06;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: isSmallScreen ? 30 : 60),
                    // Logo Card avec elevation
                    _buildLogoCard(),
                    SizedBox(height: isSmallScreen ? 30 : 50),
                    // Titre et sous-titre
                    _buildHeader(),
                    SizedBox(height: isSmallScreen ? 30 : 50),
                    // Card du formulaire téléphone
                    _buildPhoneCard(),
                    SizedBox(height: isSmallScreen ? 30 : 40),
                    // Bouton Continuer
                    _buildContinueButton(),
                    SizedBox(height: isSmallScreen ? 30 : 40),
                    // Conditions d'utilisation
                    _buildTermsAndConditions(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoCard() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFFFD700),
          width: 8, // Bordure jaune épaisse
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.local_drink,
        size: 70,
        color: Color(0xFFFFD700),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
                Text(
                  'Bienvenue',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
        const SizedBox(height: 16),
                Text(
                  'Entrez votre numéro de téléphone\npour continuer',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
      ],
    );
  }

  Widget _buildPhoneCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Row(
          children: [
            // Sélection du pays
            _buildCountrySelector(),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[200],
            ),
            // Champ de saisie
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Numéro de téléphone',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  suffixText: '$_phoneLength/$_maxPhoneLength',
                  suffixStyle: GoogleFonts.inter(
                    color: _phoneLength >= 9
                        ? const Color(0xFF4CAF50)
                        : Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                maxLength: _maxPhoneLength,
                onChanged: _onPhoneChanged,
                validator: _validatePhone,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountrySelector() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showCountryPicker(
            context: context,
            favorite: ['CD'],
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
    final isEnabled = _phoneLength >= 9 && !_isLoading;

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Card(
        elevation: isEnabled ? 6 : 0,
        shadowColor: const Color(0xFF4CAF50).withOpacity(0.4),
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
                    ],
                  )
                : null,
            color: isEnabled ? null : Colors.grey[300],
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
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
          children: [
            const TextSpan(text: 'En continuant, vous acceptez nos '),
            WidgetSpan(
              child: GestureDetector(
                onTap: () {
                  // TODO: Ouvrir les conditions d'utilisation
                },
                child: const Text(
                  'conditions d\'utilisation',
                  style: TextStyle(
                    color: Color(0xFF2196F3),
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const TextSpan(text: ' et notre '),
            WidgetSpan(
              child: GestureDetector(
                onTap: () {
                  // TODO: Ouvrir la politique de confidentialité
                },
                child: const Text(
                  'politique de confidentialité',
                  style: TextStyle(
                    color: Color(0xFF2196F3),
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
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
