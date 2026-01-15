# Guide de dépannage du firewall pour le backend

## Problème : L'émulateur Android ne peut pas se connecter au serveur backend

Si vous voyez des erreurs de timeout comme :
```
❌ [AdvertiserRepository] Request timeout after 30 seconds
```

Et que le serveur fonctionne bien depuis `localhost` mais pas depuis l'émulateur Android (`10.0.2.2:3000`), le problème est probablement lié au **firewall Windows**.

## Solution : Autoriser le port 3000 dans le firewall Windows

### Option 1 : Via l'interface graphique (Recommandé)

1. **Ouvrez le Pare-feu Windows Defender** :
   - Appuyez sur `Windows + R`
   - Tapez `wf.msc` et appuyez sur Entrée
   - Ou allez dans : Paramètres > Réseau et Internet > Pare-feu Windows Defender

2. **Créez une nouvelle règle entrante** :
   - Cliquez sur "Règles de trafic entrant" dans le panneau de gauche
   - Cliquez sur "Nouvelle règle..." dans le panneau de droite

3. **Configurez la règle** :
   - Sélectionnez "Port" et cliquez sur "Suivant"
   - Sélectionnez "TCP"
   - Sélectionnez "Ports locaux spécifiques" et entrez `3000`
   - Cliquez sur "Suivant"
   - Sélectionnez "Autoriser la connexion"
   - Cliquez sur "Suivant"
   - Cochez tous les profils (Domaine, Privé, Public)
   - Cliquez sur "Suivant"
   - Donnez un nom à la règle (ex: "Backend Node.js Port 3000")
   - Cliquez sur "Terminer"

### Option 2 : Via PowerShell (Administrateur)

Ouvrez PowerShell **en tant qu'administrateur** et exécutez :

```powershell
New-NetFirewallRule -DisplayName "Backend Node.js Port 3000" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

### Option 3 : Via l'invite de commande (Administrateur)

Ouvrez l'invite de commande **en tant qu'administrateur** et exécutez :

```cmd
netsh advfirewall firewall add rule name="Backend Node.js Port 3000" dir=in action=allow protocol=TCP localport=3000
```

## Vérification

Après avoir ajouté la règle, testez depuis l'émulateur Android :

1. **Redémarrez l'application Flutter** (hot restart ne suffit pas)
2. **Essayez de créer un annonceur** à nouveau
3. **Vérifiez les logs** - vous devriez voir des requêtes réussies au lieu de timeouts

## Alternative : Désactiver temporairement le firewall (Non recommandé)

⚠️ **ATTENTION** : Ne faites cela que pour tester, et réactivez le firewall après !

1. Ouvrez le Pare-feu Windows Defender
2. Cliquez sur "Activer ou désactiver le Pare-feu Windows Defender"
3. Désactivez pour les réseaux privés (temporairement)
4. Testez votre application
5. **Réactivez le firewall immédiatement après**

## Vérifier que le serveur écoute sur toutes les interfaces

Le serveur doit écouter sur `0.0.0.0` (toutes les interfaces) et non seulement sur `localhost` :

```bash
netstat -ano | findstr :3000
```

Vous devriez voir :
```
TCP    0.0.0.0:3000           0.0.0.0:0              LISTENING
```

Si vous voyez `127.0.0.1:3000` au lieu de `0.0.0.0:3000`, le serveur n'écoute que sur localhost et ne sera pas accessible depuis l'émulateur.

## Test de connexion depuis l'émulateur

Pour tester si l'émulateur peut accéder au serveur :

1. **Depuis l'émulateur Android** :
   - Ouvrez un navigateur dans l'émulateur
   - Allez sur `http://10.0.2.2:3000/test`
   - Vous devriez voir : `{"message":"Backend is reachable!"}`

2. **Depuis PowerShell sur votre machine** :
   ```powershell
   Invoke-WebRequest -Uri http://localhost:3000/test
   ```
   Vous devriez voir une réponse 200 OK.

## Problèmes courants

### Le serveur répond depuis localhost mais pas depuis l'émulateur

- ✅ Vérifiez que le firewall autorise le port 3000
- ✅ Vérifiez que le serveur écoute sur `0.0.0.0:3000` et non `127.0.0.1:3000`
- ✅ Vérifiez que l'URL dans l'app est `http://10.0.2.2:3000/api` (pour émulateur)

### L'émulateur ne peut toujours pas se connecter

- Essayez d'utiliser votre IP locale au lieu de `10.0.2.2` :
  - Trouvez votre IP locale : `ipconfig` (cherchez "Adresse IPv4")
  - Modifiez `mobile/lib/core/constants/api_constants.dart` :
    ```dart
    static const String baseUrl = 'http://VOTRE_IP_LOCALE:3000/api';
    ```
  - Note : Cela fonctionne pour les appareils physiques, mais `10.0.2.2` devrait fonctionner pour les émulateurs

### Le firewall bloque toujours

- Vérifiez qu'il n'y a pas d'autres logiciels de sécurité (antivirus, VPN) qui bloquent le port
- Vérifiez que vous avez bien créé une règle **entrante** (Inbound) et non sortante (Outbound)
