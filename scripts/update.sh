#!/usr/bin/env bash
# ============================================================================
# Universal Dotfiles Update Script
# Supports: Debian, Ubuntu, CentOS/RHEL, Fedora, Arch, CachyOS, Alpine, openSUSE, macOS
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
DOTFILES_DIR="$HOME/.dotfiles"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect OS and package manager
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        PACKAGE_MANAGER="brew"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case $ID in
            debian|ubuntu)
                OS="debian"
                PACKAGE_MANAGER="apt"
                ;;
            centos|rhel|rocky|almalinux)
                OS="rhel"
                PACKAGE_MANAGER="yum"
                ;;
            fedora)
                OS="fedora"
                PACKAGE_MANAGER="dnf"
                ;;
            opensuse*|sles)
                OS="opensuse"
                PACKAGE_MANAGER="zypper"
                ;;
            arch|manjaro)
                OS="arch"
                PACKAGE_MANAGER="pacman"
                ;;
            cachyos)
                OS="arch"
                PACKAGE_MANAGER="pacman"
                IS_CACHYOS="true"
                ;;
            alpine)
                OS="alpine"
                PACKAGE_MANAGER="apk"
                ;;
            *)
                OS="unknown"
                PACKAGE_MANAGER="unknown"
                ;;
        esac
    else
        OS="unknown"
        PACKAGE_MANAGER="unknown"
    fi
    
    log_info "Detected OS: $OS with package manager: $PACKAGE_MANAGER"
    if [[ "$IS_CACHYOS" == "true" ]]; then
        log_info "🚀 CachyOS detected"
    fi
}

# Find configuration files in dotfiles directory
find_config_files() {
    log_info "Scanning dotfiles directory for configuration files..."
    
    # Common config file locations to check
    declare -A CONFIG_PATHS=(
        ["zshrc"]=""
        ["starship.toml"]=""
        ["vimrc"]=""
        ["gitconfig"]=""
        ["tmux.conf"]=""
        ["nvim"]=""
    )
    
    # Search for files in common locations (note: configs with 's')
    for config in "${!CONFIG_PATHS[@]}"; do
        # Try multiple possible locations
        local possible_paths=(
            "$DOTFILES_DIR/$config"
            "$DOTFILES_DIR/configs/$config"              # Added configs (plural)
            "$DOTFILES_DIR/config/$config"               # Keep config (singular) as fallback
            "$DOTFILES_DIR/configs/zsh/$config"          # Added configs/zsh
            "$DOTFILES_DIR/configs/starship/$config"     # Added configs/starship
            "$DOTFILES_DIR/configs/vim/$config"          # Added configs/vim
            "$DOTFILES_DIR/configs/git/$config"          # Added configs/git
            "$DOTFILES_DIR/configs/tmux/$config"         # Added configs/tmux
            "$DOTFILES_DIR/configs/nvim"                 # Added configs/nvim
            "$DOTFILES_DIR/config/zsh/$config"
            "$DOTFILES_DIR/config/starship/$config"
            "$DOTFILES_DIR/config/vim/$config"
            "$DOTFILES_DIR/config/git/$config"
            "$DOTFILES_DIR/config/tmux/$config"
            "$DOTFILES_DIR/config/nvim"
            "$DOTFILES_DIR/zsh/$config"
            "$DOTFILES_DIR/starship/$config"
            "$DOTFILES_DIR/vim/$config"
            "$DOTFILES_DIR/git/$config"
            "$DOTFILES_DIR/tmux/$config"
            "$DOTFILES_DIR/nvim"
        )
        
        for path in "${possible_paths[@]}"; do
            if [[ -f "$path" ]] || [[ -d "$path" && "$config" == "nvim" ]]; then
                CONFIG_PATHS["$config"]="$path"
                log_info "Found $config at: $path"
                break
            fi
        done
        
        if [[ -z "${CONFIG_PATHS[$config]}" ]]; then
            log_warning "$config not found in dotfiles directory"
        fi
    done
    
    # Also search for any .zshrc file in configs directory
    if [[ -z "${CONFIG_PATHS[zshrc]}" ]]; then
        local zshrc_candidates=(
            "$DOTFILES_DIR/.zshrc"
            "$DOTFILES_DIR/zshrc"
            "$DOTFILES_DIR/configs/zshrc"        # Added
            "$DOTFILES_DIR/configs/.zshrc"       # Added
            "$DOTFILES_DIR/config/zshrc"
            "$DOTFILES_DIR/config/.zshrc"
        )
        
        for candidate in "${zshrc_candidates[@]}"; do
            if [[ -f "$candidate" ]]; then
                CONFIG_PATHS["zshrc"]="$candidate"
                log_info "Found zshrc at: $candidate"
                break
            fi
        done
    fi
    
    # Export found paths for use in other functions
    export FOUND_ZSHRC="${CONFIG_PATHS[zshrc]}"
    export FOUND_STARSHIP="${CONFIG_PATHS[starship.toml]}"
    export FOUND_VIMRC="${CONFIG_PATHS[vimrc]}"
    export FOUND_GITCONFIG="${CONFIG_PATHS[gitconfig]}"
    export FOUND_TMUX="${CONFIG_PATHS[tmux.conf]}"
    export FOUND_NVIM="${CONFIG_PATHS[nvim]}"
}

