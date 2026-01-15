# Configuration de JAVA_HOME pour Flutter

## Problème
Flutter nécessite que la variable d'environnement `JAVA_HOME` soit configurée pour compiler les applications Android.

## Solution rapide (PowerShell)

### Option 1 : Script automatique
Exécutez le script fourni dans PowerShell :
```powershell
cd mobile
.\setup_java_env.ps1
```

Puis **redémarrez votre terminal** et réessayez `flutter run`.

### Option 2 : Configuration manuelle

1. **Trouver le chemin Java** :
   - Ouvrez Android Studio
   - Allez dans File → Settings → Build, Execution, Deployment → Build Tools → Gradle
   - Notez le chemin du JDK (généralement : `C:\Program Files\Android\Android Studio\jbr`)

2. **Configurer JAVA_HOME** :
   - Ouvrez "Variables d'environnement" dans Windows
   - Cliquez sur "Nouveau" dans les variables utilisateur
   - Nom : `JAVA_HOME`
   - Valeur : `C:\Program Files\Android\Android Studio\jbr` (ou votre chemin Java)
   - Cliquez sur OK

3. **Ajouter Java au PATH** (si nécessaire) :
   - Dans les variables système, trouvez "Path"
   - Ajoutez : `%JAVA_HOME%\bin`
   - Cliquez sur OK

4. **Redémarrer** :
   - Fermez tous les terminaux et IDE
   - Rouvrez votre terminal
   - Vérifiez avec : `echo $env:JAVA_HOME` (PowerShell) ou `echo %JAVA_HOME%` (CMD)

## Vérification

Dans un nouveau terminal :
```powershell
# Vérifier JAVA_HOME
echo $env:JAVA_HOME

# Vérifier Java
java -version

# Vérifier Gradle (si installé)
gradle -version
```

## Problème de mémoire

Si vous rencontrez toujours des erreurs "Out of memory", j'ai déjà augmenté la mémoire allouée à Gradle dans `android/gradle.properties` :
- Mémoire maximale : 4GB (au lieu de 2GB)
- Cache de code : 512MB (au lieu de 256MB)

Si le problème persiste, vous pouvez :
1. Fermer d'autres applications pour libérer de la RAM
2. Augmenter encore la mémoire dans `gradle.properties` si vous avez plus de 8GB de RAM
3. Utiliser `flutter clean` puis `flutter pub get` avant de relancer
