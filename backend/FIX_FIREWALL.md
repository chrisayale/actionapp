# Solution rapide : Configurer le firewall pour le port 3000

## Problème

L'émulateur Android ne peut pas se connecter au serveur backend (timeout après 30 secondes) car le firewall Windows bloque le port 3000.

## Solution : Autoriser le port 3000 dans le firewall

### Option 1 : Script PowerShell (Administrateur) - RECOMMANDÉ

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

### Option 2 : Interface graphique Windows

1. **Ouvrez le Pare-feu Windows Defender** :
   - Appuyez sur `Windows + R`
   - Tapez `wf.msc` et appuyez sur Entrée

2. **Créez une nouvelle règle entrante** :
   - Cliquez sur "Règles de trafic entrant" dans le panneau de gauche
   - Cliquez sur "Nouvelle règle..." dans le panneau de droite

3. **Configurez la règle** :
   - Sélectionnez "Port" → Suivant
   - Sélectionnez "TCP"
   - Sélectionnez "Ports locaux spécifiques" et entrez `3000`
   - Sélectionnez "Autoriser la connexion"
   - Cochez tous les profils (Domaine, Privé, Public)
   - Donnez un nom : "Backend Node.js Port 3000"
   - Terminer

### Option 3 : Commande PowerShell (Administrateur)

Ouvrez PowerShell **en tant qu'administrateur** et exécutez :

```powershell
New-NetFirewallRule -DisplayName "Backend Node.js Port 3000" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow -Profile Domain,Private,Public
```

## Vérification

Après avoir créé la règle :

1. **Redémarrez l'application Flutter** (hot restart ne suffit pas)
2. **Testez à nouveau** - les requêtes devraient maintenant fonctionner

## Test rapide

Pour tester si le firewall est le problème, vous pouvez temporairement désactiver le firewall (⚠️ **uniquement pour tester**) :

1. Ouvrez le Pare-feu Windows Defender
2. Cliquez sur "Activer ou désactiver le Pare-feu Windows Defender"
3. Désactivez pour les réseaux privés (temporairement)
4. Testez votre application
5. **Réactivez le firewall immédiatement après**

Si cela fonctionne avec le firewall désactivé, c'est bien un problème de firewall et vous devez créer la règle comme décrit ci-dessus.
