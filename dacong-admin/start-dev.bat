@echo off
cd /d "%~dp0"
echo Starting DaCong Admin in DEV MODE on port 8082...
flutter run -d chrome --web-port=8082 --dart-define=DEV_MODE=true
