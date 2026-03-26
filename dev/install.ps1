# Define paths
$buildScriptPath = "$(Split-Path -Parent $PSCommandPath)\build.ps1"
$buildDir = "$(Split-Path -Parent $PSCommandPath)\..\build"
$destinationDir = "$HOME\OpenplanetNext\Plugins"

# Step 1: Call the build.ps1 script
if (-Not (Test-Path $buildScriptPath)) {
    Write-Host "build.ps1 script not found. Exiting script."
    exit
}

Write-Host "Running build.ps1..."
& $buildScriptPath

# Step 2: Copy the original directory to the destination directory
$originalDir = Get-ChildItem -Path $buildDir -Directory | Select-Object -First 1

if (-Not $originalDir) {
    Write-Host "No directory found in the build directory. Exiting script."
    exit
}

if (-Not (Test-Path $destinationDir)) {
    Write-Host "Creating destination directory: $destinationDir"
    New-Item -ItemType Directory -Path $destinationDir | Out-Null
}

Write-Host "Copying directory $($originalDir.Name) to $destinationDir..."
Copy-Item -Path $originalDir.FullName -Destination $destinationDir -Recurse -Force

Write-Host "Installation completed successfully."
