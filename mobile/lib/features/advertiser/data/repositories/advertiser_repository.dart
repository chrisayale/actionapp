import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/establishment_model.dart';
import '../models/promotion_model.dart';

class AdvertiserRepository {
  final FirebaseAuth _auth = FirebaseService.auth;
  final FirebaseStorage _storage = FirebaseService.storage;
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  /// Get Firebase ID Token for authentication
  Future<String?> _getIdToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      return await user.getIdToken();
    } catch (e) {
      return null;
    }
  }

  /// Get promotions for a specific establishment
  Future<List<PromotionModel>> getPromotionsForEstablishment(String establishmentId) async {
    try {
      if (kDebugMode) {
        print('📋 [AdvertiserRepository] Fetching promotions for establishment: $establishmentId');
      }

      // Get promotions directly from Firestore
      final snapshot = await _firestore
          .collection('promotions')
          .where('establishmentId', isEqualTo: establishmentId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      if (kDebugMode) {
        print('✅ [AdvertiserRepository] Found ${snapshot.docs.length} promotions');
      }

      return snapshot.docs.map((doc) {
        return PromotionModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AdvertiserRepository] Error fetching promotions: $e');
      }
      throw Exception('Erreur lors de la récupération des promotions: $e');
    }
  }

  /// Get all public active promotions (no authentication required)
  Future<List<PromotionModel>> getPublicPromotions() async {
    try {
      if (kDebugMode) {
        print('📋 [AdvertiserRepository] Fetching public promotions...');
      }

      // Get active promotions directly from Firestore
      final snapshot = await _firestore
          .collection('promotions')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      if (kDebugMode) {
        print('✅ [AdvertiserRepository] Found ${snapshot.docs.length} public promotions');
      }

      return snapshot.docs.map((doc) {
        return PromotionModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AdvertiserRepository] Error fetching public promotions: $e');
      }
      throw Exception('Erreur lors de la récupération des promotions publiques: $e');
    }
  }

  /// Upload image to Firebase Storage
  Future<String> _uploadImage(Uint8List imageBytes, String path) async {
    try {
      if (kDebugMode) {
        print('📤 [AdvertiserRepository] Uploading to path: $path (${imageBytes.length} bytes)');
      }
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      );

      final uploadTask = ref.putData(imageBytes, metadata);
      await uploadTask;
      
      final url = await ref.getDownloadURL();
      if (kDebugMode) {
        print('✅ [AdvertiserRepository] Upload completed: $url');
      }
      return url;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AdvertiserRepository] Upload failed: $e');
      }
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Create a new establishment
  Future<EstablishmentModel> createEstablishment({
    required String type,
    required String name,
    required Uint8List logoImageBytes,
    required Uint8List enseigneImageBytes,
    Uint8List? documentImageBytes,
    required String ville,
    required String quartier,
    required String avenue,
    required String numero,
    required double latitude,
    required double longitude,
  }) async {
    try {
      if (kDebugMode) {
        print('🚀 [AdvertiserRepository] Starting establishment creation...');
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        print('✅ [AdvertiserRepository] User authenticated: ${user.uid}');
      }

      // Upload images to Firebase Storage
      if (kDebugMode) {
        print('📤 [AdvertiserRepository] Uploading logo image...');
      }
      final logoUrl = await _uploadImage(
        logoImageBytes,
        'establishments/${user.uid}/logo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (kDebugMode) {
        print('✅ [AdvertiserRepository] Logo uploaded: $logoUrl');
      }

      if (kDebugMode) {
        print('📤 [AdvertiserRepository] Uploading enseigne image...');
      }
      final enseigneUrl = await _uploadImage(
        enseigneImageBytes,
        'establishments/${user.uid}/enseigne_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (kDebugMode) {
        print('✅ [AdvertiserRepository] Enseigne uploaded: $enseigneUrl');
      }

      String? documentUrl;
      if (documentImageBytes != null) {
        if (kDebugMode) {
          print('📤 [AdvertiserRepository] Uploading document image...');
        }
        documentUrl = await _uploadImage(
          documentImageBytes,
          'establishments/${user.uid}/document_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        if (kDebugMode) {
          print('✅ [AdvertiserRepository] Document uploaded: $documentUrl');
        }
      }

      // Create establishment directly in Firestore (Firebase en ligne)
      if (kDebugMode) {
        print('💾 [AdvertiserRepository] Saving establishment to Firestore...');
      }

      final establishmentData = {
        'userId': user.uid,
        'type': type,
        'name': name.trim(),
        'logoUrl': logoUrl,
        'enseigneUrl': enseigneUrl,
        'documentUrl': documentUrl,
        'location': {
          'ville': ville.trim(),
          'quartier': quartier.trim(),
          'avenue': avenue.trim(),
          'numero': numero.trim(),
          'latitude': latitude,
          'longitude': longitude,
        },
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (kDebugMode) {
        print('📦 [AdvertiserRepository] Establishment data prepared');
        print('   User ID: ${user.uid}');
        print('   Name: $name');
        print('   Type: $type');
      }

      try {
        // Save directly to Firestore
        final docRef = await _firestore.collection('establishments').add(establishmentData);
        
        if (kDebugMode) {
          print('✅ [AdvertiserRepository] Establishment saved to Firestore');
          print('   Document ID: ${docRef.id}');
        }

        // Get the created document to return complete data
        final createdDoc = await docRef.get();
        if (!createdDoc.exists) {
          throw Exception('Le document n\'a pas été créé avec succès');
        }

        final createdData = createdDoc.data()!;
        final establishment = EstablishmentModel.fromJson({
          'id': docRef.id,
          ...createdData,
        });

        if (kDebugMode) {
          print('✅ [AdvertiserRepository] Establishment created successfully');
          print('   ID: ${establishment.id}');
          print('   Name: ${establishment.name}');
        }

        return establishment;
      } catch (e) {
        if (kDebugMode) {
          print('❌ [AdvertiserRepository] Firestore error: $e');
          print('   Error type: ${e.runtimeType}');
        }
        throw Exception('Erreur lors de la sauvegarde dans Firestore: $e');
      }
    } catch (e) {
      // Handle any other unexpected errors
      if (kDebugMode) {
        print('❌ [AdvertiserRepository] Unexpected error: $e');
        print('   Error type: ${e.runtimeType}');
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erreur inattendue: $e');
    }
  }

  /// Get all establishments for the current user
  Future<List<EstablishmentModel>> getEstablishments() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        print('📋 [AdvertiserRepository] Fetching establishments for user: ${user.uid}');
      }

      // Get establishments directly from Firestore
      final snapshot = await _firestore
          .collection('establishments')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      if (kDebugMode) {
        print('✅ [AdvertiserRepository] Found ${snapshot.docs.length} establishments');
      }

      return snapshot.docs.map((doc) {
        return EstablishmentModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AdvertiserRepository] Error getting establishments: $e');
      }
      throw Exception('Erreur lors de la récupération des établissements: $e');
    }
  }

  /// Get a single establishment by ID
  Future<EstablishmentModel> getEstablishmentById(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        print('📋 [AdvertiserRepository] Fetching establishment: $id');
      }

      final doc = await _firestore.collection('establishments').doc(id).get();

      if (!doc.exists) {
        throw Exception('Establishment not found');
      }

      final data = doc.data()!;
      
      // Verify the establishment belongs to the user
      if (data['userId'] != user.uid) {
        throw Exception('Access denied');
      }

      if (kDebugMode) {
        print('✅ [AdvertiserRepository] Establishment found');
      }

      return EstablishmentModel.fromJson({
        'id': doc.id,
        ...data,
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AdvertiserRepository] Error getting establishment: $e');
      }
      throw Exception('Erreur lors de la récupération de l\'établissement: $e');
    }
  }

  /// Update an establishment
  Future<EstablishmentModel> updateEstablishment({
    required String id,
    String? type,
    String? name,
    Uint8List? logoImageBytes,
    Uint8List? enseigneImageBytes,
    Uint8List? documentImageBytes,
    String? ville,
    String? quartier,
    String? avenue,
    String? numero,
    double? latitude,
    double? longitude,
    bool? isActive,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        print('🔄 [AdvertiserRepository] Updating establishment: $id');
      }

      // Verify the establishment exists and belongs to the user
      final docRef = _firestore.collection('establishments').doc(id);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Establishment not found');
      }

      final data = doc.data()!;
      if (data['userId'] != user.uid) {
        throw Exception('Access denied');
      }

      final Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (type != null) updateData['type'] = type;
      if (name != null) updateData['name'] = name.trim();

      // Upload new images if provided
      if (logoImageBytes != null) {
        updateData['logoUrl'] = await _uploadImage(
          logoImageBytes,
          'establishments/${user.uid}/logo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      if (enseigneImageBytes != null) {
        updateData['enseigneUrl'] = await _uploadImage(
          enseigneImageBytes,
          'establishments/${user.uid}/enseigne_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      if (documentImageBytes != null) {
        updateData['documentUrl'] = await _uploadImage(
          documentImageBytes,
          'establishments/${user.uid}/document_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      // Update location if any location field is provided
      if (ville != null || quartier != null || avenue != null || 
          numero != null || latitude != null || longitude != null) {
        final currentLocation = data['location'] as Map<String, dynamic>? ?? {};
        updateData['location'] = {
          ...currentLocation,
          if (ville != null) 'ville': ville.trim(),
          if (quartier != null) 'quartier': quartier.trim(),
          if (avenue != null) 'avenue': avenue.trim(),
          if (numero != null) 'numero': numero.trim(),
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        };
      }

      if (isActive != null) updateData['isActive'] = isActive;

      // Update in Firestore
      await docRef.update(updateData);

      // Get the updated document
      final updatedDoc = await docRef.get();
      final updatedData = updatedDoc.data()!;

      if (kDebugMode) {
        print('✅ [AdvertiserRepository] Establishment updated successfully');
      }

      return EstablishmentModel.fromJson({
        'id': updatedDoc.id,
        ...updatedData,
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AdvertiserRepository] Error updating establishment: $e');
      }
      throw Exception('Erreur lors de la mise à jour de l\'établissement: $e');
    }
  }

  /// Delete an establishment
  Future<void> deleteEstablishment(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        print('🗑️ [AdvertiserRepository] Deleting establishment: $id');
      }

      // Verify the establishment exists and belongs to the user
      final docRef = _firestore.collection('establishments').doc(id);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Establishment not found');
      }

      final data = doc.data()!;
      if (data['userId'] != user.uid) {
        throw Exception('Access denied');
      }

      // Delete from Firestore
      await docRef.delete();

      if (kDebugMode) {
        print('✅ [AdvertiserRepository] Establishment deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AdvertiserRepository] Error deleting establishment: $e');
      }
      throw Exception('Erreur lors de la suppression de l\'établissement: $e');
    }
  }

  /// Create a new promotion
  Future<PromotionModel> createPromotion({
    required String establishmentId,
    required String establishmentName,
    String? establishmentLogoUrl,
    required String boissonId,
    required String boissonName,
    String? boissonImageUrl,
    required String formule,
    Uint8List? imageBytes,
    String? imageUrl, // Use this if imageBytes is null
    double? price,
    String? currency,
    required DateTime startDate,
    required DateTime endDate,
    bool isUnlimited = false,
  }) async {
    try {
      if (kDebugMode) {
        print('🚀 [AdvertiserRepository] Starting promotion creation...');
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      String? finalImageUrl = imageUrl;

      // Upload image if provided
      if (imageBytes != null) {
        if (kDebugMode) {
          print('📤 [AdvertiserRepository] Uploading promotion image...');
        }
        finalImageUrl = await _uploadImage(
          imageBytes,
          'promotions/${user.uid}/${establishmentId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        if (kDebugMode) {
          print('✅ [AdvertiserRepository] Promotion image uploaded: $finalImageUrl');
        }
      }

      // Create promotion directly in Firestore (Firebase en ligne)
      if (kDebugMode) {
        print('💾 [AdvertiserRepository] Saving promotion to Firestore...');
      }

      final promotionData = {
        'userId': user.uid,
        'establishmentId': establishmentId,
        'establishmentName': establishmentName,
        'establishmentLogoUrl': establishmentLogoUrl,
        'boissonId': boissonId,
        'boissonName': boissonName,
        'boissonImageUrl': boissonImageUrl,
        'formule': formule,
        'imageUrl': finalImageUrl,
        'price': price,
        'currency': currency ?? 'CDF',
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'isUnlimited': isUnlimited,
        'isActive': true,
        'interestedCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (kDebugMode) {
        print('📦 [AdvertiserRepository] Promotion data prepared');
        print('   Establishment ID: $establishmentId');
        print('   Formule: $formule');
      }

      try {
        // Save directly to Firestore
        final docRef = await _firestore.collection('promotions').add(promotionData);
        
        if (kDebugMode) {
          print('✅ [AdvertiserRepository] Promotion saved to Firestore');
          print('   Document ID: ${docRef.id}');
        }

        // Get the created document to return complete data
        final createdDoc = await docRef.get();
        if (!createdDoc.exists) {
          throw Exception('Le document n\'a pas été créé avec succès');
        }

        final createdData = createdDoc.data()!;
        final promotion = PromotionModel.fromJson({
          'id': docRef.id,
          ...createdData,
        });

        if (kDebugMode) {
          print('✅ [AdvertiserRepository] Promotion created successfully');
          print('   ID: ${promotion.id}');
          print('   Formule: ${promotion.formule}');
        }

        return promotion;
      } catch (e) {
        if (kDebugMode) {
          print('❌ [AdvertiserRepository] Firestore error: $e');
        }
        throw Exception('Erreur lors de la sauvegarde dans Firestore: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AdvertiserRepository] Unexpected error: $e');
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erreur inattendue: $e');
    }
  }

  /// Toggle interested count (like button - toggle behavior) - Requires authentication
  Future<PromotionModel> toggleInterestedCount(String promotionId) async {
    try {
      if (kDebugMode) {
        print('👍 [AdvertiserRepository] Toggling interested count for promotion: $promotionId');
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user has already liked this promotion
      final userLikeRef = _firestore
          .collection('promotions')
          .doc(promotionId)
          .collection('interestedUsers')
          .doc(user.uid);

      final userLikeDoc = await userLikeRef.get();
      final hasLiked = userLikeDoc.exists;

      // Get the promotion document
      final promotionRef = _firestore.collection('promotions').doc(promotionId);
      final promotionDoc = await promotionRef.get();

      if (!promotionDoc.exists) {
        throw Exception('Promotion not found');
      }

      final currentData = promotionDoc.data()!;
      final currentCount = (currentData['interestedCount'] as int?) ?? 0;

      // Toggle: if user has liked, remove like (decrement), otherwise add like (increment)
      final newCount = hasLiked ? currentCount - 1 : currentCount + 1;

      // Update the promotion's interestedCount
      await promotionRef.update({
        'interestedCount': newCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update the user's like status
      if (hasLiked) {
        await userLikeRef.delete();
      } else {
        await userLikeRef.set({
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Get the updated promotion
      final updatedDoc = await promotionRef.get();
      final updatedData = updatedDoc.data()!;

      if (kDebugMode) {
        print('✅ [AdvertiserRepository] Interested count toggled. New count: $newCount');
      }

      return PromotionModel.fromJson({
        'id': updatedDoc.id,
        ...updatedData,
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AdvertiserRepository] Error toggling interested count: $e');
      }
      throw Exception('Erreur lors du toggle du compteur intéressé: $e');
    }
  }

  /// Increment view count for a promotion (no authentication required)
  Future<void> incrementViewCount(String promotionId) async {
    try {
      if (kDebugMode) {
        print('👁️ [AdvertiserRepository] Incrementing view count for promotion: $promotionId');
      }

      // Use FieldValue.increment for atomic increment
      await _firestore.collection('promotions').doc(promotionId).update({
        'viewCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ [AdvertiserRepository] View count incremented successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AdvertiserRepository] Error incrementing view count: $e');
      }
      // Don't throw error - view count increment is not critical
      // Just log it silently
    }
  }
}

