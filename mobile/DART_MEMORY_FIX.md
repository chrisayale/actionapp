# Solution au problème "Out of memory" de Dart/Flutter

## Problème
Flutter/Dart s'écrase avec "Out of memory" lors de la compilation d'une expression régulière complexe dans le compilateur JIT.

## Solutions

### Solution 1 : Augmenter la mémoire Dart (Recommandé)

#### Option A : Via script PowerShell (temporaire pour cette session)
```powershell
cd mobile
.\fix_dart_memory.ps1
flutter clean
flutter pub get
flutter run
```

#### Option B : Configuration permanente via variables d'environnement Windows

1. Ouvrez "Variables d'environnement" dans Windows
2. Cliquez sur "Nouveau" dans les variables utilisateur
3. Nom : `DART_VM_OPTIONS`
4. Valeur : `--old-gen-heap-size=4096`
5. Cliquez sur OK
6. **Redémarrez votre terminal/IDE**

### Solution 2 : Utiliser le mode release (moins de mémoire)

Le mode release utilise AOT au lieu de JIT, ce qui consomme moins de mémoire :

```bash
cd mobile
flutter clean
flutter pub get
flutter run --release
```

**Note** : Le mode release est plus lent à compiler mais plus rapide à exécuter. Le hot reload ne fonctionne pas en mode release.

### Solution 3 : Désactiver certaines optimisations

```bash
cd mobile
flutter clean
flutter pub get
flutter run --no-sound-null-safety --no-tree-shake-icons
```

### Solution 4 : Compiler directement sans run

Si `flutter run` échoue, essayez de compiler d'abord :

```bash
cd mobile
flutter clean
flutter pub get
flutter build apk --debug
```

Puis installez l'APK manuellement sur votre appareil.

### Solution 5 : Mettre à jour Flutter

Le problème peut être lié à une version spécifique de Flutter :

```bash
flutter upgrade
flutter doctor -v
```

### Solution 6 : Réduire la complexité du projet temporairement

Si le problème persiste, essayez de :
1. Commenter temporairement certaines dépendances dans `pubspec.yaml`
2. Simplifier le code dans `main.dart`
3. Recompiler progressivement

## Vérification

Après avoir configuré les variables d'environnement, vérifiez dans un **nouveau terminal** :

```powershell
echo $env:DART_VM_OPTIONS
# Devrait afficher : --old-gen-heap-size=4096
```

## Si rien ne fonctionne

1. **Fermez toutes les applications** pour libérer de la RAM
2. **Redémarrez votre ordinateur**
3. **Vérifiez l'espace disque** (au moins 10GB libre)
4. **Vérifiez la RAM disponible** (au moins 8GB recommandés)
5. Essayez sur un autre appareil ou émulateur

## Informations techniques

- L'erreur se produit dans le compilateur JIT de Dart
- La regex complexe fait partie du système de migration de Flutter
- Le problème est connu avec certaines versions de Flutter 3.10+
- La solution consiste à allouer plus de mémoire au VM Dart
