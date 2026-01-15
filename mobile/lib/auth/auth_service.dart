import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for handling Firebase Phone Authentication
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  int? _resendToken;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Send OTP to phone number
  /// Returns verificationId on success
  Future<String> sendOTP({
    required String phoneNumber,
    Function(String)? onCodeSent,
    Function(FirebaseAuthException)? onError,
    Function(PhoneAuthCredential)? onVerificationCompleted,
  }) async {
    final completer = Completer<String>();
    bool isCompleted = false;

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (Android only)
          if (onVerificationCompleted != null) {
            onVerificationCompleted(credential);
          } else {
            await _auth.signInWithCredential(credential);
          }
          if (!isCompleted && !completer.isCompleted) {
            isCompleted = true;
            // For auto-verification, we don't have a verificationId
            // This case is handled by the onVerificationCompleted callback
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (onError != null) {
            onError(e);
          }
          if (!isCompleted && !completer.isCompleted) {
            isCompleted = true;
            completer.completeError(e);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          if (onCodeSent != null) {
            onCodeSent(verificationId);
          }
          if (!isCompleted && !completer.isCompleted) {
            isCompleted = true;
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          if (!isCompleted && !completer.isCompleted) {
            isCompleted = true;
            completer.complete(verificationId);
          }
        },
        timeout: const Duration(seconds: 60),
      );

      // Wait for the callback to complete
      return await completer.future;
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      rethrow;
    }
  }

  /// Verify OTP code
  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  /// Resend OTP
  Future<String> resendOTP({
    required String phoneNumber,
    Function(String)? onCodeSent,
    Function(FirebaseAuthException)? onError,
  }) async {
    final completer = Completer<String>();
    bool isCompleted = false;

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          // For auto-verification, we don't have a verificationId
          // This case doesn't need resend
        },
        verificationFailed: (FirebaseAuthException e) {
          if (onError != null) {
            onError(e);
          }
          if (!isCompleted && !completer.isCompleted) {
            isCompleted = true;
            completer.completeError(e);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          if (onCodeSent != null) {
            onCodeSent(verificationId);
          }
          if (!isCompleted && !completer.isCompleted) {
            isCompleted = true;
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          if (!isCompleted && !completer.isCompleted) {
            isCompleted = true;
            completer.complete(verificationId);
          }
        },
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),
      );

      // Wait for the callback to complete
      return await completer.future;
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get verification ID (for resend)
  String? get verificationId => _verificationId;
}




