#!/bin/bash

# SWMud Blight Scripts Installer for Linux/macOS
# This script installs the SWMud Blight Scripts to your Blightmud configuration directory

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory (where this script is located)
# Go up one level to the repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Function to find Blightmud config directory
find_blightmud_config() {
    local os=$(detect_os)
    local config_dir=""
    
    if [[ "$os" == "linux" ]] || [[ "$os" == "macos" ]]; then
        # Standard Linux/macOS config location
        config_dir="$HOME/.config/blightmud"
        
        # Check if directory exists
        if [[ -d "$config_dir" ]]; then
            echo "$config_dir"
            return 0
        fi
        
        # If it doesn't exist, we'll create it
        print_info "Blightmud config directory not found. Will create: $config_dir"
        echo "$config_dir"
        return 0
    fi
    
    return 1
}

# Function to check if Blightmud is installed
check_blightmud() {
    if command_exists blightmud; then
        print_success "Blightmud is installed"
        if blightmud --version >/dev/null 2>&1; then
            local version=$(blightmud --version 2>&1 | head -n1)
            print_info "Blightmud version: $version"
        fi
        return 0
    else
        print_warning "Blightmud command not found in PATH"
        print_info "This might be okay if Blightmud is installed but not in PATH"
        return 1
    fi
}

# Function to backup existing files
backup_existing() {
    local config_dir="$1"
    local backup_dir="${config_dir}.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [[ -d "$config_dir/swmud" ]] || [[ -f "$config_dir/000_connect.lua" ]]; then
        print_warning "Existing installation found. Creating backup..."
        mkdir -p "$backup_dir"
        
        if [[ -d "$config_dir/swmud" ]]; then
            cp -r "$config_dir/swmud" "$backup_dir/" 2>/dev/null || true
        fi
        
        if [[ -f "$config_dir/000_connect.lua" ]]; then
            cp "$config_dir/000_connect.lua" "$backup_dir/" 2>/dev/null || true
        fi
        
        print_success "Backup created at: $backup_dir"
    fi
}

# Function to copy files
copy_files() {
    local config_dir="$1"
    
    print_info "Installing files to: $config_dir"
    
    # Create config directory if it doesn't exist
    mkdir -p "$config_dir"
    
    # Copy swmud directory
    if [[ -d "$SCRIPT_DIR/swmud" ]]; then
        print_info "Copying swmud directory..."
        cp -r "$SCRIPT_DIR/swmud" "$config_dir/"
        print_success "swmud directory copied"
    else
        print_error "swmud directory not found in $SCRIPT_DIR"
        return 1
    fi
    
    # Copy 000_connect.lua
    if [[ -f "$SCRIPT_DIR/000_connect.lua" ]]; then
        print_info "Copying 000_connect.lua..."
        cp "$SCRIPT_DIR/000_connect.lua" "$config_dir/"
        print_success "000_connect.lua copied"
    else
        print_error "000_connect.lua not found in $SCRIPT_DIR"
        return 1
    fi
    
    # Copy settings.ron if it exists (optional)
    if [[ -f "$SCRIPT_DIR/settings.ron" ]]; then
        if [[ ! -f "$config_dir/settings.ron" ]]; then
            print_info "Copying settings.ron..."
            cp "$SCRIPT_DIR/settings.ron" "$config_dir/"
            print_success "settings.ron copied"
        else
            print_info "settings.ron already exists, skipping (to preserve your settings)"
        fi
    fi
    
    # Create private directory if it doesn't exist
    if [[ ! -d "$config_dir/private" ]]; then
        print_info "Creating private directory..."
        mkdir -p "$config_dir/private"
        print_success "private directory created"
    fi
    
    return 0
}

# Function to verify installation
verify_installation() {
    local config_dir="$1"
    local errors=0
    
    print_info "Verifying installation..."
    
    # Check for required files
    if [[ ! -f "$config_dir/000_connect.lua" ]]; then
        print_error "000_connect.lua not found"
        errors=$((errors + 1))
    fi
    
    if [[ ! -d "$config_dir/swmud" ]]; then
        print_error "swmud directory not found"
        errors=$((errors + 1))
    fi
    
    # Check for required subdirectories
    local required_dirs=("core" "utils" "ui" "commands" "parsers" "services" "models" "data")
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$config_dir/swmud/$dir" ]]; then
            print_error "swmud/$dir directory not found"
            errors=$((errors + 1))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        print_success "Installation verified successfully!"
        return 0
    else
        print_error "Installation verification failed with $errors error(s)"
        return 1
    fi
}

# Main installation function
main() {
    print_info "SWMud Blight Scripts Installer"
    print_info "=============================="
    echo ""
    
    # Detect OS
    local os=$(detect_os)
    if [[ "$os" == "unknown" ]]; then
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    print_info "Detected OS: $os"
    echo ""
    
    # Check for Blightmud (non-fatal)
    check_blightmud || print_warning "Could not verify Blightmud installation. Continuing anyway..."
    echo ""
    
    # Find config directory
    local config_dir=$(find_blightmud_config)
    if [[ -z "$config_dir" ]]; then
        print_error "Could not determine Blightmud config directory"
        exit 1
    fi
    print_info "Blightmud config directory: $config_dir"
    echo ""
    
    # Backup existing installation
    backup_existing "$config_dir"
    echo ""
    
    # Copy files
    if ! copy_files "$config_dir"; then
        print_error "Failed to copy files"
        exit 1
    fi
    echo ""
    
    # Verify installation
    if ! verify_installation "$config_dir"; then
        print_error "Installation verification failed"
        exit 1
    fi
    echo ""
    
    # Success message
    print_success "Installation completed successfully!"
    echo ""
    print_info "Next steps:"
    echo "  1. Launch Blightmud: blightmud"
    echo "  2. The scripts will automatically load when you connect to SWMud"
    echo "  3. Use '/reload' in-game to reload scripts after making changes"
    echo ""
    print_info "Config directory: $config_dir"
    print_info "For character-specific scripts, create: $config_dir/private/020_character.lua"
    echo ""
}

# Run main function
main

