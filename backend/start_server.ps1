# Script PowerShell pour démarrer le serveur backend

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Démarrage du serveur backend" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier si node_modules existe
if (-not (Test-Path "node_modules")) {
    Write-Host "Installation des dépendances..." -ForegroundColor Yellow
    npm install
    Write-Host ""
}

# Vérifier si .env existe
if (-not (Test-Path ".env")) {
    Write-Host "Création du fichier .env depuis env.example.txt..." -ForegroundColor Yellow
    Copy-Item env.example.txt .env -ErrorAction SilentlyContinue
    Write-Host ""
    Write-Host "⚠️  ATTENTION: Le fichier .env a été créé avec des valeurs par défaut." -ForegroundColor Yellow
    Write-Host "   Vous DEVEZ le configurer avec vos credentials Firebase pour utiliser Firebase en production." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📖 Guide de configuration: Voir FIREBASE_PRODUCTION_SETUP.md" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "Démarrage du serveur en mode développement..." -ForegroundColor Green
Write-Host "Le serveur sera accessible sur http://localhost:3000" -ForegroundColor Green
Write-Host ""
Write-Host "Appuyez sur Ctrl+C pour arrêter le serveur" -ForegroundColor Yellow
Write-Host ""

npm run dev
