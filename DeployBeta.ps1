# PowerShell script to move and push APK to GitHub

# --- Configuration ---
$apkDestination = "E:\Astro-Portfolio-Blog\public\downloads\app\msbridge\beta"
$logFile = "build_push.log"
$gitRepoPath = "E:\Astro-Portfolio-Blog"  # Path to the root of the git repo.
$flutterProjectPath = "E:\MSBridge"        # Path to the root of your Flutter Project. MUST be different from the git path.
$commitMessage = "MS Bridge Beta Launch" # Customize this commit message

#--- Functions ---

function Log-Message {
    param (
        [string]$Message,
        [string]$Type = "Info"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp [$Type]: $Message"
    Add-Content -Path $logFile -Value $LogEntry
    Write-Host $LogEntry
}

function Check-For-Changes {
    param (
        [string]$RepoPath
    )

    try {
        Push-Location $RepoPath

        # Check for uncommitted changes
        $status = git status --porcelain 2>&1

        if ($status) {
            Log-Message "Uncommitted changes detected in $RepoPath. Please commit or stash them." -Type "Warning"
            Write-Host "Uncommitted changes detected.  Do you want to stash these changes? (y/n)" -ForegroundColor Yellow
            $answer = Read-Host
            if ($answer -eq "y") {
                Log-Message "Stashing changes..." -Type "Info"
                git stash push -u -m "Stashed changes by build script" 2>&1 | Out-Null # Push changes with message
                if ($LASTEXITCODE -ne 0) {
                    Log-Message "Failed to stash changes." -Type "Error"
                    throw "Failed to stash changes."
                }
                Log-Message "Changes stashed successfully." -Type "Info"
            }
            else {
                Log-Message "User chose not to stash changes. Exiting." -Type "Warning"
                Write-Host "Exiting script." -ForegroundColor Yellow
                throw "Uncommitted changes present. User chose to exit."
            }
        }
        else {
            Log-Message "No uncommitted changes detected." -Type "Info"
        }
    }
    catch {
        Log-Message "Error checking for changes: $($_.Exception.Message)" -Type "Error"
        throw $_  # Re-throw exception for handling in the main script
    }
    finally {
        Pop-Location
    }
}

function Determine-APK-Location {
    param (
        [string]$FlutterProjectPath
    )

    Log-Message "Determining APK location..." -Type "Info"
    try {
        # Construct the expected path to the APK
        $apkPath = Join-Path -Path $FlutterProjectPath -ChildPath "build\app\outputs\flutter-apk\app-release.apk"

        if (-not (Test-Path $apkPath)) {
            Log-Message "Could not find APK at expected path: $apkPath.  Ensure that you built the project." -Type "Error"
            throw "Could not find APK at expected path."
        }
        Log-Message "APK found at: $apkPath" -Type "Info"
        return $apkPath #Return the path
    }
    catch {
        Log-Message "Error determining APK location: $($_.Exception.Message)" -Type "Error"
        throw #Re-throw the exception
    }
}

# --- Main Script ---

try {
    Log-Message "Starting script execution..." -Type "Info"

    # 1. Ask User if Project Built
    Write-Host "Did you already build the release APK for the Flutter project? (y/n)" -ForegroundColor Cyan
    $buildAnswer = Read-Host

    if ($buildAnswer -ne "y") {
        Log-Message "User chose not to push without building. Exiting." -Type "Warning"
        Write-Host "Exiting script." -ForegroundColor Yellow
        exit 0 # Exit cleanly
    }

    #2. Get Path of the APK
    try {
        $apkPath = Determine-APK-Location -FlutterProjectPath $flutterProjectPath
    }
    catch {
        Log-Message "Failed to determine APK location. Check logs" -Type "Error"
        throw "Failed to determine APK location."
    }

    # 3. Check for Uncommitted Changes (BEFORE Moving the APK)
    try {
        Push-Location $gitRepoPath
        Check-For-Changes -RepoPath $gitRepoPath #Call function, which either stashes or exits on error.
        Pop-Location #Return to the folder before the git push, for moving the files
    }
    catch {
        Log-Message "Aborted due to changes check failure: $($_.Exception.Message)" -Type "Error"
        throw
    }

    # 4. Move the APK file

    Log-Message "Moving APK file to $apkDestination..." -Type "Info"
    try {
        # Create the destination directory if it doesn't exist
        if (!(Test-Path -Path $apkDestination)) {
            New-Item -ItemType Directory -Force -Path $apkDestination | Out-Null
        }

        # Remove all files in the destination directory
        Get-ChildItem -Path $apkDestination | Remove-Item -Force

        # Copy the new APK file to the destination
        Copy-Item -Path $apkPath -Destination $apkDestination -Force

        Log-Message "APK file moved successfully." -Type "Info"
    }
    catch {
        Log-Message "Error moving APK file: $($_.Exception.Message)" -Type "Error"
        throw
    }

    # 5. Navigate to the Git Repository
    try {
        Push-Location $gitRepoPath
    }
    catch {
        Log-Message "Error navigating to Git repository at $gitRepoPath : $($_.Exception.Message)" -Type "Error"
        throw
    }

    # 6. Check the Branch

    Log-Message "Checking the current branch..." -Type "Info"
    try {
        $currentBranch = git branch --show-current 2>&1
        if ($currentBranch -ne "main") {
            Log-Message "You are not on the main branch. Current branch is: $currentBranch" -Type "Warning"
            Write-Host "You are not on the 'main' branch.  Are you sure you want to continue? (y/n)" -ForegroundColor Yellow
            $answer = Read-Host
            if ($answer -ne "y") {
                Log-Message "User chose not to continue because they are not on main branch. Exiting." -Type "Warning"
                Write-Host "Exiting script." -ForegroundColor Yellow
                throw "Not on main branch. User chose to exit."
            }
        }
        else {
            Log-Message "You are on the main branch." -Type "Info"
        }
    }
    catch {
        Log-Message "Error checking the current branch: $($_.Exception.Message)" -Type "Error"
        throw
    }

    # 7. Push the APK file and the build log to GitHub

    Log-Message "Pushing the APK file to GitHub..." -Type "Info"
    try {
        git add "$apkDestination\*" # Add the new files in $apkDestination

        git commit -m "$commitMessage" 2>&1 | Out-Null  # Use the configured commit message
        git push origin main 2>&1 | Out-Null

        if ($LASTEXITCODE -ne 0) {
            Log-Message "Failed to push APK to GitHub." -Type "Error"
            throw "Failed to push to github"
        }

        Log-Message "APK file pushed to GitHub successfully." -Type "Info"
    }
    catch {
        Log-Message "Error pushing APK file to GitHub: $($_.Exception.Message)" -Type "Error"
        throw
    }
}
catch {
    Log-Message "Script failed. $($_.Exception.Message)" -Type "Error"
    exit 1
}
finally {
    Pop-Location # Ensure we return to where we started
    Log-Message "Script execution completed." -Type "Info"
    exit 0
}