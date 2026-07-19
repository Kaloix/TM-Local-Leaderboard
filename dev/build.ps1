param(
    [bool]
    $Install = 1,

    [switch]
    $BackupData,

    [switch]
    $RestoreData
)

# Define the path to the info.toml file
$infoFilePath = "info.toml"

# Check if the info.toml file exists
if (-Not (Test-Path $infoFilePath)) {
    Write-Host "info.toml file not found. Exiting script."
    exit
}

# Read the project name and version from the info.toml file
$infoContent = Get-Content $infoFilePath
$projectName = ($infoContent | Select-String -Pattern "^name\s*=\s*['""](.+?)['""]" | ForEach-Object { if ($_ -match "^name\s*=\s*['""](.+?)['""]") { $matches[1] } })
$projectVersion = ($infoContent | Select-String -Pattern "^version\s*=\s*['""](.+?)['""]" | ForEach-Object { if ($_ -match "^version\s*=\s*['""](.+?)['""]") { $matches[1] } })

# Ensure project name and version are valid
if (-Not $projectName -or -Not $projectVersion) {
    Write-Host "Project name or version not found in info.toml. Exiting script."
    exit
}

# Remove spaces from the project name and version
$projectName = $projectName -replace "\s", ""
$projectVersion = $projectVersion -replace "\s", ""
$fileName = "$projectName-v$projectVersion"

$dataStorageRoot = "$HOME\OpenplanetNext\PluginStorage"
$projectDataDir = Join-Path $dataStorageRoot $projectName
$backupDir = "backup-data"
$backupFilePath = Join-Path $backupDir "$fileName-data.zip"

# Create a versioned snapshot of this plugin's PluginStorage folder in a repo-local, gitignored directory.
if ($BackupData) {
    if (-Not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir | Out-Null
    }
    if (-Not (Test-Path $projectDataDir)) {
        Write-Host "Project data directory not found: $projectDataDir"
        exit 1
    }
    if (Test-Path $backupFilePath) {
        Remove-Item -Path $backupFilePath -Force
    }
    Compress-Archive -Path $projectDataDir -DestinationPath $backupFilePath
    Write-Host "Created data backup: $backupFilePath"
}

# Restore the versioned snapshot into PluginStorage, replacing the current project data directory.
if ($RestoreData) {
    if (-Not (Test-Path $backupFilePath)) {
        Write-Host "Backup file not found: $backupFilePath"
        exit 1
    }
    if (-Not (Test-Path $dataStorageRoot)) {
        New-Item -ItemType Directory -Path $dataStorageRoot | Out-Null
    }
    if (Test-Path $projectDataDir) {
        Remove-Item -Path $projectDataDir -Recurse -Force
    }
    Expand-Archive -Path $backupFilePath -DestinationPath $dataStorageRoot -Force
    Write-Host "Restored data backup from: $backupFilePath"
}

# Define the build directory and the target directory
$buildDir = "build"
$targetDir = Join-Path $buildDir "$fileName"

# Create the build directory if it doesn't exist
if (-Not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

# Remove the specific .op file that will be overwritten
$opFilePath = "$buildDir\$fileName.op"
if (Test-Path $opFilePath) {
    Write-Host "Removing existing .op file: $opFilePath"
    Remove-Item -Path $opFilePath -Force
}

# Create the target directory
if (-Not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir | Out-Null
}

# Copy the files from src, info.toml, and LICENSE into the target directory
Copy-Item -Path "src\*" -Destination $targetDir -Recurse
Copy-Item -Path $infoFilePath -Destination $targetDir
Copy-Item -Path "LICENSE" -Destination $targetDir

# Create a .zip file with files directly in the root
$zipFilePath = "$buildDir\$fileName.zip"
if (Test-Path $zipFilePath) {
    Remove-Item $zipFilePath
}
Compress-Archive -Path "$targetDir\*" -DestinationPath $zipFilePath

# Install the plugin in the local TM installation
if ($Install) {
    $destinationDir = "$HOME\OpenplanetNext\Plugins"
    $installDirName = $projectName
    $installTargetDir = Join-Path $destinationDir $installDirName

    Write-Host "Copying directory $installDirName to $destinationDir..."
    if (Test-Path $installTargetDir) {
        Remove-Item -Path $installTargetDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $installTargetDir | Out-Null
    Copy-Item -Path "$targetDir\*" -Destination $installTargetDir -Recurse -Force
}

# Delete the target directory after creating the zip file
if (Test-Path $targetDir) {
    Remove-Item -Path $targetDir -Recurse -Force
}

# Rename the .zip file to .op
$opFilePath = "$fileName.op"
if (Test-Path $opFilePath) {
    Remove-Item $opFilePath
}
Rename-Item -Path $zipFilePath -NewName $opFilePath

Write-Host "Build completed successfully. Output file: $opFilePath"
