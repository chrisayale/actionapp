# Guide de dépannage Flutter

## Problèmes résolus

### 1. ✅ JAVA_HOME non configuré
**Solution appliquée** : JAVA_HOME a été configuré automatiquement.
- **Action requise** : Redémarrer votre terminal/IDE pour que les changements prennent effet.

### 2. ✅ Mémoire insuffisante (Out of memory) - Gradle
**Solutions appliquées** :
- Mémoire Gradle augmentée à 4GB dans `android/gradle.properties`
- Cache de code augmenté à 512MB
- Garbage collector G1 activé pour de meilleures performances

### 3. ⚠️ Mémoire insuffisante (Out of memory) - Dart/Flutter
**Problème** : Le compilateur Dart lui-même manque de mémoire lors de la compilation JIT.

**Solutions disponibles** :
- **Option 1 (Recommandée)** : Utiliser le script `run_flutter.bat` qui configure automatiquement la mémoire
- **Option 2** : Configurer `DART_VM_OPTIONS=--old-gen-heap-size=4096` dans les variables d'environnement Windows
- **Option 3** : Utiliser `flutter run --release` (mode AOT, moins de mémoire mais pas de hot reload)
- Voir `DART_MEMORY_FIX.md` pour plus de détails

## Étapes suivantes

1. **Redémarrer votre terminal/IDE** (obligatoire pour JAVA_HOME)

2. **Nettoyer le projet** :
   ```bash
   cd mobile
   flutter clean
   flutter pub get
   ```

3. **Réessayer de lancer l'application** :
   ```bash
   flutter run
   ```

## Si le problème persiste

### Vérifier JAVA_HOME
Dans un **nouveau terminal** :
```powershell
echo $env:JAVA_HOME
# Devrait afficher : C:\Program Files\Android\Android Studio\jbr

java -version
# Devrait afficher la version de Java
```

### Augmenter encore la mémoire (si vous avez 16GB+ de RAM)
Éditez `android/gradle.properties` et changez :
```
org.gradle.jvmargs=-Xmx6G ...
```

### Vérifier l'espace disque
Assurez-vous d'avoir au moins 5GB d'espace libre sur votre disque.

### Fermer d'autres applications
Fermez les applications gourmandes en mémoire (navigateurs avec beaucoup d'onglets, etc.)

## Commandes utiles

```bash
# Nettoyer complètement
flutter clean
flutter pub get

# Vérifier l'environnement
flutter doctor -v

# Voir les appareils connectés
flutter devices

# Lancer en mode release (plus rapide mais sans hot reload)
flutter run --release
```
