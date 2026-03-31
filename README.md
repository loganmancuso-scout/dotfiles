# Dotfiles

Personal system configuration files managed with GNU Stow.

## Overview

This repository contains configuration files for various tools and applications organized as stow packages. Each directory represents a package that can be independently installed or removed.

## Included Configurations

- `aliases` - Shell aliases
- `aws` - AWS CLI configuration
- `bash` - Bash shell configuration
- `colima` - Colima container runtime templates
- `docker` - Docker configuration
- `ghostty` - Ghostty terminal emulator
- `git` - Git configuration
- `karabiner` - Karabiner Elements keyboard remapping (Linux-style shortcuts)
- `nvim` - Neovim configuration
- `powershell` - PowerShell configuration
- `ssh` - SSH configuration
- `starship` - Starship prompt
- `tmux` - tmux terminal multiplexer
- `vscode` - Visual Studio Code settings
- `zed` - Zed editor configuration (see [zed/README.md](zed/README.md) for setup)
- `zsh` - Zsh shell configuration

## Prerequisites

- [GNU Stow](https://www.gnu.org/software/stow/) - Required for symlinking configuration files

Install on macOS:
```bash
brew install stow
```

Install on Linux:
```bash
# Debian/Ubuntu
sudo apt install stow

# Arch
sudo pacman -S stow

# Fedora
sudo dnf install stow
```

## Installation

Clone this repository to your preferred location:

```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### Stow All Packages

To install all configuration files:

```bash
./stow-dotfiles.sh --stow
```

This will:
- Automatically discover all packages in the repository
- Symlink each package's configuration files to your home directory
- Adopt any existing files (merge them into the repository)

### Stow Individual Packages

To install specific packages manually:

```bash
stow -v --dotfiles --adopt --target="$HOME" <package-name>
```

Example:
```bash
stow -v --dotfiles --adopt --target="$HOME" nvim
```

## Uninstallation

### Unstow All Packages

To remove all symlinks:

```bash
./stow-dotfiles.sh --unstow
```

### Unstow Individual Packages

To remove specific packages:

```bash
stow -D -vv <package-name>
```

## How It Works

GNU Stow creates symlinks from this repository to your home directory. Files and directories prefixed with `dot-` are automatically renamed with a `.` prefix when stowed (e.g., `dot-bashrc` becomes `.bashrc`).

The directory structure in each package mirrors the target structure in your home directory. For example:
- `bash/dot-bashrc` → `~/.bashrc`
- `nvim/dot-config/nvim/init.lua` → `~/.config/nvim/init.lua`

## Customization

Feel free to fork this repository and customize it for your own use. You can:
- Add new packages by creating directories with your config files
- Modify existing configurations to match your preferences
- Remove packages you don't need

## Notes

- The `--adopt` flag in the stow script will merge existing files into the repository
- Back up your existing configuration files before stowing if you want to preserve them separately
- The `.gitignore` is configured to only track specific configuration files while ignoring generated content

## License

Feel free to use and modify as needed.
