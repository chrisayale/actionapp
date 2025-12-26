# Guide d'installation rapide

## Installation des dépendances

### 1. Mobile App

```bash
cd mobile
flutter pub get
```

### 2. Web App

```bash
cd web
flutter pub get
```

### 3. Backend

```bash
cd backend
npm install
```

## Configuration Firebase

### Étape 1: Installer FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### Étape 2: Configurer Firebase pour Mobile

```bash
cd mobile
flutterfire configure
```

Sélectionnez votre projet Firebase et les plateformes (Android, iOS, Web).

### Étape 3: Configurer Firebase pour Web

```bash
cd web
flutterfire configure
```

Sélectionnez votre projet Firebase et la plateforme Web.

### Étape 4: Mettre à jour firebase_options.dart

Les fichiers `firebase_options.dart` seront automatiquement générés avec les bonnes valeurs après avoir exécuté `flutterfire configure`.

## Configuration Android (Mobile)

1. Téléchargez `google-services.json` depuis la console Firebase
2. Placez-le dans `mobile/android/app/`
3. Ajoutez dans `mobile/android/build.gradle` (niveau projet):

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

## Configuration iOS (Mobile)

1. Téléchargez `GoogleService-Info.plist` depuis la console Firebase
2. Placez-le dans `mobile/ios/Runner/`
3. Ouvrez `mobile/ios/Runner.xcworkspace` dans Xcode
4. Ajoutez le fichier au projet dans Xcode (glisser-déposer)

## Lancer les applications

### Mobile

```bash
cd mobile
flutter run
```

### Web

```bash
cd web
flutter run -d chrome
```

### Backend

```bash
cd backend
npm run dev
```

## Vérification

Une fois tout configuré, vous devriez pouvoir:
- ✅ Lancer l'app mobile sans erreurs
- ✅ Lancer l'app web sans erreurs
- ✅ Se connecter avec Firebase Authentication
- ✅ Lire/écrire dans Firestore

Pour plus de détails, consultez `FIREBASE_SETUP.md`.

