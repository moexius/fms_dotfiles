#!/usr/bin/env bash
# ============================================================================
# Universal Dotfiles Update Script
# Supports: Debian, Ubuntu, CentOS/RHEL, Fedora, Arch, Alpine, openSUSE, macOS
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
}

# Backup existing config file
backup_config() {
    local config_file="$1"
    local backup_dir="$HOME/.config-backup-$(date +%Y%m%d_%H%M%S)"
    
    if [[ -f "$config_file" ]]; then
        mkdir -p "$backup_dir"
        cp "$config_file" "$backup_dir/"
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
    
    if [[ -f "$source" ]]; then
        # Backup existing config
        backup_config "$destination"
        
        # Create destination directory if needed
        mkdir -p "$(dirname "$destination")"
        
        # Copy config file
        cp "$source" "$destination"
        log_success "$config_name configuration updated"
    else
        log_warning "$config_name configuration not found: $source"
        return 1
    fi
}

# Check if dotfiles directory exists
check_dotfiles_dir() {
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "Dotfiles directory not found at: $DOTFILES_DIR"
        log_error "Please run the installer first with: ./install.sh"
        exit 1
    fi
}

# Update dotfiles repository
update_repository() {
    log_info "Updating dotfiles repository..."
    
    cd "$DOTFILES_DIR"
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Dotfiles directory is not a git repository"
        exit 1
    fi
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        log_warning "You have uncommitted changes in your dotfiles repository"
        read -p "Do you want to stash them and continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git stash push -m "Auto-stash before update $(date)"
            log_info "Changes stashed"
        else
            log_info "Update cancelled"
            exit 0
        fi
    fi
    
    # Pull latest changes
    if git pull origin main; then
        log_success "Repository updated successfully"
    else
        log_error "Failed to update repository"
        exit 1
    fi
}

# Update configurations
update_configs() {
    log_info "Updating configurations..."
    
    local configs_updated=0
    
    # Update ZSH config
    if install_config "$DOTFILES_DIR/config/zsh/zshrc" "$HOME/.zshrc" "ZSH"; then
        ((configs_updated++))
    fi
    
    # Update ZSH aliases if they exist
    if [[ -f "$DOTFILES_DIR/config/zsh/aliases" ]]; then
        install_config "$DOTFILES_DIR/config/zsh/aliases" "$HOME/.zsh_aliases" "ZSH aliases"
        ((configs_updated++))
    fi
    
    # Update Starship config
    if install_config "$DOTFILES_DIR/config/starship/starship.toml" "$HOME/.config/starship.toml" "Starship"; then
        ((configs_updated++))
    fi
    
    # Update Vim config if it exists
    if [[ -f "$DOTFILES_DIR/config/vim/vimrc" ]]; then
        install_config "$DOTFILES_DIR/config/vim/vimrc" "$HOME/.vimrc" "Vim"
        ((configs_updated++))
    fi
    
    # Update Git config if it exists
    if [[ -f "$DOTFILES_DIR/config/git/gitconfig" ]]; then
        install_config "$DOTFILES_DIR/config/git/gitconfig" "$HOME/.gitconfig" "Git"
        ((configs_updated++))
    fi
    
    # Update Tmux config if it exists
    if [[ -f "$DOTFILES_DIR/config/tmux/tmux.conf" ]]; then
        install_config "$DOTFILES_DIR/config/tmux/tmux.conf" "$HOME/.tmux.conf" "Tmux"
        ((configs_updated++))
    fi
    
    # Update Neovim config if it exists
    if [[ -d "$DOTFILES_DIR/config/nvim" ]]; then
        if [[ -d "$HOME/.config/nvim" ]]; then
            backup_config "$HOME/.config/nvim"
        fi
        mkdir -p "$HOME/.config"
        cp -r "$DOTFILES_DIR/config/nvim" "$HOME/.config/"
        log_success "Neovim configuration updated"
        ((configs_updated++))
    fi
    
    if [[ $configs_updated -eq 0 ]]; then
        log_warning "No configuration files were updated"
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
    echo
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                     Update Complete!                        ║"
    echo "║                                                              ║"
    echo "║  ✅ Dotfiles repository updated                              ║"
    echo "║  ✅ Configuration files updated                              ║"
    echo "║  ✅ System tools updated                                     ║"
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
    echo "║  • Update configuration files                               ║"
    echo "║  • Update system tools (optional)                           ║"
    echo "║  • Create backups of existing configs                       ║"
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
    
    # Automatically reload zsh if we're in zsh
    if [[ -n "$ZSH_VERSION" ]]; then
        log_info "Reloading ZSH configuration..."
        source ~/.zshrc
        log_success "ZSH configuration reloaded!"
    fi
}

# Run main function
main "$@"