# Script pour augmenter la mémoire allouée à Dart/Flutter
# Ce script configure les variables d'environnement nécessaires

Write-Host "Configuration de la mémoire pour Dart/Flutter..." -ForegroundColor Cyan

# Augmenter la mémoire pour Dart VM
$dartVmArgs = "-Ddart.vm.options=--old-gen-heap-size=4096"

# Configurer les variables d'environnement pour cette session
$env:DART_VM_OPTIONS = "--old-gen-heap-size=4096"
$env:FLUTTER_BUILD_MODE = "debug"

Write-Host "Variables d'environnement configurées pour cette session:" -ForegroundColor Green
Write-Host "  DART_VM_OPTIONS = $env:DART_VM_OPTIONS" -ForegroundColor White
Write-Host ""
Write-Host "Pour une configuration permanente, ajoutez ces variables dans les Variables d'environnement Windows." -ForegroundColor Yellow
Write-Host ""
Write-Host "Essayez maintenant:" -ForegroundColor Cyan
Write-Host "  flutter clean" -ForegroundColor White
Write-Host "  flutter pub get" -ForegroundColor White
Write-Host "  flutter run --no-sound-null-safety" -ForegroundColor White
