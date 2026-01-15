@echo off
REM Script pour arrêter le processus utilisant le port 3000

echo ========================================
echo   Arret du processus sur le port 3000
echo ========================================
echo.

REM Trouver le PID du processus utilisant le port 3000
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000 ^| findstr LISTENING') do (
    set PID=%%a
    goto :found
)

:found
if defined PID (
    echo Processus trouve sur le port 3000:
    echo    PID: %PID%
    echo.
    
    REM Obtenir le nom du processus
    for /f "tokens=1" %%b in ('tasklist /FI "PID eq %PID%" /FO LIST ^| findstr "Nom"') do (
        for /f "tokens=2" %%c in ('tasklist /FI "PID eq %PID%" /FO LIST ^| findstr "Nom"') do (
            echo    Nom: %%c
        )
    )
    echo.
    
    set /p response="Voulez-vous arreter ce processus? (O/N): "
    if /i "%response%"=="O" (
        echo.
        echo Arret du processus...
        taskkill /PID %PID% /F
        if errorlevel 1 (
            echo.
            echo ❌ Erreur lors de l'arret du processus
            echo    Vous pouvez essayer manuellement: taskkill /PID %PID% /F
        ) else (
            echo.
            echo ✅ Processus arrete avec succes!
            echo    Vous pouvez maintenant redemarrer le serveur backend.
        )
    ) else (
        echo.
        echo ❌ Operation annulee
    )
) else (
    echo ✅ Aucun processus trouve sur le port 3000
    echo    Le port est libre, vous pouvez demarrer le serveur.
)

echo.
pause
