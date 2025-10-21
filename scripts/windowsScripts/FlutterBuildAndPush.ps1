# Check if Flutter is installed
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Flutter is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Step 1: Run 'flutter analyze'
Write-Host "Running 'flutter analyze'..."
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "'flutter analyze' failed. Please fix the issues before proceeding." -ForegroundColor Red
    exit 1
}
Write-Host "'flutter analyze' completed successfully." -ForegroundColor Green

# Step 2: Build APK
Write-Host "Building APK in release mode..."
flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "'flutter build apk --release' failed. Please check the issues and try again." -ForegroundColor Red
    exit 1
}
Write-Host "APK built successfully." -ForegroundColor Green

# Step 3: Git operations
Write-Host "Adding all changes to Git..."
git add *
if ($LASTEXITCODE -ne 0) {
    Write-Host "Git add failed. Please check the repository and try again." -ForegroundColor Red
    exit 1
}

# Prompt for commit message
$commitMessage = Read-Host "Enter the commit message"
if ([string]::IsNullOrWhiteSpace($commitMessage)) {
    Write-Host "Commit message cannot be empty. Exiting." -ForegroundColor Red
    exit 1
}

Write-Host "Committing changes..."
git commit -m $commitMessage
if ($LASTEXITCODE -ne 0) {
    Write-Host "Git commit failed. Please check the repository and try again." -ForegroundColor Red
    exit 1
}

Write-Host "Pushing changes to the repository..."
git push
if ($LASTEXITCODE -ne 0) {
    Write-Host "Git push failed. Please check the repository and try again." -ForegroundColor Red
    exit 1
}

Write-Host "All operations completed successfully." -ForegroundColor Green
