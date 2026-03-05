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
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://github.com/moexius/fms_dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        PACKAGE_MANAGER="brew"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case $ID in
            debian|ubuntu) OS="debian"; PACKAGE_MANAGER="apt" ;;
            centos|rhel|rocky|almalinux) OS="rhel"; PACKAGE_MANAGER="yum" ;;
            fedora) OS="fedora"; PACKAGE_MANAGER="dnf" ;;
            opensuse*|sles) OS="opensuse"; PACKAGE_MANAGER="zypper" ;;
            arch|manjaro) OS="arch"; PACKAGE_MANAGER="pacman" ;;
            cachyos) OS="arch"; PACKAGE_MANAGER="pacman"; IS_CACHYOS="true" ;;
            alpine) OS="alpine"; PACKAGE_MANAGER="apk" ;;
            *) log_error "Unsupported OS: $ID"; exit 1 ;;
        esac
    else
        log_error "Cannot detect OS"
        exit 1
    fi
    log_info "Detected OS: $OS with package manager: $PACKAGE_MANAGER"
}

check_root() {
    if [[ $EUID -eq 0 ]] && [[ "$OS" != "alpine" ]]; then
        log_warning "Running as root. Some operations will be performed for the root user."
        USER_HOME="/root"
    else
        USER_HOME="$HOME"
    fi
}

update_packages() {
    log_info "Updating package lists..."
    case $PACKAGE_MANAGER in
        apt) sudo apt update ;;
        yum) sudo yum update -y ;;
        dnf) sudo dnf update -y ;;
        pacman)
            [[ "$IS_CACHYOS" == "true" ]] && sudo pacman -Sy cachyos-keyring --noconfirm 2>/dev/null || true
            sudo pacman -Sy ;;
        apk) sudo apk update ;;
        zypper) sudo zypper refresh ;;
        brew) brew update ;;
    esac
}

install_packages() {
    log_info "Installing required packages..."
    case $OS in
        debian)
            sudo apt install -y zsh curl git wget unzip build-essential
            sudo apt install -y fd-find bat lsd 2>/dev/null || true ;;
        rhel|fedora)
            if [[ "$PACKAGE_MANAGER" == "yum" ]]; then
                sudo yum install -y zsh curl git wget unzip gcc make epel-release
                sudo yum install -y fd-find bat lsd 2>/dev/null || true
            else
                sudo dnf install -y zsh curl git wget unzip gcc make
                sudo dnf install -y fd bat lsd 2>/dev/null || true
            fi ;;
        arch)
            sudo pacman -S --noconfirm zsh curl git wget unzip base-devel fd bat lsd
            if [[ "$IS_CACHYOS" == "true" ]]; then
                sudo pacman -S --noconfirm cpupower cachyos-hello cachyos-kernel-manager 2>/dev/null || true
            fi ;;
        alpine)
            sudo apk add zsh curl git wget unzip build-base fd bat lsd 2>/dev/null || true ;;
        opensuse)
            sudo zypper install -y zsh curl git wget unzip gcc make find-utils ripgrep fd bat lsd 2>/dev/null || true ;;
        macos)
            if ! command -v brew >/dev/null 2>&1; then
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                [[ -f "/opt/homebrew/bin/brew" ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
            brew install zsh curl git wget fd bat lsd fzf zoxide tldr ;;
    esac
    log_success "Required packages installed"
}

install_starship() {
    log_info "Installing Starship..."
    if command -v starship >/dev/null 2>&1; then return; fi
    case $OS in
        macos) brew install starship ;;
        opensuse) sudo zypper install -y starship 2>/dev/null || curl -sS https://starship.rs/install.sh | sh -s -- -y ;;
        *) curl -sS https://starship.rs/install.sh | sh -s -- -y ;;
    esac
}

install_additional_tools() {
    log_info "Installing additional tools..."
    if ! command -v fzf >/dev/null 2>&1 && [[ "$OS" != "macos" ]]; then
        if [[ ! -d ~/.fzf ]]; then
            git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
            ~/.fzf/install --all --no-bash --no-fish
        fi
    fi
    if ! command -v zoxide >/dev/null 2>&1; then
        case $OS in
            macos) brew install zoxide ;;
            *) curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash ;;
        esac
    fi
}

install_tldr() {
    if ! command -v tldr >/dev/null 2>&1; then
        log_info "Installing tldr..."
        case $OS in
            macos) brew install tldr ;;
            *)
                if command -v npm >/dev/null 2>&1; then sudo npm install -g tldr; fi
                ;;
        esac
    fi
}

setup_dotfiles() {
    log_info "Setting up dotfiles..."
    if [[ -d "$DOTFILES_DIR" ]]; then
        cd "$DOTFILES_DIR" && git pull origin main
    else
        git clone "$REPO_URL" "$DOTFILES_DIR" && cd "$DOTFILES_DIR"
    fi
}

backup_configs() {
    log_info "Backing up existing configurations..."
    local backup_dir="$HOME/.config-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$backup_dir/"
    [[ -f "$HOME/.config/starship.toml" && ! -L "$HOME/.config/starship.toml" ]] && cp "$HOME/.config/starship.toml" "$backup_dir/"
    [[ -z "$(ls -A "$backup_dir" 2>/dev/null)" ]] && rmdir "$backup_dir" 2>/dev/null || log_success "Backup created"
}

set_default_shell() {
    log_info "Setting ZSH as default shell..."
    local zsh_path=$(which zsh)
    [[ -z "$zsh_path" ]] && return 1
    if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null; fi
    if [[ "$SHELL" != *"zsh"* ]]; then chsh -s "$zsh_path" 2>/dev/null || true; fi
}

install_configs() {
    log_info "Installing configurations..."
    mkdir -p "$HOME/.config" "$HOME/.config/zsh"
    
    if [[ -f "$DOTFILES_DIR/configs/zsh/zshrc" ]]; then
        ln -sf "$DOTFILES_DIR/configs/zsh/zshrc" "$HOME/.zshrc"
        log_success "ZSH configuration symlinked"
    else
        log_error "ZSH configuration not found"
        exit 1
    fi
    
    if [[ -f "$DOTFILES_DIR/configs/starship.toml" ]]; then
        ln -sf "$DOTFILES_DIR/configs/starship.toml" "$HOME/.config/starship.toml"
        log_success "Starship configuration symlinked"
    fi
    set_default_shell
}

create_private_aliases() {
    local private_aliases="$HOME/.zsh_private_aliases"
    [[ -f "$private_aliases" ]] && return 0
    
    if [[ "$OS" != "macos" ]]; then return 0; fi
    
    cat > "$private_aliases" << 'EOF'
# Private ZSH Aliases
alias tinypc='ssh root@192.168.1.12'
EOF
    chmod 600 "$private_aliases"
}

main() {
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
    
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
    create_private_aliases
    
    echo -e "${GREEN}🎉 ZSH and Starship have been installed successfully!${NC}"
    if [[ "$0" != *"zsh"* ]] && [[ -z "$ZSH_VERSION" ]]; then
        exec zsh
    fi
}

main "$@"