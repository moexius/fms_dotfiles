#!/usr/bin/env bash
# ============================================================================
# Universal ZSH + Starship Dotfiles Installer
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
            cachyos)
                OS="arch"
                PACKAGE_MANAGER="pacman"
                IS_CACHYOS="true"
                log_info "CachyOS detected - performance optimized Arch derivative"
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
    if [[ "$IS_CACHYOS" == "true" ]]; then
        log_info "🚀 CachyOS optimizations will be enabled"
    fi
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
            if [[ "$IS_CACHYOS" == "true" ]]; then
                # Update CachyOS keyring first
                sudo pacman -Sy cachyos-keyring --noconfirm 2>/dev/null || true
            fi
            sudo pacman -Sy
            ;;
        apk)
            sudo apk update
            ;;
        zypper)
            sudo zypper refresh
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
                sudo dnf install -y fd bat lsd 2>/dev/null || log_warning "Some additional tools not available"
            fi
            ;;
        arch)
            sudo pacman -S --noconfirm zsh curl git wget unzip base-devel
            sudo pacman -S --noconfirm fd bat lsd 2>/dev/null || log_warning "Some additional tools not available"
            
            # CachyOS specific packages
            if [[ "$IS_CACHYOS" == "true" ]]; then
                log_info "Installing CachyOS specific tools..."
                sudo pacman -S --noconfirm cpupower 2>/dev/null || log_warning "cpupower not available"
                # Install CachyOS tools if available
                sudo pacman -S --noconfirm cachyos-hello cachyos-kernel-manager 2>/dev/null || log_warning "CachyOS tools not available"
            fi
            ;;
        alpine)
            sudo apk add zsh curl git wget unzip build-base
            sudo apk add fd bat lsd 2>/dev/null || log_warning "Some additional tools not available"
            ;;
        opensuse)
            sudo zypper install -y zsh curl git wget unzip gcc make
            # Install additional tools if available
            sudo zypper install -y fd bat lsd 2>/dev/null || log_warning "Some additional tools not available in repositories"
            # Some tools might be in different package names for openSUSE
            sudo zypper install -y find-utils ripgrep 2>/dev/null || true
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
        opensuse)
            # Try to install from repositories first
            if sudo zypper install -y starship 2>/dev/null; then
                log_success "Starship installed from repository"
            else
                log_info "Installing Starship from official installer..."
                curl -sS https://starship.rs/install.sh | sh -s -- -y
            fi
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
            opensuse)
                # Try repository first, fallback to installer
                if ! sudo zypper install -y zoxide 2>/dev/null; then
                    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
                fi
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
            opensuse)
                # Try repository first, fallback to npm
                if ! sudo zypper install -y tldr 2>/dev/null; then
                    if command -v npm >/dev/null 2>&1; then
                        sudo npm install -g tldr
                    else
                        log_warning "tldr not available, install nodejs and npm to get it"
                    fi
                fi
                ;;
            *)
                # Try package manager first, fallback to npm
                case $PACKAGE_MANAGER in
                    dnf) sudo dnf install -y tldr 2>/dev/null || log_warning "tldr not available in repositories" ;;
                    yum) sudo yum install -y tldr 2>/dev/null || log_warning "tldr not available in repositories" ;;
                    pacman) sudo pacman -S --noconfirm tldr 2>/dev/null || log_warning "tldr not available in repositories" ;;
                    apk) sudo apk add tldr 2>/dev/null || log_warning "tldr not available in repositories" ;;
                    zypper) sudo zypper install -y tldr 2>/dev/null || log_warning "tldr not available in repositories" ;;
                esac
                ;;
        esac
    fi
}