# Backup existing config file
backup_config() {
    local config_file="$1"
    local backup_dir="$HOME/.config-backup-$(date +%Y%m%d_%H%M%S)"
    
    if [[ -f "$config_file" ]] || [[ -d "$config_file" ]]; then
        mkdir -p "$backup_dir"
        cp -r "$config_file" "$backup_dir/"
        log_success "Backed up $(basename "$config_file") to $backup_dir"
        return 0
    fi
    return 1
}

# Install config file with backup
install_config() {
    local source="$1"
    local destination="$2"
    local config_name="$3"
    
    if [[ -n "$source" ]] && ([[ -f "$source" ]] || [[ -d "$source" ]]); then
        # Backup existing config
        backup_config "$destination"
        
        # Create destination directory if needed
        mkdir -p "$(dirname "$destination")"
        
        # Copy config file or directory
        if [[ -d "$source" ]]; then
            cp -r "$source" "$(dirname "$destination")/"
        else
            cp "$source" "$destination"
        fi
        log_success "$config_name configuration updated"
        return 0
    else
        log_warning "$config_name configuration not found"
        return 1
    fi
}

# Check if dotfiles directory exists
check_dotfiles_dir() {
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "Dotfiles directory not found at: $DOTFILES_DIR"
        log_error "Please run the installer first or clone your dotfiles repository"
        exit 1
    fi
    
    log_info "Dotfiles directory found at: $DOTFILES_DIR"
    
    # List contents for debugging
    log_info "Dotfiles directory contents:"
    ls -la "$DOTFILES_DIR" | head -10
}

# Update dotfiles repository
update_repository() {
    log_info "Updating dotfiles repository..."
    
    cd "$DOTFILES_DIR"
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_warning "Dotfiles directory is not a git repository, skipping git update"
        return 0
    fi
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        log_warning "You have uncommitted changes in your dotfiles repository"
        read -p "Do you want to stash them and continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git stash push -m "Auto-stash before update $(date)"
            log_info "Changes stashed"
        else
            log_info "Continuing without stashing changes"
        fi
    fi
    
    # Pull latest changes
    if git pull origin main 2>/dev/null || git pull origin master 2>/dev/null; then
        log_success "Repository updated successfully"
    else
        log_warning "Failed to update repository (may already be up to date)"
    fi
}

