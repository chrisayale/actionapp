# Guide de démarrage du serveur backend

## Démarrage rapide

### Option 1 : Script automatique (Recommandé)

**Windows (PowerShell) :**
```powershell
cd backend
.\start_server.ps1
```

**Windows (CMD) :**
```cmd
cd backend
start_server.bat
```

### Option 2 : Commande manuelle

```bash
cd backend
npm run dev
```

## Vérifications préalables

### 1. Node.js installé
Vérifiez que Node.js est installé :
```bash
node --version
npm --version
```

### 2. Dépendances installées
Les dépendances seront installées automatiquement si elles n'existent pas.

Sinon, installez-les manuellement :
```bash
cd backend
npm install
```

### 3. Fichier .env
Le fichier `.env` sera créé automatiquement depuis `env.example.txt` s'il n'existe pas.

**Pour la production**, vous devez configurer :
- `FIREBASE_PROJECT_ID` : ID de votre projet Firebase
- `FIREBASE_CLIENT_EMAIL` : Email du service account
- `FIREBASE_PRIVATE_KEY` : Clé privée du service account

**Par défaut**, le serveur utilise Firebase en production (en ligne). Les données seront enregistrées directement dans votre projet Firebase.

**Pour utiliser les emulators** (développement local uniquement), ajoutez `FIRESTORE_EMULATOR_HOST=localhost:9081` dans votre `.env`.

📖 **Guide de configuration Firebase** : Voir [FIREBASE_PRODUCTION_SETUP.md](./FIREBASE_PRODUCTION_SETUP.md)

## Port du serveur

Le serveur écoute sur le **port 3000** par défaut.

URL : `http://localhost:3000`

## Vérification que le serveur fonctionne

Une fois démarré, testez avec :
```bash
curl http://localhost:3000/test
```

Ou ouvrez dans votre navigateur : `http://localhost:3000/test`

Vous devriez voir : `{"message":"Backend is reachable!"}`

## Endpoints disponibles

- `GET /test` - Test de connexion
- `POST /api/auth/register` - Inscription
- `POST /api/auth/login` - Connexion
- `GET /api/promotions/public` - Promotions publiques
- `POST /api/advertisers` - Créer un annonceur
- `GET /api/advertisers` - Liste des annonceurs

## Arrêter le serveur

Appuyez sur `Ctrl+C` dans le terminal où le serveur tourne.

## Dépannage

### Le serveur ne démarre pas

#### Erreur : "Port 3000 might already be in use"

Si vous voyez cette erreur, un autre processus utilise déjà le port 3000.

**Solution rapide :**

**Option 1 : Script automatique (Recommandé)**

**Windows (PowerShell) :**
```powershell
cd backend
.\kill_port_3000.ps1
```

**Windows (CMD) :**
```cmd
cd backend
kill_port_3000.bat
```

**Option 2 : Commande manuelle**

1. **Trouvez le processus :**
   ```bash
   netstat -ano | findstr :3000
   ```
   Notez le PID (dernier nombre)

2. **Arrêtez le processus :**
   ```bash
   taskkill /PID <PID> /F
   ```
   Remplacez `<PID>` par le numéro trouvé à l'étape 1

**Option 3 : Utiliser un autre port**

Modifiez `PORT=3001` dans votre fichier `.env` et mettez à jour l'URL dans l'app mobile.

**Autres vérifications :**

1. **Vérifiez les logs d'erreur** dans le terminal

2. **Vérifiez que Node.js est installé :**
   ```bash
   node --version
   ```

### Erreur de connexion depuis l'app mobile

1. **Vérifiez que le serveur est démarré** (vous devriez voir des logs dans le terminal)

2. **Vérifiez l'URL dans l'app** :
   - Émulateur Android : `http://10.0.2.2:3000`
   - Appareil physique : `http://<IP_LOCALE>:3000` (remplacez par votre IP locale)

3. **Vérifiez le firewall** Windows qui pourrait bloquer le port 3000
   - 📖 **Guide détaillé** : Voir [FIREWALL_TROUBLESHOOTING.md](./FIREWALL_TROUBLESHOOTING.md)
   - **Solution rapide** : Autorisez le port 3000 dans le Pare-feu Windows Defender

### Erreur Firebase

Si vous voyez des erreurs Firebase :
- Le serveur utilisera automatiquement les emulators en développement
- Pour la production, configurez le fichier `.env` avec vos credentials Firebase
