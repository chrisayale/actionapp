import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseService.auth;
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  String? _verificationId;
  
  String? get verificationId => _verificationId;

  Future<UserModel> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        return await _getUserData(userCredential.user!.uid);
      }
      throw Exception('Login failed');
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> register(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        final userModel = UserModel(
          id: userCredential.user!.uid,
          email: email,
          name: name,
        );
        
        await _firestore.collection('users').doc(userModel.id).set(
          userModel.toJson(),
        );
        
        return userModel;
      }
      throw Exception('Registration failed');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await _getUserData(user.uid);
    }
    return null;
  }

  Future<void> sendOTP(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw Exception(e.message ?? 'Erreur de vérification');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> verifyOTP(String verificationId, String code) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        final user = userCredential.user!;
        final phoneNumber = user.phoneNumber ?? '';
        
        // Vérifier si l'utilisateur existe déjà
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (!userDoc.exists) {
          // Créer un nouvel utilisateur
          final userModel = UserModel(
            id: user.uid,
            email: '',
            name: phoneNumber,
          );
          
          await _firestore.collection('users').doc(userModel.id).set(
            userModel.toJson(),
          );
          
          return userModel;
        } else {
          return UserModel.fromJson(userDoc.data()!);
        }
      }
      throw Exception('Vérification échouée');
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> _getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data()!);
    }
    throw Exception('User data not found');
  }
}

