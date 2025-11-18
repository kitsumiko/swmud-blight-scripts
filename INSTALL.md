# SWMud Blight Scripts Installation Guide

This guide will help you install the SWMud Blight Scripts on Windows and Linux systems.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Installation (Automated)](#quick-installation-automated)
- [Manual Installation](#manual-installation)
- [Windows Installation](#windows-installation)
- [Linux Installation](#linux-installation)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before installing the SWMud Blight Scripts, you need to have Blightmud installed on your system.

### Installing Blightmud

#### Linux

**Option 1: Using Package Manager (Recommended)**

- **Arch Linux (AUR):**
  ```bash
  yay -S blightmud
  # or
  paru -S blightmud
  ```

- **Other distributions:** Check if Blightmud is available in your distribution's repositories.

**Option 2: Build from Source**

1. Install Rust (if not already installed):
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   source $HOME/.cargo/env
   ```

2. Clone and build Blightmud:
   ```bash
   git clone https://github.com/Blightmud/Blightmud.git
   cd Blightmud
   cargo build --release
   ```

3. Install Blightmud:
   ```bash
   cargo install --path .
   ```

#### Windows

**Option 1: Using WSL2 (Recommended)**

1. Install WSL2 and a Linux distribution (Ubuntu recommended)
2. Follow the Linux installation instructions above within WSL2

**Option 2: Build from Source (Requires Rust)**

1. Install Rust from https://rustup.rs/
2. Install Git for Windows from https://git-scm.com/download/win
3. Open PowerShell or Command Prompt
4. Clone and build:
   ```powershell
   git clone https://github.com/Blightmud/Blightmud.git
   cd Blightmud
   cargo build --release
   cargo install --path .
   ```

**Option 3: Pre-built Binaries**

Check the [Blightmud releases page](https://github.com/Blightmud/Blightmud/releases) for Windows binaries if available.

### Verify Blightmud Installation

After installing Blightmud, verify it's working:

```bash
blightmud --version
```

If this command works, you're ready to proceed with installing the scripts.

## Quick Installation (Automated)

The easiest way to install the scripts is using the provided installer scripts.

### Linux/macOS

1. Clone or download this repository:
   ```bash
   git clone https://github.com/mikotaichou/swmud-blight-scripts.git
   cd swmud-blight-scripts
   ```

2. Make the installer executable and run it:
   ```bash
   chmod +x installers/install.sh
   ./installers/install.sh
   ```

The script will:
- Detect your Blightmud installation
- Find your Blightmud config directory
- Copy all necessary files to the correct location
- Verify the installation

### Windows

**Using PowerShell (Recommended):**

1. Clone or download this repository
2. Open PowerShell in the repository directory
3. Run:
   ```powershell
   .\installers\install.ps1
   ```

**Using Command Prompt:**

1. Clone or download this repository
2. Open Command Prompt in the repository directory
3. Run:
   ```cmd
   installers\install.bat
   ```

## Manual Installation

If you prefer to install manually or the automated scripts don't work, follow these steps:

### Step 1: Locate Blightmud Config Directory

**Linux/macOS:**
- Default location: `~/.config/blightmud/`
- If it doesn't exist, create it:
  ```bash
  mkdir -p ~/.config/blightmud
  ```

**Windows:**
- Default location: `%APPDATA%\blightmud\` or `%LOCALAPPDATA%\blightmud\`
- If it doesn't exist, create it:
  ```cmd
  mkdir %APPDATA%\blightmud
  ```

### Step 2: Copy Script Files

**Linux/macOS:**
```bash
# From the repository directory
cp -r swmud ~/.config/blightmud/
cp 000_connect.lua ~/.config/blightmud/
cp settings.ron ~/.config/blightmud/  # Optional
```

**Windows (Command Prompt):**
```cmd
xcopy /E /I swmud %APPDATA%\blightmud\swmud
copy 000_connect.lua %APPDATA%\blightmud\
copy settings.ron %APPDATA%\blightmud\
```

**Windows (PowerShell):**
```powershell
Copy-Item -Recurse swmud $env:APPDATA\blightmud\
Copy-Item 000_connect.lua $env:APPDATA\blightmud\
Copy-Item settings.ron $env:APPDATA\blightmud\
```

### Step 3: Create Private Directory (Optional)

If you want to use character-specific scripts:

**Linux/macOS:**
```bash
mkdir -p ~/.config/blightmud/private
```

**Windows:**
```cmd
mkdir %APPDATA%\blightmud\private
```

## Windows Installation

### Detailed Windows Steps

1. **Install Blightmud** (see Prerequisites above)

2. **Find Blightmud Config Directory:**
   - Open PowerShell or Command Prompt
   - Run Blightmud once to create the config directory
   - The config directory is typically at:
     - `%APPDATA%\blightmud\` (User AppData)
     - `%LOCALAPPDATA%\blightmud\` (Local AppData)

3. **Install Scripts:**
   - Use the automated installer (`installers/install.ps1` or `installers/install.bat`)
   - Or follow the manual installation steps above

4. **Verify Installation:**
   - Check that `000_connect.lua` exists in the config directory
   - Check that the `swmud` directory exists in the config directory

## Linux Installation

### Detailed Linux Steps

1. **Install Blightmud** (see Prerequisites above)

2. **Find Blightmud Config Directory:**
   - The config directory is typically at `~/.config/blightmud/`
   - If it doesn't exist, run Blightmud once to create it, or create it manually:
     ```bash
     mkdir -p ~/.config/blightmud
     ```

3. **Install Scripts:**
   - Use the automated installer (`installers/install.sh`)
   - Or follow the manual installation steps above

4. **Verify Installation:**
   - Check that `000_connect.lua` exists in `~/.config/blightmud/`
   - Check that the `swmud` directory exists in `~/.config/blightmud/`

## Verification

After installation, verify everything is set up correctly:

1. **Check File Structure:**

   **Linux/macOS:**
   ```bash
   ls -la ~/.config/blightmud/
   ls -la ~/.config/blightmud/swmud/
   ```

   **Windows:**
   ```cmd
   dir %APPDATA%\blightmud
   dir %APPDATA%\blightmud\swmud
   ```

2. **Expected Files:**
   - `000_connect.lua` in the config directory
   - `swmud/` directory with subdirectories:
     - `core/`
     - `utils/`
     - `ui/`
     - `commands/`
     - `parsers/`
     - `services/`
     - `models/`
     - `data/`

3. **Test Installation:**
   - Launch Blightmud:
     ```bash
     blightmud
     ```
   - The scripts should automatically load when you connect to SWMud
   - You should see version information and status displays

## Troubleshooting

### Scripts Not Loading

**Problem:** Scripts don't appear to be loading when you start Blightmud.

**Solutions:**
1. Verify `000_connect.lua` is in the correct location:
   - Linux: `~/.config/blightmud/000_connect.lua`
   - Windows: `%APPDATA%\blightmud\000_connect.lua`

2. Check that the `swmud` directory exists and contains all subdirectories

3. Check for Lua syntax errors in the debug logs:
   - Linux: `~/.local/share/blightmud/logs/syslogs/swmud_debug.log`
   - Windows: Check Blightmud's log directory

4. Ensure Blightmud has read permissions for the config directory

### Blightmud Not Found

**Problem:** Installer script says Blightmud is not installed.

**Solutions:**
1. Verify Blightmud is installed:
   ```bash
   blightmud --version
   ```

2. If Blightmud is installed but not in PATH:
   - Add Blightmud to your system PATH
   - Or manually specify the config directory during installation

3. Run Blightmud at least once to create the config directory

### Permission Errors

**Problem:** Permission denied errors during installation.

**Solutions:**
1. **Linux/macOS:**
   - Ensure you have write permissions to `~/.config/blightmud/`
   - If needed, create the directory first:
     ```bash
     mkdir -p ~/.config/blightmud
     chmod 755 ~/.config/blightmud
     ```

2. **Windows:**
   - Run PowerShell or Command Prompt as Administrator if needed
   - Ensure you have write permissions to `%APPDATA%\blightmud\`

### Wrong Config Directory

**Problem:** Scripts are installed but Blightmud isn't finding them.

**Solutions:**
1. Check where Blightmud is looking for config files:
   - Run Blightmud with verbose logging if available
   - Check Blightmud documentation for config directory location

2. Verify the config directory path:
   - Linux: Usually `~/.config/blightmud/`
   - Windows: Usually `%APPDATA%\blightmud\` or `%LOCALAPPDATA%\blightmud\`

3. If using a custom Blightmud installation, you may need to set environment variables or use Blightmud's config options

### Module Not Found Errors

**Problem:** Errors about modules not being found.

**Solutions:**
1. Verify the `swmud` directory structure is complete
2. Check that all subdirectories (`core/`, `utils/`, etc.) exist
3. Ensure file permissions allow Blightmud to read the files

## Next Steps

After successful installation:

1. **Launch Blightmud:**
   ```bash
   blightmud
   ```

2. **Connect to SWMud:**
   - The scripts will automatically connect to `swmud.org:7777`
   - Or manually connect using: `/connect swmud.org 7777`

3. **Customize (Optional):**
   - Create `private/020_character.lua` for character-specific customizations
   - Modify settings in `swmud/core/config.lua` if needed

4. **Use Commands:**
   - `/reload` - Reload all scripts
   - `/reconnect` - Reconnect to SWMud
   - `score` - Parse character information
   - See README.md for more commands

## Support

For issues, questions, or contributions:
- Open an issue on GitHub: https://github.com/mikotaichou/swmud-blight-scripts
- Check the main README.md for usage information
- Review CONTRIBUTING.md for development guidelines

## License

See LICENSE file for details.

