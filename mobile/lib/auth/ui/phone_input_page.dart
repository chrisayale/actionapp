import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth_controller.dart';
import 'otp_verification_page.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/constants/app_constants.dart';

/// Phone number input screen
class PhoneInputPage extends StatefulWidget {
  final AuthController authController;

  const PhoneInputPage({
    super.key,
    required this.authController,
  });

  @override
  State<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends State<PhoneInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  Country _selectedCountry = Country.parse(AppConstants.defaultCountryCode);
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhone);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_validatePhone);
    _phoneController.dispose();
    super.dispose();
  }

  void _validatePhone() {
    final phone = _phoneController.text.trim();
    final isValid = phone.length >= AppConstants.minPhoneLength &&
        phone.length <= AppConstants.maxPhoneLength;
    if (_isValid != isValid) {
      setState(() {
        _isValid = isValid;
      });
    }
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre numéro de téléphone';
    }
    if (value.length < AppConstants.minPhoneLength) {
      return 'Le numéro doit contenir au moins ${AppConstants.minPhoneLength} chiffres';
    }
    if (value.length > AppConstants.maxPhoneLength) {
      return 'Le numéro est trop long';
    }
    return null;
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    widget.authController.clearError();

    final phoneNumber = '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}';
    
    final success = await widget.authController.sendOTP(phoneNumber);

    if (!mounted) return;

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
      // Show error
      final error = widget.authController.errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Title
                Text(
                  'Entrez votre numéro',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                // Subtitle
                Text(
                  'Nous vous enverrons un code de vérification',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 40),
                // Phone Input Card
                _buildPhoneInputCard(),
                const Spacer(),
                // Next Button
                CustomButton(
                  text: 'Suivant',
                  onPressed: _isValid && !widget.authController.isLoading
                      ? _handleNext
                      : null,
                  isLoading: widget.authController.isLoading,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInputCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            // Country Picker
            _buildCountryPicker(),
            // Divider
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[300],
            ),
            const SizedBox(width: 12),
            // Phone Input
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A1A1A),
                ),
                decoration: InputDecoration(
                  hintText: 'Numéro de téléphone',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  errorBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                ),
                validator: _phoneValidator,
                autofocus: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryPicker() {
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
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF25D366),
                    width: 2,
                  ),
                ),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
}


