import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

/// Controller for managing authentication state
class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  /// Expose authService for auth state changes
  AuthService get authService => _authService;

  // State
  bool _isLoading = false;
  String? _errorMessage;
  String? _verificationId;
  String? _phoneNumber;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get verificationId => _verificationId;
  String? get phoneNumber => _phoneNumber;
  User? get currentUser => _authService.currentUser;

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Send OTP to phone number
  Future<bool> sendOTP(String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    _phoneNumber = phoneNumber;
    notifyListeners();

    try {
      _verificationId = await _authService.sendOTP(
        phoneNumber: phoneNumber,
        onError: (FirebaseAuthException e) {
          _errorMessage = _getErrorMessage(e);
          _isLoading = false;
          notifyListeners();
        },
      );

      _isLoading = false;
      if (_verificationId != null) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify OTP code
  Future<bool> verifyOTP(String code) async {
    if (_verificationId == null) {
      _errorMessage = 'Verification ID not found';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.verifyOTP(
        verificationId: _verificationId!,
        smsCode: code,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is FirebaseAuthException) {
        _errorMessage = _getErrorMessage(e);
      } else {
        _errorMessage = e.toString();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Resend OTP
  Future<bool> resendOTP() async {
    if (_phoneNumber == null) {
      _errorMessage = 'Phone number not found';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _verificationId = await _authService.resendOTP(
        phoneNumber: _phoneNumber!,
        onError: (FirebaseAuthException e) {
          _errorMessage = _getErrorMessage(e);
          _isLoading = false;
          notifyListeners();
        },
      );

      _isLoading = false;
      if (_verificationId != null) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Le numéro de téléphone est invalide';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard';
      case 'quota-exceeded':
        return 'Quota de SMS dépassé. Contactez le support';
      case 'invalid-verification-code':
        return 'Code de vérification invalide';
      case 'session-expired':
        return 'La session a expiré. Veuillez réessayer';
      default:
        return e.message ?? 'Une erreur est survenue';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _verificationId = null;
    _phoneNumber = null;
    _errorMessage = null;
    notifyListeners();
  }
}

