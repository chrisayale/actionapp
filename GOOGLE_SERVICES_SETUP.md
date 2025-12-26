# Configuration de google-services.json

## Emplacement du fichier

Placez le fichier `google-services.json` que vous avez téléchargé depuis Firebase Console dans :

```
android/app/google-services.json
```

## Vérification

Après avoir placé le fichier, vérifiez que :
1. ✅ Le fichier `google-services.json` est dans `android/app/`
2. ✅ Le plugin Google Services est ajouté dans `android/build.gradle.kts` (déjà fait)
3. ✅ Le plugin est appliqué dans `android/app/build.gradle.kts` (déjà fait)

## Structure attendue

```
android/
└── app/
    ├── google-services.json  ← Placez le fichier ici
    ├── build.gradle.kts
    └── src/
```

## Prochaines étapes

Une fois le fichier en place :

1. **Relancer flutterfire configure** (depuis le dossier mobile si vous travaillez avec mobile/, ou depuis la racine) :
   ```bash
   cd mobile  # ou restez à la racine
   flutterfire configure
   ```

2. **Ou continuer manuellement** :
   - Le fichier `firebase_options.dart` sera généré automatiquement
   - Vous pouvez aussi le mettre à jour manuellement avec les valeurs de `google-services.json`

## Vérification finale

Pour vérifier que tout fonctionne :

```bash
cd mobile  # ou à la racine
flutter pub get
flutter run
```

Si vous voyez des erreurs liées à Firebase, vérifiez que :
- Le fichier `google-services.json` est au bon endroit
- Le package name dans `google-services.json` correspond à `com.kivugreen.actionapp`
- Les fichiers Gradle sont correctement configurés