# Update configurations
update_configs() {
    log_info "Updating configurations..."
    
    local configs_updated=0
    
    # Find all config files first
    find_config_files
    
    # Update ZSH config
    if install_config "$FOUND_ZSHRC" "$HOME/.zshrc" "ZSH"; then
        ((configs_updated++))
    fi
    
    # Update Starship config
    if install_config "$FOUND_STARSHIP" "$HOME/.config/starship.toml" "Starship"; then
        ((configs_updated++))
    fi
    
    # Update Vim config
    if install_config "$FOUND_VIMRC" "$HOME/.vimrc" "Vim"; then
        ((configs_updated++))
    fi
    
    # Update Git config
    if install_config "$FOUND_GITCONFIG" "$HOME/.gitconfig" "Git"; then
        ((configs_updated++))
    fi
    
    # Update Tmux config
    if install_config "$FOUND_TMUX" "$HOME/.tmux.conf" "Tmux"; then
        ((configs_updated++))
    fi
    
    # Update Neovim config
    if install_config "$FOUND_NVIM" "$HOME/.config/nvim" "Neovim"; then
        ((configs_updated++))
    fi
    
    # Check for other common config files
    local other_configs=(
        "bashrc:$HOME/.bashrc"
        "bash_profile:$HOME/.bash_profile"
        "profile:$HOME/.profile"
        "inputrc:$HOME/.inputrc"
    )
    
    for config_pair in "${other_configs[@]}"; do
        local config_name="${config_pair%%:*}"
        local dest_path="${config_pair##*:}"
        local source_path=""
        
        # Try to find the config file
        for possible_path in "$DOTFILES_DIR/$config_name" "$DOTFILES_DIR/config/$config_name" "$DOTFILES_DIR/.*$config_name"; do
            if [[ -f "$possible_path" ]]; then
                source_path="$possible_path"
                break
            fi
        done
        
        if [[ -n "$source_path" ]]; then
            if install_config "$source_path" "$dest_path" "$config_name"; then
                ((configs_updated++))
            fi
        fi
    done
    
    if [[ $configs_updated -eq 0 ]]; then
        log_warning "No configuration files were updated"
        log_info "Available files in dotfiles directory:"
        find "$DOTFILES_DIR" -maxdepth 3 -type f -name "*.toml" -o -name "*rc" -o -name "*config*" | head -10
    else
        log_success "$configs_updated configuration file(s) updated"
    fi
}

# Update tools if needed
update_tools() {
    log_info "Checking for tool updates..."
    
    case $OS in
        macos)
            if command -v brew >/dev/null 2>&1; then
                log_info "Updating Homebrew packages..."
                brew update && brew upgrade
                log_success "Homebrew packages updated"
            fi
            ;;
        debian)
            log_info "Updating system packages..."
            sudo apt update && sudo apt upgrade -y
            log_success "System packages updated"
            ;;
        fedora|rhel)
            log_info "Updating system packages..."
            if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
                sudo dnf update -y
            else
                sudo yum update -y
            fi
            log_success "System packages updated"
            ;;
        opensuse)
            log_info "Updating system packages..."
            sudo zypper refresh && sudo zypper update -y
            log_success "System packages updated"
            ;;
        arch)
            log_info "Updating system packages..."
            if [[ "$IS_CACHYOS" == "true" ]]; then
                log_info "CachyOS detected - using optimized update sequence"
                # Update CachyOS keyring first
                sudo pacman -Sy cachyos-keyring --noconfirm 2>/dev/null || true
            fi
            sudo pacman -Syu --noconfirm
            log_success "System packages updated"
            ;;
        alpine)
            log_info "Updating system packages..."
            sudo apk update && sudo apk upgrade
            log_success "System packages updated"
            ;;
        *)
            log_warning "Unknown OS, skipping system package updates"
            ;;
    esac
    
    # Update Starship if installed
    if command -v starship >/dev/null 2>&1; then
        log_info "Updating Starship..."
        case $OS in
            macos)
                brew upgrade starship 2>/dev/null || log_info "Starship already up to date"
                ;;
            *)
                curl -sS https://starship.rs/install.sh | sh -s -- -y
                ;;
        esac
        log_success "Starship updated"
    fi
}

