@echo off
REM Script pour lancer Flutter avec plus de mémoire allouée à Dart

echo Configuration de la memoire pour Dart/Flutter...
set DART_VM_OPTIONS=--old-gen-heap-size=4096
set FLUTTER_BUILD_MODE=debug

echo.
echo Nettoyage du projet...
call flutter clean

echo.
echo Recuperation des dependances...
call flutter pub get

echo.
echo Lancement de l'application...
call flutter run

pause
