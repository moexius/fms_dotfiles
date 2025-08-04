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
            sudo apt install -y zsh curl git wget unzip build-essential
            # Try to install additional tools, but don't fail if they're not available
            sudo apt install -y fd-find bat lsd 2>/dev/null || log_warning "Some additional tools not available in repositories"
            ;;
        rhel|fedora)
            if [[ "$PACKAGE_MANAGER" == "yum" ]]; then
                sudo yum install -y zsh curl git wget unzip gcc make
                # Install additional tools from EPEL if available
                sudo yum install -y epel-release 2>/dev/null || true
                sudo yum install -y fd-find bat lsd 2>/dev/null || log_warning "Some additional tools not available"
            else
                sudo dnf install -y zsh curl git wget unzip gcc make
                sudo dnf install -y fd-find bat lsd 2>/dev/null || log_warning "Some additional tools not available"
            fi
            ;;
        arch)
            sudo pacman -S --noconfirm zsh curl git wget unzip base-devel
            sudo pacman -S --noconfirm fd bat lsd 2>/dev/null || log_warning "Some additional tools not available"
            ;;
        alpine)
            sudo apk add zsh curl git wget unzip build-base
            sudo apk add fd bat lsd 2>/dev/null || log_warning "Some additional tools not available"
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
        if [[ ! -d ~/.fzf ]]; then
            log_info "Installing fzf..."
            git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
            ~/.fzf/install --all --no-bash --no-fish
        else
            log_warning "fzf directory already exists, skipping..."
        fi
    fi
    
    # Install zoxide if not available
    if ! command -v zoxide >/dev/null 2>&1; then
        log_info "Installing zoxide..."
        case $OS in
            macos)
                brew install zoxide
                ;;
            *)
                curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
                ;;
        esac
    else
        log_warning "zoxide already installed, skipping..."
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

# Set ZSH as default shell
set_default_shell() {
    log_info "Setting ZSH as default shell..."
    
    local zsh_path
    zsh_path=$(which zsh)
    
    if [[ -z "$zsh_path" ]]; then
        log_error "ZSH not found in PATH"
        return 1
    fi
    
    # Check if zsh is in /etc/shells
    if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
        log_info "Adding ZSH to /etc/shells..."
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi
    
    # Change default shell if it's not already zsh
    if [[ "$SHELL" != *"zsh"* ]]; then
        log_info "Changing default shell to ZSH..."
        if chsh -s "$zsh_path" 2>/dev/null; then
            log_success "Default shell changed to ZSH"
        else
            log_warning "Could not change default shell automatically. You can change it manually with: chsh -s $zsh_path"
        fi
    else
        log_info "ZSH is already the default shell"
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
    
    # Set ZSH as default shell
    set_default_shell
}

# Install tldr if not available
install_tldr() {
    if ! command -v tldr >/dev/null 2>&1; then
        log_info "Installing tldr..."
        case $OS in
            macos)
                brew install tldr
                ;;
            debian)
                sudo apt install -y tldr 2>/dev/null || {
                    # Fallback to npm version if not in repos
                    if command -v npm >/dev/null 2>&1; then
                        sudo npm install -g tldr
                    else
                        log_warning "tldr not available, install nodejs and npm to get it"
                    fi
                }
                ;;
            *)
                # Try package manager first, fallback to npm
                case $PACKAGE_MANAGER in
                    dnf) sudo dnf install -y tldr 2>/dev/null || log_warning "tldr not available in repositories" ;;
                    yum) sudo yum install -y tldr 2>/dev/null || log_warning "tldr not available in repositories" ;;
                    pacman) sudo pacman -S --noconfirm tldr 2>/dev/null || log_warning "tldr not available in repositories" ;;
                    apk) sudo apk add tldr 2>/dev/null || log_warning "tldr not available in repositories" ;;
                esac
                ;;
        esac
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
    echo "║  • Essential development tools (fzf, zoxide, bat, lsd)      ║"
    echo "║  • Automatic shell switching to ZSH                         ║"
    echo "║                                                              ║"
    echo "║  Supported platforms:                                       ║"
    echo "║  • macOS (Homebrew)                                         ║"
    echo "║  • Debian/Ubuntu (apt)                                      ║"
    echo "║  • CentOS/RHEL/Fedora (yum/dnf)                            ║"
    echo "║  • Arch Linux (pacman)                                      ║"
    echo "║  • Alpine Linux (apk)                                       ║"
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
    install_tldr
    setup_dotfiles
    backup_configs
    install_configs
    
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Installation Complete!                   ║"
    echo "║                                                              ║"
    echo "║  🎉 ZSH and Starship have been installed successfully!      ║"
    echo "║                                                              ║"
    echo "║  Next steps:                                                 ║"
    echo "║  1. Start ZSH: run 'zsh' command                            ║"
    echo "║  2. Or log out and log back in for permanent change         ║"
    echo "║  3. Enjoy your beautiful new shell!                         ║"
    echo "║                                                              ║"
    echo "║  Useful commands to try:                                     ║"
    echo "║  • sysinfo    - Show system information                     ║"
    echo "║  • weather    - Get weather info                            ║"
    echo "║  • Ctrl+R     - Fuzzy search command history               ║"
    echo "║  • Ctrl+T     - Fuzzy search files                         ║"
    echo "║  • sa         - Reload shell configuration                  ║"
    echo "║                                                              ║"
    echo "║  Repository: https://github.com/moexius/fms_dotfiles        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Automatically start zsh if we're not already in it
    if [[ "$0" != *"zsh"* ]] && [[ -z "$ZSH_VERSION" ]]; then
        echo -e "${YELLOW}Starting ZSH now...${NC}"
        exec zsh
    fi
}

# Run main function
main "$@"