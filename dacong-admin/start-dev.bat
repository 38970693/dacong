@echo off
cd /d "%~dp0"
echo Starting DaCong Admin in DEV MODE...
flutter run -d chrome --dart-define=DEV_MODE=true
