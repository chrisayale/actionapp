# API de Création/Mise à jour de Profil

## Endpoints

### POST /api/auth/create-profile

Crée ou met à jour le profil utilisateur après vérification OTP.

**Headers:**
- `Content-Type: application/json`

**Body:**
```json
{
  "token": "string (Firebase ID Token)",
  "phoneNumber": "string (optionnel)",
  "displayName": "string (optionnel)",
  "gender": "M" | "F" (optionnel),
  "dateOfBirth": "string ISO 8601 (optionnel, ex: 1990-01-15)",
  "photoUrl": "string URL (optionnel)",
  "pin": "string 4 chiffres (optionnel)"
}
```

**Réponse (Success - 200):**
```json
{
  "success": true,
  "user": {
    "id": "uid",
    "phoneNumber": "+1234567890",
    "displayName": "John Doe",
    "gender": "M",
    "dateOfBirth": "1990-01-15T00:00:00.000Z",
    "photoUrl": "https://...",
    "profileComplete": true,
    "createdAt": "timestamp",
    "updatedAt": "timestamp"
  }
}
```

**Validations:**
- `token`: Requis
- `pin`: Si fourni, doit être exactement 4 chiffres
- `gender`: Si fourni, doit être "M" ou "F"
- `dateOfBirth`: Si fourni, doit être en format ISO 8601 valide et l'utilisateur doit avoir au moins 13 ans

**Notes:**
- Le PIN est hashé avec SHA-256 avant stockage (considérez bcrypt pour la production)
- Le champ `profileComplete` est automatiquement défini à `true` si PIN, gender et dateOfBirth sont tous fournis
- Le `displayName` et `photoUrl` sont aussi mis à jour dans Firebase Auth si fournis

---

### PUT /api/auth/profile

Met à jour le profil utilisateur (mise à jour partielle possible).

**Headers:**
- `Authorization: Bearer <Firebase ID Token>`
- `Content-Type: application/json`

**Body:**
```json
{
  "displayName": "string (optionnel)",
  "gender": "M" | "F" (optionnel)",
  "dateOfBirth": "string ISO 8601 (optionnel)",
  "photoUrl": "string URL (optionnel)",
  "pin": "string 4 chiffres (optionnel)"
}
```

**Réponse (Success - 200):**
```json
{
  "success": true,
  "user": {
    "id": "uid",
    "phoneNumber": "+1234567890",
    "displayName": "John Doe",
    "gender": "M",
    "dateOfBirth": "1990-01-15T00:00:00.000Z",
    "photoUrl": "https://...",
    "profileComplete": true,
    "updatedAt": "timestamp"
  }
}
```

**Validations:**
- Mêmes validations que `createProfile`
- Seuls les champs fournis seront mis à jour (mise à jour partielle)

---

### GET /api/auth/profile

Récupère le profil utilisateur.

**Headers:**
- `Authorization: Bearer <Firebase ID Token>`

**Réponse (Success - 200):**
```json
{
  "success": true,
  "user": {
    "id": "uid",
    "phoneNumber": "+1234567890",
    "displayName": "John Doe",
    "gender": "M",
    "dateOfBirth": "1990-01-15T00:00:00.000Z",
    "photoUrl": "https://...",
    "profileComplete": true,
    "createdAt": "timestamp",
    "updatedAt": "timestamp"
  }
}
```

**Notes:**
- Le PIN n'est jamais retourné dans les réponses pour des raisons de sécurité

---

## Structure de données Firestore

**Collection: `users`**

**Document ID:** `{uid}` (Firebase Auth UID)

**Fields:**
- `phoneNumber`: string (optionnel)
- `displayName`: string (optionnel)
- `gender`: "M" | "F" (optionnel)
- `dateOfBirth`: timestamp ISO 8601 (optionnel)
- `photoUrl`: string URL (optionnel)
- `pin`: string (hashé avec SHA-256, jamais retourné dans les réponses)
- `profileComplete`: boolean (défini automatiquement)
- `email`: string (optionnel)
- `createdAt`: timestamp
- `updatedAt`: timestamp
- `lastLoginAt`: timestamp

---

## Sécurité

1. **PIN:** Le PIN est hashé avec SHA-256 avant stockage. Considérez utiliser bcrypt pour la production.
2. **Token:** Tous les endpoints nécessitent une vérification du token Firebase ID
3. **Validation:** Toutes les données sont validées avant stockage
4. **Profil complet:** Défini automatiquement selon les champs requis (PIN, gender, dateOfBirth)

---

## Exemples d'utilisation

### Créer un profil complet
```bash
curl -X POST http://localhost:3000/api/auth/create-profile \
  -H "Content-Type: application/json" \
  -d '{
    "token": "firebase-id-token",
    "displayName": "John Doe",
    "gender": "M",
    "dateOfBirth": "1990-01-15",
    "photoUrl": "https://example.com/photo.jpg",
    "pin": "1234"
  }'
```

### Créer un profil partiel
```bash
curl -X POST http://localhost:3000/api/auth/create-profile \
  -H "Content-Type: application/json" \
  -d '{
    "token": "firebase-id-token",
    "displayName": "John Doe"
  }'
```

### Mettre à jour le profil
```bash
curl -X PUT http://localhost:3000/api/auth/profile \
  -H "Authorization: Bearer firebase-id-token" \
  -H "Content-Type: application/json" \
  -d '{
    "gender": "M",
    "dateOfBirth": "1990-01-15",
    "pin": "5678"
  }'
```

