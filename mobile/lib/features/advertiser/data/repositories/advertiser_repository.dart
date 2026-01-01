import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/establishment_model.dart';
import '../models/promotion_model.dart';

class AdvertiserRepository {
  final FirebaseAuth _auth = FirebaseService.auth;
  final FirebaseStorage _storage = FirebaseService.storage;

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

      final idToken = await _getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get authentication token');
      }

      if (kDebugMode) {
        print('✅ [AdvertiserRepository] ID Token obtained');
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

      // Create establishment via backend API
      final apiUrl = '${ApiConstants.baseUrl}${ApiConstants.advertisers}';
      if (kDebugMode) {
        print('🌐 [AdvertiserRepository] Sending POST request to: $apiUrl');
      }

      final requestBody = {
        'type': type,
        'name': name,
        'logoUrl': logoUrl,
        'enseigneUrl': enseigneUrl,
        'documentUrl': documentUrl,
        'ville': ville,
        'quartier': quartier,
        'avenue': avenue,
        'numero': numero,
        'latitude': latitude,
        'longitude': longitude,
      };

      if (kDebugMode) {
        print('📦 [AdvertiserRepository] Request body: ${jsonEncode(requestBody).substring(0, 200)}...');
      }

      if (kDebugMode) {
        print('⏳ [AdvertiserRepository] Attempting connection to: $apiUrl');
      }

      // Use http.Client with timeout for better control
      final client = http.Client();
      try {
        final response = await client
            .post(
              Uri.parse(apiUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $idToken',
              },
              body: jsonEncode(requestBody),
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                if (kDebugMode) {
                  print('❌ [AdvertiserRepository] Request timeout after 30 seconds');
                  print('   This usually means the server is not reachable');
                  print('   Check that the backend is running on port 3000');
                }
                throw Exception('Timeout: Le serveur ne répond pas après 30 secondes.\n\n'
                    'Vérifiez que:\n'
                    '1. Le backend est démarré (cd backend && npm run dev)\n'
                    '2. Le backend écoute sur le port 3000\n'
                    '3. L\'émulateur peut accéder à http://10.0.2.2:3000');
              },
            );
        
        if (kDebugMode) {
          print('📥 [AdvertiserRepository] Response received');
          print('   Status: ${response.statusCode}');
          print('   Body: ${response.body.substring(0, math.min(response.body.length, 500))}');
        }

        client.close();
        
        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            return EstablishmentModel.fromJson(data['establishment']);
          } else {
            throw Exception(data['error'] ?? 'Failed to create establishment');
          }
        } else {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'Failed to create establishment');
        }
      } catch (e) {
        client.close();
        if (kDebugMode) {
          print('❌ [AdvertiserRepository] Connection error: $e');
          print('   Error type: ${e.runtimeType}');
        }
        if (e.toString().contains('Connection refused') || 
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('SocketException') ||
            e.toString().contains('Network is unreachable') ||
            e.toString().contains('Timeout')) {
          throw Exception(
            'Impossible de se connecter au serveur.\n\n'
            'Vérifiez que:\n'
            '1. Le backend est démarré (cd backend && npm run dev)\n'
            '2. Le backend écoute sur le port 3000\n'
            '3. L\'émulateur peut accéder à http://10.0.2.2:3000\n\n'
            'URL: $apiUrl\n'
            'Erreur: $e'
          );
        }
        throw e;
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
      final idToken = await _getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get authentication token');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.advertisers}'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> establishments = data['establishments'] ?? [];
          return establishments
              .map((e) => EstablishmentModel.fromJson(e))
              .toList();
        } else {
          throw Exception(data['error'] ?? 'Failed to get establishments');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get establishments');
      }
    } on SocketException {
      throw Exception(
        'Impossible de se connecter au serveur backend.\n\n'
        'Le backend doit être démarré sur le port 3000.\n'
        'Pour démarrer le backend:\n'
        '1. Ouvrez un terminal\n'
        '2. cd backend\n'
        '3. npm run dev\n\n'
        'URL attendue: ${ApiConstants.baseUrl}${ApiConstants.advertisers}'
      );
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('Failed to fetch') || 
          errorMsg.contains('ClientException') ||
          errorMsg.contains('Connection refused') ||
          errorMsg.contains('Network is unreachable')) {
        throw Exception(
          'Impossible de se connecter au serveur backend.\n\n'
          'Le backend doit être démarré sur le port 3000.\n'
          'Pour démarrer le backend:\n'
          '1. Ouvrez un terminal\n'
          '2. cd backend\n'
          '3. npm run dev\n\n'
          'URL attendue: ${ApiConstants.baseUrl}${ApiConstants.advertisers}'
        );
      }
      rethrow;
    }
  }

  /// Get a single establishment by ID
  Future<EstablishmentModel> getEstablishmentById(String id) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get authentication token');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.advertisers}/$id'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return EstablishmentModel.fromJson(data['establishment']);
        } else {
          throw Exception(data['error'] ?? 'Failed to get establishment');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get establishment');
      }
    } on SocketException {
      throw Exception(
        'Impossible de se connecter au serveur backend.\n\n'
        'Le backend doit être démarré sur le port 3000.\n'
        'Pour démarrer le backend:\n'
        '1. Ouvrez un terminal\n'
        '2. cd backend\n'
        '3. npm run dev\n\n'
        'URL attendue: ${ApiConstants.baseUrl}${ApiConstants.advertisers}/$id'
      );
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('Failed to fetch') || 
          errorMsg.contains('ClientException') ||
          errorMsg.contains('Connection refused') ||
          errorMsg.contains('Network is unreachable')) {
        throw Exception(
          'Impossible de se connecter au serveur backend.\n\n'
          'Le backend doit être démarré sur le port 3000.\n'
          'Pour démarrer le backend:\n'
          '1. Ouvrez un terminal\n'
          '2. cd backend\n'
          '3. npm run dev\n\n'
          'URL attendue: ${ApiConstants.baseUrl}${ApiConstants.advertisers}/$id'
        );
      }
      rethrow;
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
      final idToken = await _getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get authentication token');
      }

      final Map<String, dynamic> updateData = {};

      if (type != null) updateData['type'] = type;
      if (name != null) updateData['name'] = name;

      // Upload new images if provided
      if (logoImageBytes != null) {
        final user = _auth.currentUser;
        if (user != null) {
          updateData['logoUrl'] = await _uploadImage(
            logoImageBytes,
            'establishments/${user.uid}/logo_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        }
      }

      if (enseigneImageBytes != null) {
        final user = _auth.currentUser;
        if (user != null) {
          updateData['enseigneUrl'] = await _uploadImage(
            enseigneImageBytes,
            'establishments/${user.uid}/enseigne_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        }
      }

      if (documentImageBytes != null) {
        final user = _auth.currentUser;
        if (user != null) {
          updateData['documentUrl'] = await _uploadImage(
            documentImageBytes,
            'establishments/${user.uid}/document_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        }
      }

      if (ville != null) updateData['ville'] = ville;
      if (quartier != null) updateData['quartier'] = quartier;
      if (avenue != null) updateData['avenue'] = avenue;
      if (numero != null) updateData['numero'] = numero;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (isActive != null) updateData['isActive'] = isActive;

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.advertisers}/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return EstablishmentModel.fromJson(data['establishment']);
        } else {
          throw Exception(data['error'] ?? 'Failed to update establishment');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update establishment');
      }
    } on SocketException {
      throw Exception(
        'Impossible de se connecter au serveur backend.\n\n'
        'Le backend doit être démarré sur le port 3000.\n'
        'Pour démarrer le backend:\n'
        '1. Ouvrez un terminal\n'
        '2. cd backend\n'
        '3. npm run dev\n\n'
        'URL attendue: ${ApiConstants.baseUrl}${ApiConstants.advertisers}/$id'
      );
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('Failed to fetch') || 
          errorMsg.contains('ClientException') ||
          errorMsg.contains('Connection refused') ||
          errorMsg.contains('Network is unreachable')) {
        throw Exception(
          'Impossible de se connecter au serveur backend.\n\n'
          'Le backend doit être démarré sur le port 3000.\n'
          'Pour démarrer le backend:\n'
          '1. Ouvrez un terminal\n'
          '2. cd backend\n'
          '3. npm run dev\n\n'
          'URL attendue: ${ApiConstants.baseUrl}${ApiConstants.advertisers}/$id'
        );
      }
      rethrow;
    }
  }

  /// Delete an establishment
  Future<void> deleteEstablishment(String id) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get authentication token');
      }

      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.advertisers}/$id'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] != true) {
          throw Exception(data['error'] ?? 'Failed to delete establishment');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete establishment');
      }
    } on SocketException {
      throw Exception(
        'Impossible de se connecter au serveur backend.\n\n'
        'Le backend doit être démarré sur le port 3000.\n'
        'Pour démarrer le backend:\n'
        '1. Ouvrez un terminal\n'
        '2. cd backend\n'
        '3. npm run dev\n\n'
        'URL attendue: ${ApiConstants.baseUrl}${ApiConstants.advertisers}/$id'
      );
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('Failed to fetch') || 
          errorMsg.contains('ClientException') ||
          errorMsg.contains('Connection refused') ||
          errorMsg.contains('Network is unreachable')) {
        throw Exception(
          'Impossible de se connecter au serveur backend.\n\n'
          'Le backend doit être démarré sur le port 3000.\n'
          'Pour démarrer le backend:\n'
          '1. Ouvrez un terminal\n'
          '2. cd backend\n'
          '3. npm run dev\n\n'
          'URL attendue: ${ApiConstants.baseUrl}${ApiConstants.advertisers}/$id'
        );
      }
      rethrow;
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
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (kDebugMode) {
        print('🚀 [AdvertiserRepository] Starting promotion creation...');
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final idToken = await _getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get authentication token');
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

      // Create promotion via backend API
      final apiUrl = '${ApiConstants.baseUrl}${ApiConstants.promotions}';
      if (kDebugMode) {
        print('🌐 [AdvertiserRepository] Sending POST request to: $apiUrl');
      }

      final requestBody = {
        'establishmentId': establishmentId,
        'establishmentName': establishmentName,
        'establishmentLogoUrl': establishmentLogoUrl,
        'boissonId': boissonId,
        'boissonName': boissonName,
        'boissonImageUrl': boissonImageUrl,
        'formule': formule,
        'imageUrl': finalImageUrl,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

      if (kDebugMode) {
        print('📦 [AdvertiserRepository] Request body: ${jsonEncode(requestBody)}');
      }

      final client = http.Client();
      try {
        final response = await client
            .post(
              Uri.parse(apiUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $idToken',
              },
              body: jsonEncode(requestBody),
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                if (kDebugMode) {
                  print('❌ [AdvertiserRepository] Request timeout after 30 seconds');
                }
                throw Exception('Timeout: Le serveur ne répond pas après 30 secondes.\n\n'
                    'Vérifiez que:\n'
                    '1. Le backend est démarré (cd backend && npm run dev)\n'
                    '2. Le backend écoute sur le port 3000\n'
                    '3. L\'émulateur peut accéder au backend');
              },
            );

        if (kDebugMode) {
          print('📥 [AdvertiserRepository] Response received');
          print('   Status: ${response.statusCode}');
          print('   Body: ${response.body.substring(0, math.min(response.body.length, 500))}');
        }

        client.close();

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            return PromotionModel.fromJson(data['promotion']);
          } else {
            throw Exception(data['error'] ?? 'Failed to create promotion');
          }
        } else {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'Failed to create promotion');
        }
      } catch (e) {
        client.close();
        if (kDebugMode) {
          print('❌ [AdvertiserRepository] Connection error: $e');
        }
        if (e.toString().contains('Connection refused') ||
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('SocketException') ||
            e.toString().contains('Network is unreachable') ||
            e.toString().contains('Timeout')) {
          throw Exception(
            'Impossible de se connecter au serveur.\n\n'
            'Vérifiez que:\n'
            '1. Le backend est démarré (cd backend && npm run dev)\n'
            '2. Le backend écoute sur le port 3000\n'
            '3. L\'émulateur peut accéder au backend\n\n'
            'URL: $apiUrl\n'
            'Erreur: $e',
          );
        }
        throw e;
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
}

