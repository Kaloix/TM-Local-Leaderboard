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

# Delete the target directory after creating the zip file
# if (Test-Path $targetDir) {
#     Remove-Item -Path $targetDir -Recurse -Force
# }

# Rename the .zip file to .op
$opFilePath = "$fileName.op"
if (Test-Path $opFilePath) {
    Remove-Item $opFilePath
}
Rename-Item -Path $zipFilePath -NewName $opFilePath

Write-Host "Build completed successfully. Output file: $opFilePath"
