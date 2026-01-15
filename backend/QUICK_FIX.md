# 🔧 Solution rapide : Erreur de connexion au serveur backend

## Problème

L'application mobile affiche : "Timeout: Le serveur ne répond pas après 30 secondes"

## Cause

Le **firewall Windows bloque le port 3000**, empêchant l'émulateur Android de se connecter au serveur backend.

## Solution en 3 étapes

### Étape 1 : Vérifier que le serveur est démarré

Dans un terminal, vérifiez :
```bash
netstat -ano | findstr :3000
```

Vous devriez voir quelque chose comme :
```
TCP    0.0.0.0:3000           0.0.0.0:0              LISTENING       <PID>
```

Si rien n'apparaît, démarrez le serveur :
```bash
cd backend
npm run dev
```

### Étape 2 : Configurer le firewall (IMPORTANT)

**Option A : Script automatique (Recommandé)**

1. **Ouvrez PowerShell en tant qu'administrateur** :
   - Clic droit sur PowerShell dans le menu Démarrer
   - Sélectionnez "Exécuter en tant qu'administrateur"

2. **Naviguez vers le dossier backend** :
   ```powershell
   cd C:\Users\MC\AndroidStudioProjects\new\actionapp\backend
   ```

3. **Exécutez le script** :
   ```powershell
   .\add_firewall_rule.ps1
   ```

**Option B : Interface graphique**

1. Appuyez sur `Windows + R`
2. Tapez `wf.msc` et appuyez sur Entrée
3. Cliquez sur "Règles de trafic entrant" → "Nouvelle règle..."
4. Sélectionnez "Port" → TCP → Ports locaux spécifiques : `3000`
5. Sélectionnez "Autoriser la connexion"
6. Cochez tous les profils (Domaine, Privé, Public)
7. Nom : "Backend Node.js Port 3000"
8. Terminer

**Option C : Commande PowerShell (Administrateur)**

```powershell
New-NetFirewallRule -DisplayName "Backend Node.js Port 3000" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow -Profile Domain,Private,Public
```

### Étape 3 : Redémarrer l'application

1. **Arrêtez complètement l'application Flutter** (pas juste hot restart)
2. **Redémarrez l'application**
3. **Testez à nouveau** - cela devrait fonctionner maintenant !

## Vérification

Pour vérifier que la règle de firewall est créée :

```powershell
Get-NetFirewallRule -DisplayName "*3000*" | Select-Object DisplayName, Enabled, Action
```

Vous devriez voir une règle avec `Enabled: True` et `Action: Allow`.

## Test rapide

Pour tester si le firewall est vraiment le problème :

1. Ouvrez le Pare-feu Windows Defender (`wf.msc`)
2. Cliquez sur "Activer ou désactiver le Pare-feu Windows Defender"
3. **Temporairement** désactivez pour les réseaux privés
4. Testez votre application
5. **Réactivez le firewall immédiatement après**

Si cela fonctionne avec le firewall désactivé, c'est bien un problème de firewall et vous devez créer la règle comme décrit ci-dessus.

## Aide supplémentaire

- 📖 Guide détaillé : `backend/FIREWALL_TROUBLESHOOTING.md`
- 📖 Guide rapide : `backend/FIX_FIREWALL.md`
- 📖 Configuration Firebase : `backend/FIREBASE_PRODUCTION_SETUP.md`
