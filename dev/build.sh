#!/usr/bin/env bash
set -euo pipefail

install=1
backup_data=0
restore_data=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-install|-n)
      install=0
      shift
      ;;
    --install|-i)
      install=1
      shift
      ;;
    --backup-data|-b)
      backup_data=1
      shift
      ;;
    --restore-data|-r)
      restore_data=1
      shift
      ;;
    *)
      echo "Usage: $0 [--install|--no-install] [--backup-data] [--restore-data]" >&2
      exit 1
      ;;
  esac
done

# Define the path to the info.toml file
info_file="info.toml"

# Check if the info.toml file exists
if [[ ! -f "$info_file" ]]; then
  echo "info.toml file not found. Exiting script." >&2
  exit 1
fi

# Read the project name and version from the info.toml file
project_name=$(grep -oP '^\s*name\s*=\s*"\K[^"]+' $info_file)
project_version=$(grep -oP '^\s*version\s*=\s*"\K[^"]+' $info_file)

# Ensure project name and version are valid
if [[ -z "$project_name" || -z "$project_version" ]]; then
  echo "Project name or version not found in info.toml. Exiting script." >&2
  exit 1
fi

# Remove spaces from the project name and version
project_name="${project_name//[[:space:]]/}"
project_version="${project_version//[[:space:]]/}"
file_name="${project_name}-v${project_version}"

data_storage_root="${HOME}/.local/share/Steam/steamapps/compatdata/2225070/pfx/drive_c/users/steamuser/OpenplanetNext/PluginStorage"
project_data_dir="${data_storage_root}/${project_name}"
backup_dir="backup-data"
backup_file_path="${backup_dir}/${file_name}-data.zip"

# Create a versioned snapshot of this plugin's PluginStorage folder in a repo-local, gitignored directory.
if [[ $backup_data -eq 1 ]]; then
  mkdir -p "$backup_dir"
  if [[ ! -d "$project_data_dir" ]]; then
    echo "Project data directory not found: $project_data_dir" >&2
    exit 1
  fi
  rm -f "$backup_file_path"
  (
    cd "$data_storage_root"
    zip -r "$OLDPWD/$backup_file_path" "$project_name"
  )
  echo "Created data backup: $backup_file_path"
fi

# Restore the versioned snapshot into PluginStorage, replacing the current project data directory.
if [[ $restore_data -eq 1 ]]; then
  if [[ ! -f "$backup_file_path" ]]; then
    echo "Backup file not found: $backup_file_path" >&2
    exit 1
  fi
  mkdir -p "$data_storage_root"
  rm -rf "$project_data_dir"
  unzip -o "$backup_file_path" -d "$data_storage_root"
  echo "Restored data backup from: $backup_file_path"
fi

# Define the build directory and the target directory
build_dir="build"
target_dir="${build_dir}/${file_name}"

# Create the build directory if it doesn't exist
mkdir -p "$build_dir"

# Remove the specific .op file that will be overwritten
op_file_path="${build_dir}/${file_name}.op"
if [[ -f "$op_file_path" ]]; then
  echo "Removing existing .op file: $op_file_path"
  rm -f "$op_file_path"
fi

# Create the target directory
rm -rf "$target_dir"
mkdir -p "$target_dir"

# Copy the files from src, info.toml, and LICENSE into the target directory
cp -a src/. "$target_dir/"
cp "$info_file" "$target_dir/"
cp LICENSE "$target_dir/"

# Create a .zip file with files directly in the root
zip_file_path="${build_dir}/${file_name}.zip"
rm -f "$zip_file_path"
(
  cd "$target_dir"
  zip -r "$OLDPWD/$zip_file_path" .
)

# Install the plugin in the local TM installation
if [[ $install -eq 1 ]]; then
  install_dir_name="$project_name"
  destination_dir="${HOME}/.local/share/Steam/steamapps/compatdata/2225070/pfx/drive_c/users/steamuser/OpenplanetNext/Plugins"
  install_target_dir="$destination_dir/$install_dir_name"
  mkdir -p "$destination_dir"
  echo "Copying directory $install_dir_name to $destination_dir..."
  rm -rf "$install_target_dir"
  cp -a "$target_dir" "$install_target_dir"
fi

# Delete the target directory after creating the zip file
rm -rf "$target_dir"

# Rename the .zip file to .op
mv "$zip_file_path" "$op_file_path"

echo "Build completed successfully. Output file: ${file_name}.op"
