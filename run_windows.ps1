$ErrorActionPreference = "Stop"

Write-Host "=== Smart Homez Windows Launcher ===" -ForegroundColor Cyan
Write-Host ""

flutter doctor
if ($LASTEXITCODE -ne 0) { throw "Flutter is not installed correctly or is not on PATH." }

flutter config --enable-windows-desktop
flutter clean
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed." }

Write-Host ""
Write-Host "Starting Smart Homez on Windows..." -ForegroundColor Green
flutter run -d windows
