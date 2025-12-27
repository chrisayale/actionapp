# Flow d'authentification OTP - Backend

## Vue d'ensemble

L'authentification OTP avec Firebase fonctionne en deux étapes principales :

1. **Côté Client (Mobile)** : Envoi et vérification du code OTP via Firebase Auth SDK
2. **Côté Backend** : Vérification du token Firebase et création/mise à jour du profil utilisateur

## Flow complet

### 1. Envoi du code OTP (Client Mobile)

```dart
// Dans Flutter/Mobile
final phoneNumber = '+243900000000';

await FirebaseAuth.instance.verifyPhoneNumber(
  phoneNumber: phoneNumber,
  verificationCompleted: (PhoneAuthCredential credential) async {
    // Auto-vérification (Android uniquement)
    await FirebaseAuth.instance.signInWithCredential(credential);
  },
  verificationFailed: (FirebaseAuthException e) {
    // Gérer l'erreur
    print('Erreur: ${e.message}');
  },
  codeSent: (String verificationId, int? resendToken) {
    // Stocker verificationId pour l'étape suivante
    this.verificationId = verificationId;
  },
  codeAutoRetrievalTimeout: (String verificationId) {
    this.verificationId = verificationId;
  },
  timeout: const Duration(seconds: 60),
);
```

### 2. Vérification du code OTP (Client Mobile)

```dart
// L'utilisateur entre le code reçu par SMS
final smsCode = '123456';

final credential = PhoneAuthProvider.credential(
  verificationId: verificationId,
  smsCode: smsCode,
);

final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

// Récupérer le token ID Firebase
final idToken = await userCredential.user?.getIdToken();
```

### 3. Création/Mise à jour du profil (Client → Backend)

```dart
// Envoyer le token au backend pour créer/mettre à jour le profil
final response = await http.post(
  Uri.parse('http://your-backend-url/api/auth/create-profile'),
  headers: {
    'Authorization': 'Bearer $idToken',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'token': idToken,
    'phoneNumber': phoneNumber,
    'displayName': 'John Doe', // Optionnel
  }),
);

final data = jsonDecode(response.body);
if (data['success']) {
  final user = data['user'];
  // Profil créé/mis à jour avec succès
}
```

### 4. Vérification du token (Backend)

Le backend vérifie automatiquement le token Firebase :

```javascript
// backend/controllers/auth.controller.js
const decodedToken = await admin.auth().verifyIdToken(token);
const uid = decodedToken.uid;
```

### 5. Création/Mise à jour dans Firestore (Backend)

```javascript
// Créer ou mettre à jour le profil utilisateur
await admin.firestore().collection('users').doc(uid).set({
  phoneNumber: phoneNumber,
  displayName: displayName,
  createdAt: admin.firestore.FieldValue.serverTimestamp(),
  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
}, { merge: true });
```

## Structure des données utilisateur dans Firestore

```javascript
{
  id: "user-uid",
  phoneNumber: "+243900000000",
  displayName: "John Doe", // Optionnel
  email: null, // Si authentifié par email
  createdAt: Timestamp,
  updatedAt: Timestamp,
  lastLoginAt: Timestamp,
}
```

## Endpoints Backend

### POST /api/auth/create-profile
Créer ou mettre à jour le profil utilisateur après authentification OTP.

**Headers:**
```
Authorization: Bearer <firebase-id-token>
Content-Type: application/json
```

**Body:**
```json
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
    "updatedAt": "2024-01-01T00:00:00Z",
    "lastLoginAt": "2024-01-01T00:00:00Z"
  }
}
```

### GET /api/auth/profile
Récupérer le profil utilisateur.

**Headers:**
```
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

### PUT /api/auth/profile
Mettre à jour le profil utilisateur.

**Headers:**
```
Authorization: Bearer <firebase-id-token>
Content-Type: application/json
```

**Body:**
```json
{
  "displayName": "New Name"
}
```

## Sécurité

- Tous les endpoints nécessitent un token Firebase ID valide
- Le token est vérifié côté backend avec Firebase Admin SDK
- Les données sensibles ne sont jamais stockées en clair
- Le numéro de téléphone est vérifié par Firebase Auth avant l'authentification

## Notes importantes

1. **L'envoi OTP se fait côté client** : Firebase Auth SDK gère l'envoi et la vérification du code OTP. Le backend n'intervient qu'après l'authentification réussie.

2. **Token Firebase ID** : Après authentification réussie, le client reçoit un token ID Firebase qui doit être envoyé au backend pour vérification.

3. **Création automatique du compte** : Si l'utilisateur n'existe pas dans Firebase Auth, il est créé automatiquement lors de la vérification du code OTP.

4. **Profil Firestore** : Le profil utilisateur dans Firestore est créé/mis à jour par le backend après vérification du token.


