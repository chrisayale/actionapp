# Guide de configuration Firebase manuelle

Si `flutterfire configure` ne fonctionne pas, suivez ce guide pour configurer Firebase manuellement.

## Étape 1: Placer google-services.json

1. Téléchargez `google-services.json` depuis Firebase Console
2. Placez-le dans : `android/app/google-services.json`

## Étape 2: Extraire les valeurs Firebase

### Option A: Utiliser le script Python (Recommandé)

```bash
python setup_firebase.py
```

Ce script va automatiquement :
- Lire `google-services.json`
- Extraire les valeurs Firebase
- Mettre à jour `mobile/lib/core/firebase/firebase_options.dart`

### Option B: Configuration manuelle

1. Ouvrez `android/app/google-services.json`
2. Trouvez les valeurs suivantes :
   - `project_info.project_id` → `projectId`
   - `project_info.storage_bucket` → `storageBucket`
   - `project_info.project_number` → `messagingSenderId`
   - `client[0].api_key[0].current_key` → `apiKey` (Android)
   - `client[0].client_info.mobilesdk_app_id` → `appId` (Android)

3. Ouvrez `mobile/lib/core/firebase/firebase_options.dart`
4. Remplacez les valeurs `YOUR_*` par les valeurs extraites

## Étape 3: Configuration Web (si nécessaire)

Pour configurer Firebase pour l'app web :

1. Allez dans Firebase Console → Paramètres du projet
2. Dans "Vos applications", trouvez l'app Web (ou créez-en une)
3. Copiez les valeurs de configuration
4. Mettez à jour `web/lib/core/firebase/firebase_options.dart` avec les valeurs Web

## Étape 4: Vérification

```bash
cd mobile
flutter pub get
flutter run
```

Si vous voyez des erreurs, vérifiez que :
- ✅ `google-services.json` est dans `android/app/`
- ✅ `firebase_options.dart` contient les bonnes valeurs
- ✅ Les fichiers Gradle sont configurés (déjà fait)

## Structure du fichier google-services.json

```json
{
  "project_info": {
    "project_id": "actionapp-e43b7",
    "project_number": "123456789",
    "storage_bucket": "actionapp-e43b7.appspot.com"
  },
  "client": [{
    "api_key": [{
      "current_key": "VOTRE_API_KEY"
    }],
    "client_info": {
      "mobilesdk_app_id": "1:123456789:android:abcdef"
    }
  }]
}
```

## Exemple de firebase_options.dart complet

Une fois configuré, votre fichier devrait ressembler à :

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSy...',  // Votre vraie clé API
  appId: '1:123456789:android:abcdef',
  messagingSenderId: '123456789',
  projectId: 'actionapp-e43b7',
  storageBucket: 'actionapp-e43b7.appspot.com',
);
```

