# Script PowerShell pour arrêter le processus utilisant le port 3000

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Arrêt du processus sur le port 3000" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Trouver le processus utilisant le port 3000
$process = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique

if ($process) {
    $processId = $process
    $processInfo = Get-Process -Id $processId -ErrorAction SilentlyContinue
    
    if ($processInfo) {
        Write-Host "Processus trouvé sur le port 3000:" -ForegroundColor Yellow
        Write-Host "   PID: $processId" -ForegroundColor Yellow
        Write-Host "   Nom: $($processInfo.ProcessName)" -ForegroundColor Yellow
        Write-Host "   Chemin: $($processInfo.Path)" -ForegroundColor Yellow
        Write-Host ""
        
        $response = Read-Host "Voulez-vous arrêter ce processus? (O/N)"
        if ($response -eq 'O' -or $response -eq 'o') {
            try {
                Stop-Process -Id $processId -Force
                Write-Host "✅ Processus arrêté avec succès!" -ForegroundColor Green
                Write-Host ""
                Write-Host "Vous pouvez maintenant redémarrer le serveur backend." -ForegroundColor Cyan
            } catch {
                Write-Host "❌ Erreur lors de l'arrêt du processus:" -ForegroundColor Red
                Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
                Write-Host ""
                Write-Host "Essayez d'arrêter le processus manuellement:" -ForegroundColor Yellow
                Write-Host "   taskkill /PID $processId /F" -ForegroundColor Yellow
            }
        } else {
            Write-Host "❌ Opération annulée" -ForegroundColor Red
        }
    } else {
        Write-Host "⚠️  Processus trouvé (PID: $processId) mais impossible d'obtenir les informations" -ForegroundColor Yellow
        Write-Host ""
        $response = Read-Host "Voulez-vous quand même arrêter ce processus? (O/N)"
        if ($response -eq 'O' -or $response -eq 'o') {
            try {
                Stop-Process -Id $processId -Force
                Write-Host "✅ Processus arrêté avec succès!" -ForegroundColor Green
            } catch {
                Write-Host "❌ Erreur lors de l'arrêt du processus:" -ForegroundColor Red
                Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
                Write-Host ""
                Write-Host "Essayez d'arrêter le processus manuellement:" -ForegroundColor Yellow
                Write-Host "   taskkill /PID $processId /F" -ForegroundColor Yellow
            }
        }
    }
} else {
    Write-Host "✅ Aucun processus trouvé sur le port 3000" -ForegroundColor Green
    Write-Host "   Le port est libre, vous pouvez démarrer le serveur." -ForegroundColor Green
}

Write-Host ""
pause
