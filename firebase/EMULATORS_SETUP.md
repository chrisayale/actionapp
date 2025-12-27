# Configuration des Emulators Firebase Locaux

Ce guide explique comment utiliser les emulators Firebase en local pour le développement et les tests.

## Prérequis

- Firebase CLI installé (`firebase --version` doit fonctionner)
- Node.js installé
- Flutter SDK installé

## Démarrer les Emulators Firebase

### 1. Aller dans le dossier firebase

```bash
cd firebase
```

### 2. Démarrer les emulators

```bash
firebase emulators:start
```

Cela démarre tous les emulators configurés dans `firebase.json`:
- **Auth Emulator**: http://localhost:9099
- **Firestore Emulator**: http://localhost:8080
- **Storage Emulator**: http://localhost:9199
- **UI Emulator**: http://localhost:4000 (Interface d'administration)

### 3. Accéder à l'interface UI

Ouvrez votre navigateur à: http://localhost:4000

L'interface UI vous permet de:
- Voir et gérer les utilisateurs authentifiés
- Voir et modifier les données Firestore
- Voir les fichiers dans Storage
- Tester les règles de sécurité

## Configuration de l'application Flutter

L'application Flutter est automatiquement configurée pour utiliser les emulators en mode debug.

Dans `mobile/lib/main.dart`, le code connecte automatiquement aux emulators quand `kDebugMode` est vrai:

```dart
if (kDebugMode) {
  await _connectToFirebaseEmulators();
}
```

## Tester l'authentification OTP localement

### Méthode 1: Via l'interface UI (Recommandé pour les tests)

1. Démarrez les emulators: `firebase emulators:start`
2. Ouvrez http://localhost:4000
3. Allez dans l'onglet "Authentication"
4. Cliquez sur "Add user"
5. Créez un utilisateur avec un numéro de téléphone (ex: +243900000000)

### Méthode 2: Via l'application Flutter

1. Démarrez les emulators: `firebase emulators:start`
2. Lancez l'application Flutter: `flutter run`
3. Dans l'écran de vérification OTP, entrez n'importe quel code à 6 chiffres
4. L'authentification fonctionnera directement sans SMS réel

**Note**: Avec les emulators, l'authentification par téléphone fonctionne sans envoi de SMS réel. Vous pouvez utiliser n'importe quel code à 6 chiffres.

## Tester avec un numéro de téléphone spécifique

Pour tester l'authentification OTP avec un numéro spécifique:

1. Dans l'interface UI (http://localhost:4000)
2. Allez dans "Authentication" > "Users"
3. Cliquez sur "Add user"
4. Sélectionnez "Phone" comme provider
5. Entrez le numéro de téléphone (ex: +243900000000)
6. L'utilisateur sera créé dans l'emulator

## Commandes utiles

### Démarrer uniquement certains emulators

```bash
# Seulement Auth et Firestore
firebase emulators:start --only auth,firestore

# Seulement Auth
firebase emulators:start --only auth
```

### Démarrer avec import/export de données

```bash
# Exporter les données
firebase emulators:export ./emulator-data

# Démarrer avec import de données
firebase emulators:start --import=./emulator-data
```

### Arrêter les emulators

Appuyez sur `Ctrl+C` dans le terminal où les emulators tournent.

## Ports des emulators

Les ports sont configurés dans `firebase.json`:

```json
{
  "emulators": {
    "auth": {
      "port": 9099
    },
    "firestore": {
      "port": 8080
    },
    "storage": {
      "port": 9199
    },
    "ui": {
      "enabled": true,
      "port": 4000
    }
  }
}
```

## Configuration pour Android Emulator

Si vous utilisez un émulateur Android (pas un appareil physique):

Pour `localhost`, utilisez `10.0.2.2` (adresse spéciale de l'émulateur Android):

Modifiez `mobile/lib/main.dart`:

```dart
Future<void> _connectToFirebaseEmulators() async {
  // Utiliser 10.0.2.2 pour Android Emulator, localhost pour autres plateformes
  final host = defaultTargetPlatform == TargetPlatform.android 
      ? '10.0.2.2' 
      : 'localhost';
      
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
}
```

## Avantages des emulators locaux

1. **Pas de quota consommé**: Les appels aux emulators ne consomment pas votre quota Firebase
2. **Développement rapide**: Pas besoin d'internet (après le premier démarrage)
3. **Tests sécurisés**: Testez sans affecter vos données de production
4. **Débogage facile**: Interface UI pour inspecter les données
5. **Tests automatisés**: Utilisable dans les tests CI/CD

## Désactiver les emulators pour la production

En mode release, les emulators ne sont pas utilisés automatiquement. Le code dans `main.dart` vérifie `kDebugMode`, donc:

- **Debug mode**: Utilise les emulators locaux
- **Release mode**: Utilise Firebase en production

Pour forcer l'utilisation de Firebase en production même en debug:

```dart
// Ne connecter aux emulators que si une variable d'environnement est définie
const bool useEmulators = bool.fromEnvironment('USE_EMULATORS', defaultValue: false);
if (kDebugMode && useEmulators) {
  await _connectToFirebaseEmulators();
}
```

Puis lancez avec:
```bash
flutter run --dart-define=USE_EMULATORS=true
```

## Résolution de problèmes

### Les emulators ne démarrent pas

```bash
# Vérifier que Firebase CLI est installé
firebase --version

# Vérifier que vous êtes dans le bon dossier
cd firebase

# Vérifier la configuration
firebase emulators:start --debug
```

### L'application ne se connecte pas aux emulators

1. Vérifiez que les emulators sont démarrés
2. Vérifiez que vous êtes en mode debug (`kDebugMode`)
3. Vérifiez les logs dans la console
4. Pour Android Emulator, utilisez `10.0.2.2` au lieu de `localhost`

### Erreur de connexion

Assurez-vous que:
- Les emulators sont démarrés avant de lancer l'application Flutter
- Les ports ne sont pas utilisés par d'autres applications
- Le firewall n' bloque pas les connexions locales


