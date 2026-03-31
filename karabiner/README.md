# Karabiner Elements Configuration

This directory contains Karabiner Elements configuration for Linux-style keyboard shortcuts on macOS.

## Overview

This configuration remaps keyboard shortcuts to match Linux/Windows behavior, making it easier to switch between macOS and Linux systems. All shortcuts use `Control` instead of `Command` to match Linux conventions.

## Installation

### 1. Install Karabiner Elements

```bash
brew install --cask karabiner-elements
```

### 2. Install the configuration

```bash
# From the dotfiles repo root
stow -v --dotfiles --adopt --target="$HOME" karabiner
```

### 3. Restart Karabiner Elements

The configuration should be automatically loaded. If not, restart Karabiner Elements from the menu bar or:

```bash
# The config should auto-reload, but you can verify the profile is active:
karabiner_cli --show-current-profile-name
# Should output: Linux-style
```

## Keyboard Shortcuts

### Copy/Paste/Cut (System-wide)
- `Ctrl+Shift+C` → Copy (maps to Cmd+C)
- `Ctrl+Shift+V` → Paste (maps to Cmd+V)
- `Ctrl+Shift+X` → Cut (maps to Cmd+X)

### Text Navigation (System-wide)
- `Ctrl+A` → Move to beginning of line (maps to Cmd+Left)
- `Ctrl+E` → Move to end of line (maps to Cmd+Right)
- `Ctrl+Left/Right` → Move by word (maps to Option+Left/Right)

### Text Deletion (System-wide)
- `Ctrl+K` → Delete from cursor to end of line
- `Ctrl+U` → Delete from cursor to beginning of line
- `Ctrl+W` → Delete word backward (maps to Option+Backspace)

### Tab Management (System-wide)
- `Ctrl+T` → New tab (maps to Cmd+T)
- `Ctrl+W` → Close tab/window (maps to Cmd+W)
- `Ctrl+Shift+T` → Reopen closed tab (maps to Cmd+Shift+T)
- `Ctrl+Tab` → Next tab (maps to Cmd+Option+Right)
- `Ctrl+Shift+Tab` → Previous tab (maps to Cmd+Option+Left)

### Window Management (System-wide)
- `Ctrl+Q` → Quit application (maps to Cmd+Q)
- `Ctrl+N` → New window (maps to Cmd+N)
- `Ctrl+Shift+N` → New private/incognito window (maps to Cmd+Shift+N)

### Find/Search (System-wide)
- `Ctrl+F` → Find (maps to Cmd+F)
- `Ctrl+H` → Find and replace (maps to Cmd+Option+F)

### File Operations (System-wide)
- `Ctrl+S` → Save (maps to Cmd+S)
- `Ctrl+O` → Open (maps to Cmd+O)
- `Ctrl+P` → Print (maps to Cmd+P)

### Undo/Redo (System-wide)
- `Ctrl+Z` → Undo (maps to Cmd+Z)
- `Ctrl+Shift+Z` → Redo (maps to Cmd+Shift+Z)
- `Ctrl+Y` → Redo (alternative, maps to Cmd+Shift+Z)

## Terminal-Specific Notes

Some terminal emulators (like iTerm2, Ghostty) may already have native support for `Ctrl+Shift+C/V`. If you experience conflicts:

1. Check your terminal's keyboard settings
2. Disable the native shortcuts in your terminal
3. Let Karabiner handle the remapping

For terminals that natively support these shortcuts, you may want to create an exception in Karabiner by modifying the configuration.

## Customization

To add or modify shortcuts:

1. Edit `karabiner/dot-config/karabiner/karabiner.json`
2. The configuration will automatically reload
3. Test your changes
4. Commit to your dotfiles

Alternatively, you can use the Karabiner Elements UI:
1. Open Karabiner Elements from the menu bar
2. Go to "Complex Modifications"
3. Edit rules through the UI
4. Changes will be saved to the config file

## Troubleshooting

### Configuration not loading
```bash
# Check if config exists
ls -la ~/.config/karabiner/karabiner.json

# Verify profile
karabiner_cli --show-current-profile-name

# List all profiles
karabiner_cli --list-profile-names
```

### Shortcuts not working
1. Check that Karabiner Elements has accessibility permissions:
   - System Settings → Privacy & Security → Accessibility
   - Ensure Karabiner Elements is enabled
2. Restart Karabiner Elements
3. Check for conflicting shortcuts in System Settings

### Conflicts with other apps
Some apps may override these shortcuts. You can create app-specific rules by modifying the configuration to exclude certain applications.

## References

- [Karabiner Elements Documentation](https://karabiner-elements.pqrs.org/)
- [Complex Modifications](https://karabiner-elements.pqrs.org/docs/manual/configuration/configure-complex-modifications/)
- [Karabiner JSON Reference](https://karabiner-elements.pqrs.org/docs/json/)
