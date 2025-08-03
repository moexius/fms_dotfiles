#!/usr/bin/env bash
# ============================================================================
# Universal ZSH + Starship Dotfiles Installer
# Supports: Debian, Ubuntu, CentOS/RHEL, Fedora, Arch, Alpine, macOS
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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
REPO_URL="https://github.com/moexius/fms_dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

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
            arch|manjaro)
                OS="arch"
                PACKAGE_MANAGER="pacman"
                ;;
            alpine)
                OS="alpine"
                PACKAGE_MANAGER="apk"
                ;;
            *)
                log_error "Unsupported OS: $ID"
                exit 1
                ;;
        esac
    else
        log_error "Cannot detect OS"
        exit 1
    fi
    
    log_info "Detected OS: $OS with package manager: $PACKAGE_MANAGER"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]] && [[ "$OS" != "alpine" ]]; then
        log_warning "Running as root. Some operations will be performed for the root user."
        USER_HOME="/root"
    else
        USER_HOME="$HOME"
    fi
}

# Update package lists
update_packages() {
    log_info "Updating package lists..."
    case $PACKAGE_MANAGER in
        apt)
            sudo apt update
            ;;
        yum)
            sudo yum update -y
            ;;
        dnf)
            sudo dnf update -y
            ;;
        pacman)
            sudo pacman -Sy
            ;;
        apk)
            sudo apk update
            ;;
        brew)
            brew update
            ;;
    esac
}

# Install required packages
install_packages() {
    log_info "Installing required packages..."
    
    case $OS in
        debian)
            sudo apt install -y zsh curl git wget unzip build-essential fd-find bat lsd
            ;;
        rhel|fedora)
            if [[ "$PACKAGE_MANAGER" == "yum" ]]; then
                sudo yum install -y zsh curl git wget unzip gcc make
                # Install additional tools from EPEL if available
                sudo yum install -y epel-release || true
                sudo yum install -y fd-find bat lsd || true
            else
                sudo dnf install -y zsh curl git wget unzip gcc make fd-find bat lsd
            fi
            ;;
        arch)
            sudo pacman -S --noconfirm zsh curl git wget unzip base-devel fd bat lsd
            ;;
        alpine)
            sudo apk add zsh curl git wget unzip build-base fd bat lsd
            ;;
        macos)
            if ! command -v brew >/dev/null 2>&1; then
                log_info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                
                # Add Homebrew to PATH for Apple Silicon Macs
                if [[ -f "/opt/homebrew/bin/brew" ]]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                fi
            fi
            brew install zsh curl git wget fd bat lsd fzf zoxide tldr
            ;;
    esac
    
    log_success "Required packages installed"
}

# Install Starship
install_starship() {
    log_info "Installing Starship..."
    
    if command -v starship >/dev/null 2>&1; then
        log_warning "Starship already installed, skipping..."
        return
    fi
    
    case $OS in
        macos)
            brew install starship
            ;;
        *)
            # Use the official installer for Linux
            curl -sS https://starship.rs/install.sh | sh -s -- -y
            ;;
    esac
    
    log_success "Starship installed"
}

# Install additional tools
install_additional_tools() {
    log_info "Installing additional tools..."
    
    # Install fzf if not available via package manager
    if ! command -v fzf >/dev/null 2>&1 && [[ "$OS" != "macos" ]]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all
    fi
    
    # Install zoxide if not available
    if ! command -v zoxide >/dev/null 2>&1; then
        case $OS in
            macos)
                brew install zoxide
                ;;
            *)
                curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
                ;;
        esac
    fi
    
    log_success "Additional tools installed"
}

# Clone or update dotfiles
setup_dotfiles() {
    log_info "Setting up dotfiles..."
    
    if [[ -d "$DOTFILES_DIR" ]]; then
        log_info "Dotfiles directory exists, updating..."
        cd "$DOTFILES_DIR"
        git pull origin main
    else
        log_info "Cloning dotfiles repository..."
        git clone "$REPO_URL" "$DOTFILES_DIR"
        cd "$DOTFILES_DIR"
    fi
    
    log_success "Dotfiles ready"
}

# Backup existing configs
backup_configs() {
    log_info "Backing up existing configurations..."
    
    local backup_dir="$HOME/.config-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$backup_dir/"
    [[ -f "$HOME/.config/starship.toml" ]] && cp "$HOME/.config/starship.toml" "$backup_dir/"
    
    if [[ -n "$(ls -A "$backup_dir" 2>/dev/null)" ]]; then
        log_success "Backup created at: $backup_dir"
    else
        rmdir "$backup_dir"
        log_info "No existing configurations to backup"
    fi
}

# Install configurations
install_configs() {
    log_info "Installing configurations..."
    
    # Create necessary directories
    mkdir -p "$HOME/.config"
    
    # Install .zshrc
    if [[ -f "$DOTFILES_DIR/configs/zshrc" ]]; then
        cp "$DOTFILES_DIR/configs/zshrc" "$HOME/.zshrc"
        log_success "ZSH configuration installed"
    else
        log_error "ZSH configuration not found in dotfiles"
        exit 1
    fi
    
    # Install starship.toml
    if [[ -f "$DOTFILES_DIR/configs/starship.toml" ]]; then
        cp "$DOTFILES_DIR/configs/starship.toml" "$HOME/.config/starship.toml"
        log_success "Starship configuration installed"
    else
        log_error "Starship configuration not found in dotfiles"
        exit 1
    fi
    
    # Make zsh the default shell
    if [[ "$SHELL" != *"zsh"* ]]; then
        log_info "Setting ZSH as default shell..."
        local zsh_path
        zsh_path=$(which zsh)
        
        if ! grep -q "$zsh_path" /etc/shells; then
            echo "$zsh_path" | sudo tee -a /etc/shells
        fi
        
        chsh -s "$zsh_path"
        log_success "ZSH set as default shell"
    fi
}

# Main installation function
main() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 ZSH + Starship Dotfiles Installer           ║"
    echo "║                                                              ║"
    echo "║  This script will install and configure:                    ║"
    echo "║  • ZSH shell with custom configuration                      ║"
    echo "║  • Starship prompt with beautiful theme                     ║"
    echo "║  • Essential development tools                               ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Ask for confirmation
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled"
        exit 0
    fi
    
    detect_os
    check_root
    update_packages
    install_packages
    install_starship
    install_additional_tools
    setup_dotfiles
    backup_configs
    install_configs
    
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Installation Complete!                   ║"
    echo "║                                                              ║"
    echo "║  Please restart your terminal or run:                       ║"
    echo "║  source ~/.zshrc                                             ║"
    echo "║                                                              ║"
    echo "║  Your old configurations have been backed up.               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Run main function
main "$@"