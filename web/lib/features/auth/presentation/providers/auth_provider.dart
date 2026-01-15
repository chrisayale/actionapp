import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();
  User? _user;
  bool _isAdmin = false;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _repository.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        _isAdmin = await _repository.isAdmin();
      } else {
        _isAdmin = false;
      }
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userCredential = await _repository.signInWithEmailAndPassword(
        email,
        password,
      );

      if (userCredential.user != null) {
        _user = userCredential.user;
        _isAdmin = await _repository.isAdmin();

        if (!_isAdmin) {
          await signOut();
          _error = 'Accès refusé. Seuls les administrateurs peuvent se connecter.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _error = 'Échec de la connexion';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _user = null;
    _isAdmin = false;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
