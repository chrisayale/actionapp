import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseService.auth;
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      return userData?['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  /// Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      return {
        'uid': user.uid,
        'email': user.email,
        ...userDoc.data()!,
      };
    } catch (e) {
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if any admin exists in the system
  Future<bool> hasAdmin() async {
    try {
      // Essayer d'abord avec une requête where
      try {
        final adminSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .limit(1)
            .get();
        
        if (adminSnapshot.docs.isNotEmpty) {
          return true;
        }
      } catch (e) {
        // Si la requête where échoue (index manquant), essayer de récupérer tous les users
        print('Erreur requête where: $e');
      }
      
      // Fallback: récupérer tous les users et vérifier manuellement
      final allUsersSnapshot = await _firestore
          .collection('users')
          .limit(100)
          .get();
      
      for (var doc in allUsersSnapshot.docs) {
        final data = doc.data();
        if (data['role'] == 'admin') {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('Erreur lors de la vérification admin: $e');
      // En cas d'erreur, on assume qu'il n'y a pas d'admin pour permettre la création
      return false;
    }
  }
}