# Create private aliases file for SSH servers (only on designated systems)
create_private_aliases() {
    local private_aliases="$HOME/.zsh_private_aliases"
    
    if [[ -f "$private_aliases" ]]; then
        log_info "Private aliases file already exists at $private_aliases"
        return 0
    fi
    
    # Only offer to create on macOS systems by default
    if [[ "$OS" != "macos" ]]; then
        log_info "Private aliases file creation is typically only needed on your main macOS system"
        echo
        read -p "Create private aliases file on this $OS system anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping private aliases file creation"
            log_info "The file can be created later if needed for SSH Apple Watch authentication"
            return 0
        fi
    else
        # On macOS, ask if this is the main system
        echo
        log_info "Private aliases file not found at $private_aliases"
        echo
        echo -e "${YELLOW}This file contains sensitive SSH server information and should only${NC}"
        echo -e "${YELLOW}be created on your main macOS system where you manage servers.${NC}"
        echo
        echo -e "${BLUE}Benefits of creating this file:${NC}"
        echo -e "  • Enables SSH Apple Watch authentication setup"
        echo -e "  • Provides convenient SSH server aliases"
        echo -e "  • Keeps sensitive IPs out of public dotfiles repo"
        echo
        read -p "Is this your main macOS system? Create private aliases file? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping private aliases file creation"
            log_info "You can create $private_aliases manually later if needed"
            return 0
        fi
    fi
    
    log_info "Creating private aliases file for SSH servers..."
    
    cat > "$private_aliases" << 'EOF'
# Private ZSH Aliases
# This file contains sensitive information and should not be committed to version control
# Created by dotfiles installer

# SSH Server Aliases (replace with your actual server IPs)
# Format: alias servername='ssh user@ip.address'
alias huntarr='ssh root@192.168.1.196'
alias komga='ssh root@192.168.1.72'
alias mylar3='ssh root@192.168.1.52'
alias overseerr='ssh root@192.168.1.79'
alias plexms='ssh root@192.168.1.221'
alias prowlarr='ssh root@192.168.1.89'
alias radarr='ssh root@192.168.1.172'
alias sabnzbd='ssh root@192.168.1.88'
alias sonarr='ssh root@192.168.1.157'
alias tautulli='ssh root@192.168.1.66'
alias tinypc='ssh root@192.168.1.12'

# Add your private environment variables here
# export PRIVATE_API_KEY="your-secret-key"
# export DATABASE_URL="your-database-connection"

# Add any other private configurations here
EOF
    
    chmod 600 "$private_aliases"  # Make it readable only by owner
    log_success "Private aliases file created at $private_aliases"
    echo
    echo -e "${YELLOW}Important:${NC}"
    echo -e "  1. Update the IP addresses in $private_aliases with your actual servers"
    echo -e "  2. This file is excluded from version control (keep it private)"
    echo -e "  3. Restart your terminal or run 'source ~/.zshrc' to load the aliases"
}

