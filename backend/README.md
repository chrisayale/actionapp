# ActionApp Backend API

Backend Node.js/Express pour l'application ActionApp avec authentification Firebase.

## Installation

```bash
npm install
```

## Configuration

Créez un fichier `.env` à la racine du dossier `backend/` avec les variables suivantes:

```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=your-client-email@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
PORT=3000
```

Pour obtenir les credentials Firebase Admin SDK:
1. Allez sur https://console.firebase.google.com
2. Sélectionnez votre projet
3. Allez dans Paramètres du projet > Comptes de service
4. Cliquez sur "Générer une nouvelle clé privée"
5. Téléchargez le fichier JSON et extrayez les valeurs nécessaires

## Démarrage

### Mode développement (avec auto-reload):
```bash
npm run dev
```

### Mode production:
```bash
npm start
```

Le serveur démarre sur le port 3000 par défaut (ou celui spécifié dans `.env`).

## Endpoints API

### Authentification OTP (Mobile)

#### 1. Vérifier un token Firebase
```http
POST /api/auth/verify-token
Authorization: Bearer <firebase-id-token>
```

**Réponse:**
```json
{
  "success": true,
  "uid": "user-uid",
  "phone": "+1234567890",
  "email": "user@example.com"
}
```

#### 2. Créer/Mettre à jour le profil utilisateur
```http
POST /api/auth/create-profile
Authorization: Bearer <firebase-id-token>
Content-Type: application/json

{
  "token": "firebase-id-token",
  "phoneNumber": "+243900000000",
  "displayName": "John Doe"
}
```

**Réponse:**
```json
{
  "success": true,
  "user": {
    "id": "user-uid",
    "phoneNumber": "+243900000000",
    "displayName": "John Doe",
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }
}
```

#### 3. Obtenir le profil utilisateur
```http
GET /api/auth/profile
Authorization: Bearer <firebase-id-token>
```

**Réponse:**
```json
{
  "success": true,
  "user": {
    "id": "user-uid",
    "phoneNumber": "+243900000000",
    "displayName": "John Doe",
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }
}
```

#### 4. Mettre à jour le profil utilisateur
```http
PUT /api/auth/profile
Authorization: Bearer <firebase-id-token>
Content-Type: application/json

{
  "displayName": "New Name"
}
```

#### 5. Vérifier si un numéro de téléphone existe
```http
GET /api/auth/check-phone?phoneNumber=+243900000000
```

**Réponse:**
```json
{
  "success": true,
  "exists": false,
  "phoneNumber": "+243900000000"
}
```

### Authentification Email/Password (Admin/Web)

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "admin@example.com",
  "password": "password"
}
```

#### Register
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password",
  "name": "User Name"
}
```

## Flow d'authentification OTP (Mobile)

1. **Client** : L'utilisateur entre son numéro de téléphone
2. **Client** : Utilise Firebase Auth SDK pour envoyer le code OTP
   ```dart
   await FirebaseAuth.instance.verifyPhoneNumber(
     phoneNumber: phoneNumber,
     verificationCompleted: ...,
     verificationFailed: ...,
     codeSent: (verificationId, resendToken) {
       // Stocker verificationId
     },
     codeAutoRetrievalTimeout: ...,
   );
   ```

3. **Client** : L'utilisateur entre le code OTP reçu
4. **Client** : Vérifie le code avec Firebase Auth SDK
   ```dart
   PhoneAuthCredential credential = PhoneAuthProvider.credential(
     verificationId: verificationId,
     smsCode: smsCode,
   );
   UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
   ```

5. **Client** : Récupère le token ID Firebase
   ```dart
   String? idToken = await userCredential.user?.getIdToken();
   ```

6. **Client** → **Backend** : Envoie le token au backend pour créer/mettre à jour le profil
   ```http
   POST /api/auth/create-profile
   Authorization: Bearer <id-token>
   ```

7. **Backend** : Vérifie le token, crée/met à jour le profil dans Firestore

## Structure du projet

```
backend/
├── app.js                    # Point d'entrée de l'application
├── controllers/
│   └── auth.controller.js    # Contrôleurs d'authentification
├── middleware/
│   └── auth.middleware.js    # Middleware de vérification de token
├── routes/
│   └── auth.routes.js        # Routes d'authentification
├── services/
│   └── firebase.service.js   # Service Firebase (Firestore)
├── package.json
└── .env                      # Variables d'environnement (à créer)
```

## Notes importantes

- **OTP Authentication**: L'envoi et la vérification du code OTP se font **côté client** avec Firebase Auth SDK. Le backend vérifie uniquement le token ID Firebase après authentification.
- **Token Verification**: Tous les endpoints protégés nécessitent un token Firebase ID dans le header `Authorization: Bearer <token>`.
- **Error Handling**: Toutes les erreurs retournent un format JSON cohérent avec `success: false` et un message d'erreur.

## Health Check

```http
GET /health
```

**Réponse:**
```json
{
  "status": "ok",
  "message": "Server is running"
}
```


