# Configuration de l'URL de l'API backend

## Problème

L'émulateur Android ne peut pas se connecter au serveur backend avec `http://10.0.2.2:3000`.

## Solution : Utiliser l'IP locale

Parfois, `10.0.2.2` ne fonctionne pas pour certains émulateurs Android. Dans ce cas, utilisez votre **IP locale** à la place.

## Trouver votre IP locale

### Windows (PowerShell)
```powershell
ipconfig | findstr /i "IPv4"
```

Ou :
```powershell
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object IPAddress
```

### Windows (CMD)
```cmd
ipconfig
```
Cherchez "Adresse IPv4" sous votre interface réseau (Wi-Fi ou Ethernet).

## Configurer l'URL dans l'application

1. **Ouvrez le fichier** : `mobile/lib/core/constants/api_constants.dart`

2. **Trouvez votre IP locale** (exemple : `10.228.218.188`)

3. **Modifiez la ligne** :
   ```dart
   static const String baseUrl = 'http://VOTRE_IP_LOCALE:3000/api';
   ```

   Par exemple :
   ```dart
   static const String baseUrl = 'http://10.228.218.188:3000/api';
   ```

4. **Redémarrez l'application Flutter** (hot restart ne suffit pas)

## Vérification

Pour vérifier que l'IP est correcte :

1. **Vérifiez que le serveur backend est démarré** :
   ```bash
   netstat -ano | findstr :3000
   ```

2. **Testez depuis votre navigateur** :
   ```
   http://VOTRE_IP_LOCALE:3000/test
   ```
   Vous devriez voir : `{"message":"Backend is reachable!"}`

3. **Testez depuis l'émulateur Android** :
   - Ouvrez un navigateur dans l'émulateur
   - Allez sur `http://VOTRE_IP_LOCALE:3000/test`
   - Vous devriez voir la même réponse

## Important : Firewall

⚠️ **N'oubliez pas de configurer le firewall** pour autoriser le port 3000 !

Même avec l'IP locale, le firewall Windows peut bloquer les connexions. Voir `QUICK_FIX.md` pour configurer le firewall.

## Options disponibles

### Option 1 : IP locale (Recommandé si 10.0.2.2 ne fonctionne pas)
```dart
static const String baseUrl = 'http://10.228.218.188:3000/api';
```
- ✅ Fonctionne pour les émulateurs Android
- ✅ Fonctionne pour les appareils physiques sur le même réseau
- ⚠️ Nécessite de configurer le firewall

### Option 2 : 10.0.2.2 (Standard pour émulateur Android)
```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
```
- ✅ Standard pour les émulateurs Android
- ❌ Ne fonctionne pas pour les appareils physiques
- ⚠️ Nécessite de configurer le firewall

### Option 3 : localhost (iOS Simulator / Web)
```dart
static const String baseUrl = 'http://localhost:3000/api';
```
- ✅ Fonctionne pour iOS Simulator
- ✅ Fonctionne pour Web
- ❌ Ne fonctionne pas pour Android (émulateur ou physique)

## Dépannage

### L'IP locale change à chaque connexion Wi-Fi

Si votre IP change fréquemment, vous pouvez :

1. **Configurer une IP statique** sur votre routeur
2. **Utiliser un script** pour mettre à jour automatiquement l'IP dans le code
3. **Utiliser un service de découverte automatique** (plus complexe)

### L'émulateur ne peut toujours pas se connecter

1. Vérifiez que le firewall autorise le port 3000
2. Vérifiez que le serveur écoute sur `0.0.0.0:3000` (pas seulement `127.0.0.1:3000`)
3. Vérifiez que l'émulateur et votre machine sont sur le même réseau
4. Essayez de redémarrer l'émulateur
