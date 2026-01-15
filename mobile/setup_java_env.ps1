# Script pour configurer JAVA_HOME pour Flutter/Android
# Exécutez ce script dans PowerShell en tant qu'administrateur, ou configurez manuellement

$javaPath = "C:\Program Files\Android\Android Studio\jbr"

if (Test-Path $javaPath) {
    Write-Host "Java trouvé à: $javaPath" -ForegroundColor Green
    
    # Vérifier si JAVA_HOME est déjà défini
    $currentJavaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "User")
    
    if ($currentJavaHome -and $currentJavaHome -eq $javaPath) {
        Write-Host "JAVA_HOME est déjà configuré correctement." -ForegroundColor Yellow
    } else {
        Write-Host "Configuration de JAVA_HOME..." -ForegroundColor Cyan
        [Environment]::SetEnvironmentVariable("JAVA_HOME", $javaPath, "User")
        Write-Host "JAVA_HOME configuré à: $javaPath" -ForegroundColor Green
        Write-Host ""
        Write-Host "IMPORTANT: Vous devez redémarrer votre terminal ou votre IDE pour que les changements prennent effet." -ForegroundColor Yellow
    }
    
    # Ajouter Java au PATH si nécessaire
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $javaBinPath = "$javaPath\bin"
    
    if ($currentPath -notlike "*$javaBinPath*") {
        Write-Host "Ajout de Java au PATH..." -ForegroundColor Cyan
        $newPath = "$currentPath;$javaBinPath"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "Java ajouté au PATH." -ForegroundColor Green
    } else {
        Write-Host "Java est déjà dans le PATH." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Pour vérifier, exécutez dans un nouveau terminal:" -ForegroundColor Cyan
    Write-Host "  echo `$env:JAVA_HOME" -ForegroundColor White
    Write-Host "  java -version" -ForegroundColor White
    
} else {
    Write-Host "Java non trouvé à l'emplacement attendu: $javaPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Veuillez installer Android Studio ou Java JDK 17+ et réessayer." -ForegroundColor Yellow
    exit 1
}