# SSH Apple Watch Setup (only on macOS with private aliases)
setup_ssh_apple_watch() {
    # Only offer SSH Apple Watch setup on macOS and if private aliases file exists
    if [[ "$OS" == "macos" ]] && [[ -f "$HOME/.zsh_private_aliases" ]]; then
        echo
        echo -e "${BLUE}🍎⌚ SSH Apple Watch Authentication Available${NC}"
        echo -e "This will set up SSH key authentication using your Apple Watch for approval."
        echo
        read -p "Setup SSH with Apple Watch authentication? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Running SSH Apple Watch setup..."
            if [[ -f "$DOTFILES_DIR/scripts/setup-ssh-apple-watch.sh" ]]; then
                "$DOTFILES_DIR/scripts/setup-ssh-apple-watch.sh"
            else
                log_error "SSH setup script not found at $DOTFILES_DIR/scripts/setup-ssh-apple-watch.sh"
                log_info "You can run it manually later when the script is available"
            fi
        fi
    else
        # Log why SSH Apple Watch setup is not available
        if [[ "$OS" != "macos" ]]; then
            log_info "SSH Apple Watch authentication is only available on macOS (detected: $OS)"
        elif [[ ! -f "$HOME/.zsh_private_aliases" ]]; then
            log_info "SSH Apple Watch setup requires private aliases file ($HOME/.zsh_private_aliases)"
            log_info "Create the private aliases file first, then run the SSH setup script manually"
        fi
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
    echo "║  • Optional private aliases for SSH servers                 ║"
    echo "║  • Optional SSH Apple Watch authentication (macOS only)     ║"
    echo "║  • CachyOS performance optimizations (if detected)          ║"
    echo "║                                                              ║"
    echo "║  Supported platforms:                                       ║"
    echo "║  • macOS (Homebrew)                                         ║"
    echo "║  • Debian/Ubuntu (apt)                                      ║"
    echo "║  • CentOS/RHEL/Fedora (yum/dnf)                            ║"
    echo "║  • Arch Linux/CachyOS (pacman)                             ║"
    echo "║  • Alpine Linux (apk)                                       ║"
    echo "║  • openSUSE (zypper)                                        ║"
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
    
    # Create private aliases (user will be prompted based on OS)
    create_private_aliases
    
    # SSH Apple Watch setup (will only work if private aliases exist and on macOS)
    setup_ssh_apple_watch
    
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Installation Complete!                   ║"
    echo "║                                                              ║"
    if [[ "$IS_CACHYOS" == "true" ]]; then
        echo "║  🚀 ZSH and Starship installed with CachyOS optimizations!  ║"
    else
        echo "║  🎉 ZSH and Starship have been installed successfully!      ║"
    fi
    echo "║                                                              ║"
    echo "║  Next steps:                                                 ║"
    echo "║  1. Start ZSH: run 'zsh' command                            ║"
    echo "║  2. Or log out and log back in for permanent change         ║"
    echo "║  3. Update private aliases file with your actual server IPs ║"
    echo "║  4. Enjoy your beautiful new shell!                         ║"
    echo "║                                                              ║"
    echo "║  Useful commands to try:                                     ║"
    echo "║  • sysinfo    - Show system information                     ║"
    echo "║  • weather    - Get weather info                            ║"
    echo "║  • Ctrl+R     - Fuzzy search command history               ║"
    echo "║  • Ctrl+T     - Fuzzy search files                         ║"
    echo "║  • sa         - Reload shell configuration                  ║"
    echo "║  • ah         - Alias help system                           ║"
    if [[ "$IS_CACHYOS" == "true" ]]; then
        echo "║  • al cachyos - CachyOS performance commands                ║"
        echo "║  • cm         - CachyOS maintenance                         ║"
    fi
    echo "║                                                              ║"
    if [[ -f "$HOME/.zsh_private_aliases" ]]; then
    echo "║  Private aliases created - remember to update server IPs!   ║"
    echo "║                                                              ║"
    fi
    echo "║  Repository: https://github.com/moexius/fms_dotfiles        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Show next steps for private aliases if created
    if [[ -f "$HOME/.zsh_private_aliases" ]]; then
        echo
        echo -e "${YELLOW}📝 Don't forget to:${NC}"
        echo -e "   1. Edit ~/.zsh_private_aliases with your actual server IPs"
        echo -e "   2. Run 'source ~/.zshrc' or restart your terminal"
        if [[ "$OS" == "macos" ]]; then
            echo -e "   3. Run SSH Apple Watch setup if you skipped it: $DOTFILES_DIR/scripts/setup-ssh-apple-watch.sh"
        fi
    fi
    
    # Show CachyOS specific info
    if [[ "$IS_CACHYOS" == "true" ]]; then
        echo
        echo -e "${CYAN}🚀 CachyOS Performance Tips:${NC}"
        echo -e "   • Use 'performance' to enable performance CPU governor"
        echo -e "   • Use 'balanced' for balanced performance/power"
        echo -e "   • Use 'cpustatus' to check current CPU settings"
        echo -e "   • Use 'cm' for system maintenance"
    fi
    
    # Automatically start zsh if we're not already in it
    if [[ "$0" != *"zsh"* ]] && [[ -z "$ZSH_VERSION" ]]; then
        echo -e "${YELLOW}Starting ZSH now...${NC}"
        exec zsh
    fi
}

# Run main function
main "$@"
