#!/bin/bash
##############################################################################
#
# Author: Logan Mancuso
# Created: 07.31.2024
#
##############################################################################

# Redirect all output to log file
exec > >(tee -a "backup.log") 2>&1

# Helper function
function helper() {
  # Add the logic that the script will perform here
    echo -e "START:\thelper"
  # Run a Backup on my system ##
  bw-auth
  # Retrieve the JSON from Bitwarden
  echo "Retrieving Restic Vault Secret"
  vault_json=$(bw get item "Restic Vault" --session "$BW_SESSION")
  if [ $? -ne 0 ]; then
    echo "Failed to retrieve item from Bitwarden."
    return 1
  fi
  # Use jq to extract the name and value fields and prefix them with 'export'
  export_commands=$(echo "$vault_json" | jq -r '.fields[] | "export \(.name)=\(.value)"')
  if [ $? -ne 0 ]; then
    echo "Failed to parse JSON from Bitwarden."
    return 1
  fi

  # Evaluate the export commands to set the environment variables
  echo "Setting Restic Vault Secret"
  eval "$export_commands"

  ## Raw Copy files for restore of system ##
  local raw_copy=("os-init")
  for this_folder in "${raw_copy[@]}"; do
    echo -e "START:\tbackup $this_folder"
    case $this_folder in 
      "os-init")
        # backup files to nextcloud documents
        sudo cp -R "$HOME/.gitconfig" "$HOME/Documents/Backups/os-init/secrets/gitconfig"
        sudo cp -R "$HOME/.ssh" "$HOME/Documents/Backups/os-init/secrets/ssh"
        sudo cp -R "$HOME/.gnupg" "$HOME/Documents/Backups/os-init/secrets/gnupg"
        sudo cp "$HOME/SourceControl/Personal/Infrastructure/Proxmox/global-secrets/env/terraform.tfvars" "$HOME/Documents/Backups/os-init/secrets/global_secrets.tfvars"
        sudo cp "$HOME/SourceControl/Personal/Infrastructure/Applications/vault/keys/keys.tar.gz" "$HOME/Documents/Backups/os-init/secrets/keys.tar.gz"
        sudo cp -R "$HOME/Documents/Backups/os-init" "$path_usb" --force --verbose
        ;;
      * )
        echo "Folder Not Recognized"
        return 1
        ;;
    esac
    echo -e "END:\tbackup $this_folder"
  done

  ## Restic Backup ##
  local vault_name=("home")
  for this_vault in "${vault_name[@]}"; do
    echo -e "START:\tbackup $this_vault"
    local vault_path="$path_usb/$this_vault.vault"
    if [ -d "$vault_path" ]; then
      echo "Restic repository already initialized in $vault_path."
    else
      echo "Initializing Restic repository in $vault_path..."
      sudo -E restic init --verbose --repo "$vault_path"
    fi
    # Define paths to backup for each vault
    case $this_vault in
      "home")
        backup_paths=(
          "$HOME/SourceControl"
          "$HOME/Documents"
          "$HOME/Downloads"
        )
        ;;
      *) 
        echo "Vault name not recognized."
        return 1
        ;;
    esac
    
    # Back up each path
    for path in "${backup_paths[@]}"; do
      # Pass Restic password from file
      sudo -E restic --verbose --repo "$vault_path" backup "$path"
    done
    
    # Prune old backups
    sudo -E restic --verbose --repo "$vault_path" forget --keep-last 15 --prune
    sudo -E restic --verbose --repo "$vault_path" snapshots
    echo -e "END:\tbackup $vault_name"
  done
  unset RESTIC_PASSWORD
  sudo umount $path_usb

  echo -e "END:\thelper"
}

# Main function
function main() {
  echo -e "START:\tmain"
  # Display system information
  echo "System Information:"
  echo "hostname: $(cat /etc/hostname)"
  echo "cpu: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
  echo "memory: $(free | grep Mem | awk '{print $3/$2 * 100.0"%"}')"
  echo "user: $(whoami)"
  echo "time: $(date)"
  source $HOME/.config/bash/bash_aliases
  # Ensure exactly one argument is provided
  if [ $# -gt 1 ]; then
    echo "Only One Argument at a time"
    echo "Usage: $0 /dev/sdXn "
    return 1
  fi
  local path_usb="/media/$USER/usb-backup"
  sudo mkdir -p $path_usb
  echo $1
  sleep 60
  sudo mount $1 $path_usb
  helper
  echo -e "END:\tmain"
}

# Start the script
main "$@"