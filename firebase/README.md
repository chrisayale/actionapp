# Firebase Configuration Locale

Ce répertoire contient la configuration Firebase pour le projet ActionApp.

## Installation Firebase CLI (déjà installé)

Firebase CLI est installé globalement via npm:
```bash
npm install -g firebase-tools
```

Version installée: **15.0.0**

## Connexion Firebase

Vous êtes connecté avec: **kivugreencorp@gmail.com**

## Projet Firebase Actif

Le projet actif est: **actionapp-38a33**

## Configuration

Le fichier `firebase.json` contient la configuration pour:
- **Firestore**: Base de données NoSQL
- **Storage**: Stockage de fichiers
- **Hosting**: Hébergement web
- **Emulators**: Emulateurs locaux pour le développement

## Emulateurs Firebase (Développement Local)

Les emulators sont configurés pour le développement local:

### Démarrer les emulators:

```bash
cd firebase
firebase emulators:start
```

### Ports des emulators:
- **Auth**: http://localhost:9099
- **Firestore**: http://localhost:8080
- **Storage**: http://localhost:9199
- **UI**: http://localhost:4000 (Interface d'administration)

### Arrêter les emulators:
Appuyez sur `Ctrl+C` dans le terminal

## Commandes Utiles

### Vérifier le projet actif:
```bash
firebase use
```

### Changer de projet:
```bash
firebase use [project-id]
```

### Lister les projets disponibles:
```bash
firebase projects:list
```

### Déployer les règles Firestore:
```bash
firebase deploy --only firestore:rules
```

### Déployer les règles Storage:
```bash
firebase deploy --only storage:rules
```

### Déployer tout:
```bash
firebase deploy
```

## Structure des fichiers

```
firebase/
├── firebase.json          # Configuration Firebase
├── .firebaserc           # Projet Firebase actif (auto-généré)
├── firestore.rules       # Règles de sécurité Firestore
├── firestore.indexes.json # Indexes Firestore
└── storage.rules         # Règles de sécurité Storage
```

## Notes

- Les emulators permettent de tester votre application localement sans consommer de quota Firebase
- Les données dans les emulators sont temporaires et seront supprimées à l'arrêt
- Pour la production, utilisez `firebase deploy` pour déployer sur Firebase