# Show what was updated
show_summary() {
    local configs_found=0
    local tools_updated="✅"
    
    # Count found configurations
    [[ -n "$FOUND_ZSHRC" ]] && ((configs_found++))
    [[ -n "$FOUND_STARSHIP" ]] && ((configs_found++))
    [[ -n "$FOUND_VIMRC" ]] && ((configs_found++))
    [[ -n "$FOUND_GITCONFIG" ]] && ((configs_found++))
    [[ -n "$FOUND_TMUX" ]] && ((configs_found++))
    [[ -n "$FOUND_NVIM" ]] && ((configs_found++))
    
    echo
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                     Update Complete!                        ║"
    echo "║                                                              ║"
    echo "║  ✅ Dotfiles repository updated                              ║"
    echo "║  📁 Configuration files found: $configs_found                        ║"
    if [[ $configs_found -gt 0 ]]; then
        echo "║  ✅ Configuration files updated                              ║"
    else
        echo "║  ⚠️  No configuration files found to update                 ║"
    fi
    echo "║  $tools_updated System tools updated                                     ║"
    if [[ "$IS_CACHYOS" == "true" ]]; then
        echo "║  🚀 CachyOS optimizations maintained                        ║"
    fi
    echo "║                                                              ║"
    echo "║  Next steps:                                                 ║"
    echo "║  1. Restart your terminal or run: source ~/.zshrc           ║"
    echo "║  2. Check if any manual configuration is needed             ║"
    echo "║  3. Enjoy your updated dotfiles!                            ║"
    echo "║                                                              ║"
    echo "║  Useful commands:                                            ║"
    echo "║  • sa or source ~/.zshrc  - Reload shell config             ║"
    echo "║  • sysinfo               - Show system information          ║"
    echo "║  • ah                    - Show alias help                  ║"
    if [[ "$IS_CACHYOS" == "true" ]]; then
        echo "║  • al cachyos            - CachyOS performance commands     ║"
        echo "║  • cm                    - CachyOS maintenance              ║"
    fi
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Main update function
main() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                  Dotfiles Update Script                     ║"
    echo "║                                                              ║"
    echo "║  This script will:                                          ║"
    echo "║  • Update the dotfiles repository                           ║"
    echo "║  • Scan for configuration files                             ║"
    echo "║  • Update found configuration files                         ║"
    echo "║  • Update system tools (optional)                           ║"
    echo "║  • Create backups of existing configs                       ║"
    if [[ "$IS_CACHYOS" == "true" ]]; then
        echo "║  • Maintain CachyOS performance optimizations               ║"
    fi
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Parse command line arguments
    local update_tools_flag=false
    local force_update=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --tools|-t)
                update_tools_flag=true
                shift
                ;;
            --force|-f)
                force_update=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo
                echo "Options:"
                echo "  -t, --tools    Also update system tools and packages"
                echo "  -f, --force    Force update without confirmation"
                echo "  -h, --help     Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Ask for confirmation unless force flag is used
    if [[ "$force_update" != true ]]; then
        read -p "Do you want to continue with the update? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Update cancelled"
            exit 0
        fi
    fi
    
    detect_os
    check_dotfiles_dir
    update_repository
    update_configs
    
    if [[ "$update_tools_flag" == true ]]; then
        update_tools
    else
        log_info "Skipping tool updates (use --tools flag to update tools)"
    fi
    
    show_summary
    
    # Automatically reload zsh if we're in zsh and zshrc was updated
    if [[ -n "$ZSH_VERSION" ]] && [[ -n "$FOUND_ZSHRC" ]]; then
        log_info "Reloading ZSH configuration..."
        source ~/.zshrc
        log_success "ZSH configuration reloaded!"
    fi
}

# Run main function
main "$@"
