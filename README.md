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
- `fzf` - Fuzzy finder configuration
- `ghostty` - Ghostty terminal emulator
- `git` - Git configuration
- `nvim` - Neovim configuration
- `powershell` - PowerShell configuration
- `ssh` - SSH configuration
- `starship` - Starship prompt
- `tmux` - tmux terminal multiplexer (with Catppuccin theme, vim integration, and custom scripts)
- `vscode` - Visual Studio Code settings
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

## Tmux Configuration

The tmux configuration includes several enhanced features:

### Features
- **Prefix Key**: `Ctrl+Space` (instead of default `Ctrl+b`)
- **Catppuccin Theme**: Beautiful Mocha-flavored theme with rounded window status
- **Vim Integration**: Seamless navigation between tmux panes and Neovim splits using `Ctrl+h/j/k/l`
- **Fuzzy Finder Scripts**: Project sessionizer and session switcher using fzf
- **Session Persistence**: Auto-save and restore sessions with tmux-resurrect and tmux-continuum
- **Status Bar**: Shows username, directory, session name, CPU usage, and battery percentage

### Key Bindings
- `Ctrl+Space` - Prefix key
- `Prefix + r` - Reload configuration
- `Prefix + |` - Split window vertically
- `Prefix + -` - Split window horizontally
- `Prefix + f` - Fuzzy find and switch to project directories
- `Prefix + Ctrl+j` - Session switcher popup
- `Ctrl+h/j/k/l` - Navigate between panes and vim splits
- Copy mode: `v` to select, `y` to yank to clipboard

### First Time Setup
After stowing, install tmux plugins:
1. Start tmux: `tmux`
2. Press `Ctrl+Space` then `Shift+I` to install all plugins

### Scripts
- `~/.config/tmux/scripts/tmux-sessionizer.sh` - Fuzzy find project directories
- `~/.config/tmux/scripts/session-fzf.sh` - Interactive session switcher

### Dependencies
- [fzf](https://github.com/junegunn/fzf) - Required for sessionizer and popup features
- [TPM](https://github.com/tmux-plugins/tpm) - Tmux Plugin Manager (auto-installed)

## Neovim Configuration

This repository includes a LazyVim-based Neovim configuration with tmux integration.

### Tmux Integration
The `vim-tmux-navigator` plugin enables seamless navigation between tmux panes and Neovim splits using `Ctrl+h/j/k/l`. This is automatically configured and will install on first Neovim startup after stowing.

## Notes

- The `--adopt` flag in the stow script will merge existing files into the repository
- Back up your existing configuration files before stowing if you want to preserve them separately
- The `.gitignore` is configured to only track specific configuration files while ignoring generated content

## License

Feel free to use and modify as needed.
