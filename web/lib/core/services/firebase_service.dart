import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Auth getters
  static FirebaseAuth get auth => _auth;
  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Firestore getters
  static FirebaseFirestore get firestore => _firestore;
  static CollectionReference get usersCollection => _firestore.collection('users');
  static CollectionReference get ordersCollection => _firestore.collection('orders');

  // Storage getters
  static FirebaseStorage get storage => _storage;
  static Reference get storageRef => _storage.ref();

  // Helper methods
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }
}

