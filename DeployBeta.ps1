
$apkDestination = "E:\Astro-Portfolio-Blog\public\downloads\app\msbridge\beta"
$logFile = "build_push.log"
$gitRepoPath = "E:\Astro-Portfolio-Blog"
$flutterProjectPath = "E:\MSBridge"
$commitMessage = "MS Bridge Beta Launch"


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

        $status = git status --porcelain 2>&1

        if ($status) {
            Log-Message "Uncommitted changes detected in $RepoPath. Please commit or stash them." -Type "Warning"
            Write-Host "Uncommitted changes detected.  Do you want to stash these changes? (y/n)" -ForegroundColor Yellow
            $answer = Read-Host
            if ($answer -eq "y") {
                Log-Message "Stashing changes..." -Type "Info"
                git stash push -u -m "Stashed changes by build script" 2>&1 | Out-Null
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
        throw $_
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
        $apkPath = Join-Path -Path $FlutterProjectPath -ChildPath "build\app\outputs\flutter-apk\app-release.apk"

        if (-not (Test-Path $apkPath)) {
            Log-Message "Could not find APK at expected path: $apkPath.  Ensure that you built the project." -Type "Error"
            throw "Could not find APK at expected path."
        }
        Log-Message "APK found at: $apkPath" -Type "Info"
        return $apkPath
    }
    catch {
        Log-Message "Error determining APK location: $($_.Exception.Message)" -Type "Error"
        throw
    }
}


try {
    Log-Message "Starting script execution..." -Type "Info"

    Write-Host "Did you already build the release APK for the Flutter project? (y/n)" -ForegroundColor Cyan
    $buildAnswer = Read-Host

    if ($buildAnswer -ne "y") {
        Log-Message "User chose not to push without building. Exiting." -Type "Warning"
        Write-Host "Exiting script." -ForegroundColor Yellow
        exit 0
    }

    try {
        $apkPath = Determine-APK-Location -FlutterProjectPath $flutterProjectPath
    }
    catch {
        Log-Message "Failed to determine APK location. Check logs" -Type "Error"
        throw "Failed to determine APK location."
    }

    try {
        Push-Location $gitRepoPath
        Check-For-Changes -RepoPath $gitRepoPath
        Pop-Location
    }
    catch {
        Log-Message "Aborted due to changes check failure: $($_.Exception.Message)" -Type "Error"
        throw
    }


    Log-Message "Moving APK file to $apkDestination..." -Type "Info"
    try {
        if (!(Test-Path -Path $apkDestination)) {
            New-Item -ItemType Directory -Force -Path $apkDestination | Out-Null
        }

        Get-ChildItem -Path $apkDestination | Remove-Item -Force

        Copy-Item -Path $apkPath -Destination $apkDestination -Force

        Log-Message "APK file moved successfully." -Type "Info"
    }
    catch {
        Log-Message "Error moving APK file: $($_.Exception.Message)" -Type "Error"
        throw
    }

    try {
        Push-Location $gitRepoPath
    }
    catch {
        Log-Message "Error navigating to Git repository at $gitRepoPath : $($_.Exception.Message)" -Type "Error"
        throw
    }


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


    Log-Message "Pushing the APK file to GitHub..." -Type "Info"
    try {
        git add "$apkDestination\*"

        git commit -m "$commitMessage" 2>&1 | Out-Null
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
    Pop-Location
    Log-Message "Script execution completed." -Type "Info"
    exit 0
}