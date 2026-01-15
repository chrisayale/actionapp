# Configuration Firebase en production pour le backend

## Configuration actuelle

**Par défaut, le backend utilise Firebase en production (en ligne).** Les données sont enregistrées directement dans votre projet Firebase, pas dans les emulators.

## Configuration requise

Pour que le backend fonctionne avec Firebase en production, vous devez configurer le fichier `.env` dans le dossier `backend/` avec vos credentials Firebase.

### 1. Obtenir les credentials Firebase

1. Allez sur [https://console.firebase.google.com](https://console.firebase.google.com)
2. Sélectionnez votre projet Firebase (ex: `actionapp-e43b7`)
3. Allez dans **Paramètres du projet** (icône ⚙️)
4. Cliquez sur l'onglet **Comptes de service**
5. Cliquez sur **Générer une nouvelle clé privée**
6. Téléchargez le fichier JSON

### 2. Extraire les valeurs du JSON

Le fichier JSON téléchargé contient :
```json
{
  "project_id": "actionapp-e43b7",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@actionapp-e43b7.iam.gserviceaccount.com",
  ...
}
```

### 3. Créer le fichier `.env`

Dans le dossier `backend/`, créez un fichier `.env` (ou copiez `env.example.txt` vers `.env`) :

```env
FIREBASE_PROJECT_ID=actionapp-e43b7
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@actionapp-e43b7.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

PORT=3000
```

**Important :**
- Remplacez les valeurs par celles de votre fichier JSON
- La `FIREBASE_PRIVATE_KEY` doit être entre guillemets et les `\n` doivent être préservés
- Ne commitez JAMAIS le fichier `.env` dans Git (il est déjà dans `.gitignore`)

### 4. Vérifier la configuration

Démarrez le serveur backend :
```bash
cd backend
npm run dev
```

Vous devriez voir :
```
✅ Firebase Admin SDK initialisé avec succès (PRODUCTION)
   Project ID: actionapp-e43b7
   📍 Les données seront enregistrées directement dans Firebase en ligne
```

## Utiliser les emulators (optionnel)

Si vous voulez utiliser les emulators Firebase pour le développement local (les données ne seront PAS enregistrées dans Firebase en ligne), ajoutez dans votre `.env` :

```env
FIRESTORE_EMULATOR_HOST=localhost:9081
```

⚠️ **Attention :** Avec cette configuration, les données seront enregistrées dans les emulators locaux, pas dans Firebase en production.

## Vérification

Pour vérifier que les données sont bien enregistrées dans Firebase en ligne :

1. Allez sur [https://console.firebase.google.com](https://console.firebase.google.com)
2. Sélectionnez votre projet
3. Allez dans **Firestore Database**
4. Créez un établissement depuis l'application
5. Vérifiez que l'établissement apparaît dans la collection `establishments`

## Dépannage

### Erreur : "FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL et FIREBASE_PRIVATE_KEY sont requis"

- Vérifiez que le fichier `.env` existe dans le dossier `backend/`
- Vérifiez que toutes les variables sont définies dans `.env`
- Vérifiez que la `FIREBASE_PRIVATE_KEY` est entre guillemets

### Erreur : "Invalid credentials"

- Vérifiez que les credentials sont corrects
- Vérifiez que la clé privée n'a pas été modifiée (les `\n` doivent être préservés)
- Vérifiez que le compte de service a les bonnes permissions dans Firebase

### Les données ne s'enregistrent pas

- Vérifiez les logs du serveur backend
- Vérifiez que `FIRESTORE_EMULATOR_HOST` n'est PAS défini dans `.env` (sinon les emulators seront utilisés)
- Vérifiez les règles de sécurité Firestore dans la console Firebase
