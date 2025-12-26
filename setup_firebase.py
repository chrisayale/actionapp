#!/usr/bin/env python3
"""
Script pour extraire les valeurs Firebase depuis google-services.json
et mettre à jour firebase_options.dart
"""
import json
import os
import sys

def extract_firebase_config():
    # Chemin du fichier google-services.json
    google_services_path = "android/app/google-services.json"
    
    if not os.path.exists(google_services_path):
        print(f"❌ Fichier {google_services_path} introuvable!")
        print(f"\n📋 Instructions:")
        print(f"1. Téléchargez google-services.json depuis Firebase Console")
        print(f"2. Placez-le dans: {google_services_path}")
        print(f"3. Relancez ce script")
        return None
    
    try:
        with open(google_services_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        project_info = data.get('project_info', {})
        client = data.get('client', [{}])[0]
        
        android_config = {
            'apiKey': client.get('api_key', [{}])[0].get('current_key', ''),
            'appId': client.get('client_info', {}).get('mobilesdk_app_id', ''),
            'messagingSenderId': project_info.get('project_number', ''),
            'projectId': project_info.get('project_id', ''),
            'storageBucket': project_info.get('storage_bucket', ''),
        }
        
        return {
            'android': android_config,
            'projectId': project_info.get('project_id', ''),
            'storageBucket': project_info.get('storage_bucket', ''),
        }
    except Exception as e:
        print(f"❌ Erreur lors de la lecture du fichier: {e}")
        return None

def generate_firebase_options(config):
    if not config:
        return
    
    project_id = config['projectId']
    storage_bucket = config['storageBucket']
    android = config['android']
    
    dart_code = f'''// File generated automatically from google-services.json
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {{
  static FirebaseOptions get currentPlatform {{
    if (kIsWeb) {{
      return web;
    }}
    switch (defaultTargetPlatform) {{
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }}
  }}

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '{android["apiKey"]}',
    appId: '{android["appId"]}',
    messagingSenderId: '{android["messagingSenderId"]}',
    projectId: '{project_id}',
    authDomain: '{project_id}.firebaseapp.com',
    storageBucket: '{storage_bucket}',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '{android["apiKey"]}',
    appId: '{android["appId"]}',
    messagingSenderId: '{android["messagingSenderId"]}',
    projectId: '{project_id}',
    storageBucket: '{storage_bucket}',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '{android["apiKey"]}',
    appId: '{android["appId"]}',
    messagingSenderId: '{android["messagingSenderId"]}',
    projectId: '{project_id}',
    storageBucket: '{storage_bucket}',
    iosBundleId: 'com.kivugreen.actionapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: '{android["apiKey"]}',
    appId: '{android["appId"]}',
    messagingSenderId: '{android["messagingSenderId"]}',
    projectId: '{project_id}',
    storageBucket: '{storage_bucket}',
    iosBundleId: 'com.kivugreen.actionapp',
  );
}}
'''
    
    # Écrire dans mobile/lib/core/firebase/firebase_options.dart
    output_path = "mobile/lib/core/firebase/firebase_options.dart"
    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(dart_code)
        print(f"✅ Fichier {output_path} mis à jour avec succès!")
        return True
    except Exception as e:
        print(f"❌ Erreur lors de l'écriture: {e}")
        return False

if __name__ == "__main__":
    print("🔥 Configuration Firebase depuis google-services.json\n")
    config = extract_firebase_config()
    if config:
        print("✅ Configuration extraite avec succès!")
        print(f"   Project ID: {config['projectId']}")
        generate_firebase_options(config)
    else:
        sys.exit(1)

