#!/bin/zsh

# --- ANSI Color Codes for pretty output ---
# Adding some flair to your terminal messages!
NC='\033[0m'       # No Color - Resets the text to default
RED='\033[31m'
GREEN='\033[32m'
CYAN='\033[36m'
YELLOW='\033[33m'

# --- Define the emulator name ---
# Make sure this matches your AVD name exactly!
emulatorName="Prometheus"

# --- Function to check if the emulator is already running ---
# We'll leverage 'flutter devices' and 'grep' for this check.
is_emulator_running() {
    # 'flutter devices' lists all connected devices and running emulators.
    # 'grep -q' searches for the emulator name quietly, returning 0 if found, 1 if not.
    flutter devices | grep -q "$emulatorName"
    return $? # Returns the exit status of grep (0 for found, 1 for not found)
}

# --- Function to launch the emulator if not running ---
launch_emulator() {
    echo "\n${CYAN}Checking emulator status...${NC}"
    if ! is_emulator_running; then
        echo "${YELLOW}Emulator '$emulatorName' is not running. Launching...${NC}"
        # `flutter emulators --launch` is the command to start it up.
        if ! flutter emulators --launch "$emulatorName"; then
            echo "${RED}Failed to launch emulator '$emulatorName'. Please check your Android SDK setup.${NC}"
            exit 1
        fi
        echo "${YELLOW}Emulator '$emulatorName' launched. Waiting 10 seconds for full boot...${NC}"
        sleep 10 # Give the emulator some time to become fully ready.
        echo "${GREEN}Emulator should be ready now!${NC}"
    else
        echo "${GREEN}Emulator '$emulatorName' is already running. Awesome!${NC}"
    fi
}

# --- Main script execution ---
# This brings all the pieces together for your dev session.
main() {
    # Attempt to launch the specified emulator
    launch_emulator

    # --- Clean the Flutter project ---
    echo "\n${CYAN}Cleaning the Flutter project...${NC}"
    if ! flutter clean; then
        echo "${RED}An error occurred: Failed to clean the Flutter project.${NC}"
        exit 1
    fi
    echo "${GREEN}Project cleaned successfully.${NC}"

    # --- Get project dependencies ---
    echo "\n${CYAN}Getting project dependencies...${NC}"
    if ! flutter pub get; then
        echo "${RED}An error occurred: Failed to get project dependencies.${NC}"
        exit 1
    fi
    echo "${GREEN}Dependencies installed successfully.${NC}"

    # --- Run the project on the emulator ---
    echo "\n${CYAN}Running the project on emulator '$emulatorName'...${NC}"
    # `flutter run -d emulator` will automatically pick the running emulator.
    # This command will remain active until you manually stop it in the terminal.
    if ! flutter run -d emulator; then
        echo "${RED}An error occurred: Failed to run the project on emulator '$emulatorName'.${NC}"
        exit 1
    fi
    echo "\n${GREEN}Flutter project is now running on your emulator! Happy coding!${NC}\n"
}

# Let's get this show on the road!
main