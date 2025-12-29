import 'package:permission_handler/permission_handler.dart' hide openAppSettings;
import 'package:permission_handler/permission_handler.dart' as ph show openAppSettings;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

/// Service pour gérer les permissions de l'application
class PermissionService {
  /// Demande la permission de la caméra
  static Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      
      if (kDebugMode) {
        print('📷 Statut permission caméra: $status');
      }
      
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la demande de permission caméra: $e');
      }
      return false;
    }
  }

  /// Vérifie si la permission de la caméra est accordée
  static Future<bool> isCameraPermissionGranted() async {
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la vérification de permission caméra: $e');
      }
      return false;
    }
  }

  /// Demande la permission de la galerie de photos
  static Future<bool> requestPhotoLibraryPermission() async {
    try {
      // Sur le web, les permissions sont gérées automatiquement par le navigateur
      // lors de la sélection d'image, donc on retourne true
      if (kIsWeb) {
        if (kDebugMode) {
          print('🖼️ Web: Les permissions photos sont gérées par le navigateur');
        }
        return true;
      }
      
      // Pour Android 13+ (API 33+), utiliser photos
      // Pour les versions antérieures, utiliser storage
      PermissionStatus status;
      
      try {
        status = await Permission.photos.request();
        if (status.isGranted) {
          if (kDebugMode) {
            print('🖼️ Statut permission photos: $status');
          }
          return true;
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Permission.photos non supporté, tentative avec storage...');
        }
      }
      
      // Essayer storage seulement si on n'est pas sur le web
      try {
        status = await Permission.storage.request();
        if (kDebugMode) {
          print('🖼️ Statut permission storage: $status');
        }
        return status.isGranted;
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Permission.storage non supporté sur cette plateforme');
        }
        // Si aucune permission n'est supportée, retourner true
        // car le système gérera les permissions automatiquement
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la demande de permission photos: $e');
      }
      // En cas d'erreur, retourner true pour ne pas bloquer l'utilisateur
      // Le système gérera les permissions automatiquement
      return true;
    }
  }

  /// Vérifie si la permission de la galerie est accordée
  static Future<bool> isPhotoLibraryPermissionGranted() async {
    try {
      // Sur le web, les permissions sont gérées automatiquement par le navigateur
      if (kIsWeb) {
        return true;
      }
      
      // Vérifier d'abord photos, puis storage
      PermissionStatus status;
      
      try {
        status = await Permission.photos.status;
        if (status.isGranted) return true;
      } catch (e) {
        // Si photos n'est pas supporté, vérifier storage
        if (kDebugMode) {
          print('⚠️ Permission.photos non supporté, vérification storage...');
        }
      }
      
      try {
        status = await Permission.storage.status;
        return status.isGranted;
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Permission.storage non supporté sur cette plateforme');
        }
        // Si aucune permission n'est supportée, retourner true
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la vérification de permission photos: $e');
      }
      // En cas d'erreur, retourner true pour ne pas bloquer l'utilisateur
      return true;
    }
  }

  /// Demande la permission des notifications
  static Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      
      if (kDebugMode) {
        print('🔔 Statut permission notifications: $status');
      }
      
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la demande de permission notifications: $e');
      }
      return false;
    }
  }

  /// Vérifie si la permission des notifications est accordée
  static Future<bool> isNotificationPermissionGranted() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la vérification de permission notifications: $e');
      }
      return false;
    }
  }

  /// Demande la permission de localisation GPS
  static Future<bool> requestLocationPermission() async {
    try {
      // Sur le web, les permissions de localisation sont gérées automatiquement par le navigateur
      if (kIsWeb) {
        if (kDebugMode) {
          print('📍 Web: Les permissions de localisation sont gérées par le navigateur');
        }
        return true;
      }
      
      // Demander la permission de localisation précise (GPS)
      final status = await Permission.location.request();
      
      if (kDebugMode) {
        print('📍 Statut permission localisation: $status');
      }
      
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la demande de permission localisation: $e');
      }
      return false;
    }
  }

  /// Vérifie si la permission de localisation est accordée
  static Future<bool> isLocationPermissionGranted() async {
    try {
      // Sur le web, les permissions de localisation sont gérées automatiquement par le navigateur
      if (kIsWeb) {
        return true;
      }
      
      final status = await Permission.location.status;
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la vérification de permission localisation: $e');
      }
      return false;
    }
  }

  /// Demande toutes les permissions nécessaires
  /// Retourne un Map avec le statut de chaque permission
  static Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{};
    
    // Demander les permissions en parallèle
    final cameraResult = await requestCameraPermission();
    final photosResult = await requestPhotoLibraryPermission();
    final notificationResult = await requestNotificationPermission();
    final locationResult = await requestLocationPermission();
    
    results['camera'] = cameraResult;
    results['photos'] = photosResult;
    results['notifications'] = notificationResult;
    results['location'] = locationResult;
    
    if (kDebugMode) {
      print('📋 Résultats des permissions:');
      print('   - Caméra: ${cameraResult ? "✅" : "❌"}');
      print('   - Photos: ${photosResult ? "✅" : "❌"}');
      print('   - Notifications: ${notificationResult ? "✅" : "❌"}');
      print('   - Localisation: ${locationResult ? "✅" : "❌"}');
    }
    
    return results;
  }

  /// Vérifie toutes les permissions
  /// Retourne un Map avec le statut de chaque permission
  static Future<Map<String, bool>> checkAllPermissions() async {
    final results = <String, bool>{};
    
    final cameraGranted = await isCameraPermissionGranted();
    final photosGranted = await isPhotoLibraryPermissionGranted();
    final notificationGranted = await isNotificationPermissionGranted();
    final locationGranted = await isLocationPermissionGranted();
    
    results['camera'] = cameraGranted;
    results['photos'] = photosGranted;
    results['notifications'] = notificationGranted;
    results['location'] = locationGranted;
    
    return results;
  }

  /// Ouvre les paramètres de l'application pour permettre à l'utilisateur
  /// de modifier les permissions manuellement
  static Future<bool> openAppSettings() async {
    try {
      // Utiliser la fonction globale openAppSettings() de permission_handler
      final opened = await ph.openAppSettings();
      
      if (kDebugMode) {
        print('⚙️ Ouverture des paramètres: ${opened ? "✅" : "❌"}');
      }
      
      return opened;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de l\'ouverture des paramètres: $e');
      }
      return false;
    }
  }
}
