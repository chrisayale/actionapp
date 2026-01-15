# Script PowerShell pour ajouter une règle de firewall pour le port 3000
# IMPORTANT: Ce script doit être exécuté en tant qu'administrateur

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Configuration du firewall" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier si le script est exécuté en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ ERREUR: Ce script doit être exécuté en tant qu'administrateur!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Pour exécuter ce script:" -ForegroundColor Yellow
    Write-Host "1. Clic droit sur PowerShell" -ForegroundColor Yellow
    Write-Host "2. Sélectionnez 'Exécuter en tant qu'administrateur'" -ForegroundColor Yellow
    Write-Host "3. Naviguez vers le dossier backend" -ForegroundColor Yellow
    Write-Host "4. Exécutez: .\add_firewall_rule.ps1" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Ou utilisez le guide manuel dans FIREWALL_TROUBLESHOOTING.md" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

# Vérifier si la règle existe déjà
$existingRule = Get-NetFirewallRule -DisplayName "Backend Node.js Port 3000" -ErrorAction SilentlyContinue

if ($existingRule) {
    Write-Host "⚠️  Une règle existe déjà pour le port 3000" -ForegroundColor Yellow
    Write-Host "   Nom: $($existingRule.DisplayName)" -ForegroundColor Yellow
    Write-Host "   Activée: $($existingRule.Enabled)" -ForegroundColor Yellow
    Write-Host ""
    $response = Read-Host "Voulez-vous la supprimer et en créer une nouvelle? (O/N)"
    if ($response -eq 'O' -or $response -eq 'o') {
        Remove-NetFirewallRule -DisplayName "Backend Node.js Port 3000" -ErrorAction SilentlyContinue
        Write-Host "✅ Règle existante supprimée" -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host "❌ Opération annulée" -ForegroundColor Red
        pause
        exit 0
    }
}

# Créer la nouvelle règle
Write-Host "Création de la règle de firewall pour le port 3000..." -ForegroundColor Yellow
Write-Host ""

try {
    New-NetFirewallRule `
        -DisplayName "Backend Node.js Port 3000" `
        -Direction Inbound `
        -LocalPort 3000 `
        -Protocol TCP `
        -Action Allow `
        -Profile Domain,Private,Public `
        -Description "Autorise les connexions entrantes sur le port 3000 pour le serveur backend Node.js (nécessaire pour l'émulateur Android)"

    Write-Host "✅ Règle de firewall créée avec succès!" -ForegroundColor Green
    Write-Host ""
    Write-Host "La règle autorise maintenant:" -ForegroundColor Cyan
    Write-Host "  - Connexions entrantes sur le port 3000" -ForegroundColor Cyan
    Write-Host "  - Pour tous les profils réseau (Domaine, Privé, Public)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Vous pouvez maintenant tester votre application Flutter!" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "❌ ERREUR lors de la création de la règle:" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Essayez de créer la règle manuellement:" -ForegroundColor Yellow
    Write-Host "1. Ouvrez le Pare-feu Windows Defender (wf.msc)" -ForegroundColor Yellow
    Write-Host "2. Créez une nouvelle règle entrante pour le port TCP 3000" -ForegroundColor Yellow
    Write-Host "3. Voir FIREWALL_TROUBLESHOOTING.md pour les instructions détaillées" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

pause
