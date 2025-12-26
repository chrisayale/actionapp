# Guide d'installation Firebase pour Flutter

## Prérequis

1. Un compte Firebase (https://console.firebase.google.com)
2. Flutter SDK installé
3. FlutterFire CLI installé globalement

## Installation de FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

## Configuration Firebase

### Étape 1: Créer un projet Firebase

1. Allez sur https://console.firebase.google.com
2. Cliquez sur "Ajouter un projet"
3. Suivez les étapes pour créer votre projet

### Étape 2: Configurer Firebase pour Mobile

```bash
cd mobile
flutterfire configure
```

Cette commande va:
- Vous demander de sélectionner votre projet Firebase
- Générer automatiquement le fichier `lib/core/firebase/firebase_options.dart`
- Configurer Android et iOS

### Étape 3: Configurer Firebase pour Web

```bash
cd web
flutterfire configure
```

### Étape 4: Installer les dépendances

**Pour Mobile:**
```bash
cd mobile
flutter pub get
```

**Pour Web:**
```bash
cd web
flutter pub get
```

## Configuration Android (Mobile uniquement)

### Ajouter google-services.json

1. Téléchargez `google-services.json` depuis la console Firebase
2. Placez-le dans `mobile/android/app/`
3. Ajoutez dans `mobile/android/build.gradle`:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

4. Ajoutez dans `mobile/android/app/build.gradle`:

```gradle
apply plugin: 'com.google.gms.google-services'
```

## Configuration iOS (Mobile uniquement)

1. Téléchargez `GoogleService-Info.plist` depuis la console Firebase
2. Placez-le dans `mobile/ios/Runner/`
3. Ouvrez `mobile/ios/Runner.xcworkspace` dans Xcode
4. Ajoutez le fichier au projet dans Xcode

## Activer les services Firebase

### Firestore Database

1. Dans la console Firebase, allez dans "Firestore Database"
2. Cliquez sur "Créer une base de données"
3. Choisissez le mode de démarrage (test ou production)
4. Sélectionnez une région

### Authentication

1. Dans la console Firebase, allez dans "Authentication"
2. Cliquez sur "Commencer"
3. Activez "Email/Password" dans l'onglet "Sign-in method"

### Storage

1. Dans la console Firebase, allez dans "Storage"
2. Cliquez sur "Commencer"
3. Suivez les instructions pour configurer Storage

## Déployer les règles de sécurité

```bash
cd firebase
firebase deploy --only firestore:rules,storage:rules
```

## Vérification

### Test dans Mobile

```bash
cd mobile
flutter run
```

### Test dans Web

```bash
cd web
flutter run -d chrome
```

## Structure des fichiers Firebase

```
mobile/
├── lib/
│   └── core/
│       ├── firebase/
│       │   └── firebase_options.dart  # Généré par flutterfire configure
│       └── services/
│           └── firebase_service.dart   # Service helper
└── android/
    └── app/
        └── google-services.json        # Téléchargé depuis Firebase

web/
├── lib/
│   └── core/
│       ├── firebase/
│       │   └── firebase_options.dart  # Généré par flutterfire configure
│       └── services/
│           └── firebase_service.dart   # Service helper
```

## Utilisation dans le code

### Exemple d'authentification

```dart
import 'package:actionapp_mobile/core/services/firebase_service.dart';

// Connexion
final userCredential = await FirebaseService.signInWithEmailAndPassword(
  'user@example.com',
  'password123',
);

// Déconnexion
await FirebaseService.signOut();

// Utilisateur actuel
final currentUser = FirebaseService.currentUser;
```

### Exemple Firestore

```dart
import 'package:actionapp_mobile/core/services/firebase_service.dart';

// Lire des données
final snapshot = await FirebaseService.usersCollection.doc('userId').get();

// Écrire des données
await FirebaseService.usersCollection.doc('userId').set({
  'name': 'John Doe',
  'email': 'john@example.com',
});
```

## Dépannage

### Erreur: "FirebaseApp not initialized"
- Vérifiez que `Firebase.initializeApp()` est appelé dans `main()`
- Vérifiez que `firebase_options.dart` contient les bonnes valeurs

### Erreur Android: "google-services.json not found"
- Vérifiez que le fichier est dans `android/app/`
- Vérifiez que le plugin est ajouté dans `build.gradle`

### Erreur iOS: "GoogleService-Info.plist not found"
- Vérifiez que le fichier est dans `ios/Runner/`
- Vérifiez qu'il est ajouté au projet dans Xcode

