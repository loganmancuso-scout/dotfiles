#!/bin/bash
##############################################################################
#
# Author: Logan Mancuso
# Created: 07.31.2024
#
##############################################################################

# Redirect all output to log file
exec > >(tee -a "init-debian.log") 2>&1

# Record the start time
START_TIME=$(date +%s)

# Function to calculate elapsed time
function print_ascii_time() {
  local message=$1
  local current_time=$(date +%s)
  local elapsed_time=$((current_time - START_TIME))
  local hours=$((elapsed_time / 3600))
  local minutes=$(( (elapsed_time % 3600) / 60 ))
  local seconds=$((elapsed_time % 60))
  printf "\nElapsed Time: %02d:%02d:%02d - %s\n" $hours $minutes $seconds "$message"
  echo -e "######################################################\n"
}

function bw-auth(){
  print_ascii_time "Starting bw-auth"
  
  if [ -z "$BW_SESSION" ]; then
    if [ -f /tmp/bw.env ]; then
      source /tmp/bw.env
    fi
    if [ -z "$BW_SESSION" ]; then
      echo "Logging in to Bitwarden..."
      local login_output=$(bw unlock --raw)
      if [ $? -ne 0 ]; then
        echo "Failed to log in to Bitwarden."
        return 1
      fi
      eval "BW_SESSION=$login_output"
      echo "export BW_SESSION=\"$login_output\"" > /tmp/bw.env
    fi
  fi
  
  print_ascii_time "Completed bw-auth"
}


function install-packages() {
  print_ascii_time "Starting install-packages"
  
  pushd /tmp
  sudo apt update -y
  sudo apt upgrade -y 
  sudo apt -y --fix-broken install
  # install required packages
  # bluetooth is for one plus buds 
  # rdp is for work laptop
  # restic is file backup
  sudo apt install -y \
  vim \
  git \
  curl \
  restic \
  snap \
  pipewire \
  python3-full \
  python3-pip \
  unzip \
  perl \
  freerdp2-x11 \
  libspa-0.2-bluetooth \
  qemu-kvm \
  libvirt-daemon-system \
  virt-manager

  curl -sS https://starship.rs/install.sh | sh

  rm $HOME/.bashrc
  curl -Lo /tmp/stow.tar.gz https://mirror.us-midwest-1.nexcess.net/gnu/stow/stow-latest.tar.gz
  tar -xzf /tmp/stow.tar.gz -C /tmp
  pushd stow-2.4.0
  ./configure
  sudo make install
  popd
  stow -V
  git clone git@gitlab.com:loganmancuso_personal/dotfiles.git $HOME/source/Personal/dotfiles
  pushd $HOME/source/Personal/dotfiles
  stow -vv --dotfiles --target=$HOME bash
  popd
  # install docker
  sudo apt install -y ca-certificates 
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker $USER

  curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

  # Install rust and Cargo
  sudo apt install -y libssl-dev libasound2-dev libdbus-1-dev
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  cargo install spotify_player

  # Install Packer and Vault
  wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt update -y && sudo apt install -y vault packer

  sudo snap install firefox 
  sudo snap install bw 
  sudo snap install nextcloud-desktop-client 
  sudo snap install --classic opentofu 
  sudo snap install --classic obsidian 
  sudo snap install --classic codium
  sudo snap install --classic --beta nvim 
  sudo snap connect nextcloud-desktop-client:mount-observe 
  sudo snap connect nextcloud-desktop-client:network-manager-observe 
  sudo snap connect nextcloud-desktop-client:password-manager-service
  popd
  
  print_ascii_time "Completed install-packages"
}

function install-frontend() {
  print_ascii_time "Starting install-frontend"

  git clone --depth=1 -b Ubuntu-24.04-LTS git@github.com:JaKooLit/Debian-Hyprland.git $HOME/.front-end.JaKooLit
  pushd $HOME/.front-end.JaKooLit
  chmod +x install.sh
  ./install.sh 
  popd
  # update monitor config with custom setup
  echo "Update Monitors"
  sed -i '/^monitor=,preferred,auto,1/c\
monitor = eDP-1, 3000x2000@60,  3640x0, 1.6\
monitor = DP-3,  2560x1080@144, 0x0,    1\
monitor = DP-4,  1920x1080@75,  2560x-250, 1, transform, 3\
bindl = , switch:off:Lid Switch,exec,hyprctl keyword monitor "eDP-1, enable"\
bindl = , switch:on:Lid Switch,exec,hyprctl keyword monitor "eDP-1, disable"' \
$HOME/.config/hypr/UserConfigs/Monitors.conf

  print_ascii_time "Completed install-frontend"
}


function main() {
  print_ascii_time "Starting main"
  
  echo "System Information:"
  echo "hostname: $(cat /etc/hostname)"
  echo "cpu: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
  echo "memory: $(free | grep Mem | awk '{print $3/$2 * 100.0"%"}')"
  echo "user: $(whoami)"
  echo "time: $(date)"
  if [ $# -lt 1 ]; then
    echo "Missing an argument Usage: $0 /path/to/usb-backup "
    return 1
  else
    path_usb=$1
    echo -e "Import SSH Keys"
    mkdir $HOME/.local/bin
    mkdir -p $HOME/.ssh
    mkdir -p $HOME/.gnupg
    cp --verbose -r $path_usb/os-init/secrets/ssh/* $HOME/.ssh
    cp --verbose -r $path_usb/os-init/secrets/gnupg/* $HOME/.gnupg
    eval $(ssh-agent -s)
    ssh-add $HOME/.ssh/id_rsa
    ssh-add $HOME/.ssh/id_ed25519
    echo -e "Finished Importing SSH Keys"
    sudo timedatectl set-timezone America/New_York
    install-packages
    install-frontend
  fi
  
  print_ascii_time "Completed main"
}

main "$@"
