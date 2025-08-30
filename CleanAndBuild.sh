#!/bin/zsh

# --- ANSI Color Codes for pretty output ---
# Nifty little trick to make your terminal pop!
NC='\033[0m'       # No Color - Resets the text to default
RED='\033[31m'
GREEN='\033[32m'
CYAN='\033[36m'

# --- Function to check if Flutter is installed ---
# Gotta make sure your dev environment is ready to fly!
check_flutter() {
    echo "\n${CYAN}Checking if Flutter is installed...${NC}"
    # Redirecting output to /dev/null keeps things tidy!
    flutter --version > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "${RED}Flutter is not installed or not added to PATH. Please install Flutter and try again.${NC}"
        exit 1 # Exiting gracefully (or not so gracefully, in this case!)
    fi
    echo "${GREEN}Flutter is installed.${NC}"
}

# --- Function to check if the current directory is a Flutter project ---
# Let's not build the wrong thing, right?
check_flutter_project() {
    echo "\n${CYAN}Checking if the current directory is a Flutter project...${NC}"
    # `[ -f "pubspec.yaml" ]` is the Zsh way to check for a file!
    if [ ! -f "pubspec.yaml" ]; then
        echo "${RED}The current directory is not a Flutter project. Make sure you're in the root of a Flutter project and try again.${NC}"
        exit 1
    fi
    echo "${GREEN}Flutter project detected.${NC}"
}

# --- Function to clean, get dependencies, and build the Flutter APK ---
# The heavy lifting happens here!
flutter_build() {
    echo "\n${CYAN}Cleaning the Flutter project...${NC}"
    # Using `if ! command; then` is a concise way to check for command failure.
    if ! flutter clean; then
        echo "\n${RED}An error occurred during the Flutter build process: Failed to clean the project.${NC}"
        exit 1
    fi
    echo "${GREEN}Project cleaned successfully.${NC}"

    echo "\n${CYAN}Getting project dependencies...${NC}"
    if ! flutter pub get; then
        echo "\n${RED}An error occurred during the Flutter build process: Failed to get project dependencies.${NC}"
        exit 1
    fi
    echo "${GREEN}Dependencies installed successfully.${NC}"

    echo "\n${CYAN}Building APK file...${NC}"
    if ! flutter build apk --release; then
        echo "\n${RED}An error occurred during the Flutter build process: Failed to build the APK.${NC}"
        exit 1
    fi
    echo "${GREEN}APK build complete. You can find the APK file in the 'build/app/outputs/flutter-apk/' directory.${NC}"

    # On macOS, `open` is your friend for opening files or directories!
    local outputPath="./build/app/outputs/flutter-apk"
    echo "\n${CYAN}Opening file explorer to the APK output directory...${NC}"
    open "$outputPath"
}

# --- Main script execution ---
# Bringing it all together!
main() {
    # Each of these functions will exit the script if they encounter a problem,
    # mimicking the PowerShell `try-catch`'s quick fail behavior.
    check_flutter
    check_flutter_project
    flutter_build
    
    echo "\n${GREEN}Flutter build process completed successfully! Happy deploying!${NC}\n"
}

# Let's kick things off!
main