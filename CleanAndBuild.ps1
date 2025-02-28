function Check-Flutter {
    Write-Host "`nChecking if Flutter is installed..." -ForegroundColor Cyan
    flutter --version > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Flutter is not installed or not added to PATH. Please install Flutter and try again." -ForegroundColor Red
        exit 1
    }
    Write-Host "Flutter is installed." -ForegroundColor Green
}

function Check-FlutterProject {
    Write-Host "`nChecking if the current directory is a Flutter project..." -ForegroundColor Cyan
    if (-not (Test-Path "pubspec.yaml")) {
        Write-Host "The current directory is not a Flutter project. Make sure you're in the root of a Flutter project and try again." -ForegroundColor Red
        exit 1
    }
    Write-Host "Flutter project detected." -ForegroundColor Green
}

function Flutter-Build {
    try {
        Write-Host "`nCleaning the Flutter project..." -ForegroundColor Cyan
        flutter clean
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to clean the project."
        }
        Write-Host "Project cleaned successfully." -ForegroundColor Green

        Write-Host "`nGetting project dependencies..." -ForegroundColor Cyan
        flutter pub get
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to get project dependencies."
        }
        Write-Host "Dependencies installed successfully." -ForegroundColor Green

        Write-Host "`nBuilding APK file..." -ForegroundColor Cyan
        flutter build apk --release
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to build the APK."
        }
        Write-Host "APK build complete. You can find the APK file in the 'build/app/outputs/flutter-apk/' directory." -ForegroundColor Green

        # Open the directory where the APK file is located
        $outputPath = ".\build\app\outputs\flutter-apk"
        Write-Host "`nOpening file explorer to the APK output directory..." -ForegroundColor Cyan
        explorer.exe $outputPath
    }
    catch {
        Write-Host "`nAn error occurred during the Flutter build process: $_" -ForegroundColor Red
        exit 1
    }
}

# Main script execution
try {
    Check-Flutter
    Check-FlutterProject
    Flutter-Build
}
catch {
    Write-Host "`nA critical error occurred: $_" -ForegroundColor Red
    exit 1
}
