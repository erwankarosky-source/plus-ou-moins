@echo off
chcp 65001 >nul
rem Telecharge la derniere version de la branche "supabase" et l'ouvre dans ton navigateur.
rem Aucune installation : double-clique simplement sur ce fichier. Le serveur Supabase est utilise normalement.
set BRANCHE=supabase
set DOSSIER=%~dp0essai
echo Telechargement de la derniere version (%BRANCHE%)...
if exist "%DOSSIER%" rmdir /s /q "%DOSSIER%"
mkdir "%DOSSIER%"
powershell -NoProfile -Command "try { Invoke-WebRequest -UseBasicParsing 'https://github.com/erwankarosky-source/plus-ou-moins/archive/refs/heads/%BRANCHE%.zip' -OutFile '%DOSSIER%\v.zip'; Expand-Archive -Force '%DOSSIER%\v.zip' '%DOSSIER%' } catch { Write-Host 'Echec du telechargement :' $_.Exception.Message; exit 1 }"
if errorlevel 1 ( pause & exit /b 1 )
start "" "%DOSSIER%\plus-ou-moins-%BRANCHE%\www\index.html"
echo Ouvert dans ton navigateur. Pour tester la derniere version, relance ce fichier.
timeout /t 4 >nul
