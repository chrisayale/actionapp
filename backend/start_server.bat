@echo off
REM Script pour démarrer le serveur backend

echo ========================================
echo   Demarrage du serveur backend
echo ========================================
echo.

REM Vérifier si node_modules existe
if not exist "node_modules" (
    echo Installation des dependances...
    call npm install
    echo.
)

REM Vérifier si .env existe
if not exist ".env" (
    echo Creation du fichier .env depuis env.example.txt...
    copy env.example.txt .env >nul 2>&1
    echo.
    echo ⚠️  ATTENTION: Le fichier .env a ete cree avec des valeurs par defaut.
    echo    Vous DEVEZ le configurer avec vos credentials Firebase pour utiliser Firebase en production.
    echo.
    echo 📖 Guide de configuration: Voir FIREBASE_PRODUCTION_SETUP.md
    echo.
)

echo Demarrage du serveur en mode developpement...
echo Le serveur sera accessible sur http://localhost:3000
echo.
echo Appuyez sur Ctrl+C pour arreter le serveur
echo.

call npm run dev

pause
