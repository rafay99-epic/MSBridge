# Define the emulator name
$emulatorName = "Prometheus"

# Function to check if the emulator is already running
function Is-EmulatorRunning {
    $adbDevices = flutter devices
    return $adbDevices -match $emulatorName
}

# Function to launch the emulator if not running
function Launch-Emulator {
    if (-not (Is-EmulatorRunning)) {
        Write-Host "Launching emulator '$emulatorName'..."
        flutter emulators --launch $emulatorName

        # Wait for the emulator to fully boot up
        Start-Sleep -Seconds 10
    }
    else {
        Write-Host "Emulator '$emulatorName' is already running."
    }
}

# Main script execution
try {
    # Launch the emulator if not running
    Launch-Emulator

    # Clean the Flutter project
    Write-Host "Cleaning the Flutter project..."
    flutter clean

    # Install dependencies
    Write-Host "Getting project dependencies..."
    flutter pub get

    # Run the project on the emulator
    Write-Host "Running the project on emulator '$emulatorName'..."
    flutter run -d emulator
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}
