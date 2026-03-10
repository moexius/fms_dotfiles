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
        OS="macos"; PACKAGE_MANAGER="brew"
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
        log_error "Cannot detect OS"; exit 1
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

# PHASE 1: Baseline Dependencies
install_baseline() {
    log_info "Installing baseline dependencies (git, curl, wget, zsh)..."
    case $OS in
        debian) sudo apt install -y git curl wget unzip zsh build-essential ;;
        rhel|fedora)
            if [[ "$PACKAGE_MANAGER" == "yum" ]]; then
                sudo yum install -y git curl wget unzip zsh gcc make epel-release
            else
                sudo dnf install -y git curl wget unzip zsh gcc make
            fi ;;
        arch)
            sudo pacman -S --noconfirm git curl wget unzip zsh base-devel
            if [[ "$IS_CACHYOS" == "true" ]]; then
                sudo pacman -S --noconfirm cpupower cachyos-hello cachyos-kernel-manager 2>/dev/null || true
            fi ;;
        alpine) sudo apk add git curl wget unzip zsh build-base ;;
        opensuse) sudo zypper install -y git curl wget unzip zsh gcc make find-utils ripgrep ;;
        macos)
            if ! command -v brew >/dev/null 2>&1; then
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                [[ -f "/opt/homebrew/bin/brew" ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
            brew install git curl wget zsh unzip ;;
    esac
}

# PHASE 2: Clone Dotfiles
setup_dotfiles() {
    log_info "Setting up dotfiles repository..."
    if [[ -d "$DOTFILES_DIR" ]]; then
        cd "$DOTFILES_DIR" && git pull origin main
    else
        git clone "$REPO_URL" "$DOTFILES_DIR" && cd "$DOTFILES_DIR"
    fi
}

# PHASE 3: Profile Apps
install_profile_packages() {
    log_info "Detecting machine profile for software provisioning..."

    if grep -qa container=lxc /proc/1/environ 2>/dev/null; then
        log_info "📦 Profile: LXC Container (Headless)"
        if [[ -f "$DOTFILES_DIR/packages/lxc.txt" ]]; then
            local pkgs=$(grep -vE "^\s*#" "$DOTFILES_DIR/packages/lxc.txt" | tr '\n' ' ')
            sudo apt install -y $pkgs
            log_success "LXC headless packages installed."
        else
            log_warning "No packages/lxc.txt found in repo. Skipping extra apps."
        fi

    elif [[ "$OS" == "macos" ]]; then
        log_info "🍎 Profile: macOS Workstation"
        if [[ -f "$DOTFILES_DIR/packages/Brewfile" ]]; then
            brew bundle --file="$DOTFILES_DIR/packages/Brewfile"
            log_success "macOS apps installed via Brewfile."
        else
            log_warning "No packages/Brewfile found. Skipping."
        fi

    elif [[ "$IS_CACHYOS" == "true" ]]; then
        log_info "🚀 Profile: CachyOS Workstation"
        if [[ -f "$DOTFILES_DIR/packages/cachyos.txt" ]]; then
            local pkgs=$(grep -vE "^\s*#" "$DOTFILES_DIR/packages/cachyos.txt" | tr '\n' ' ')
            sudo pacman -S --needed --noconfirm $pkgs
            log_success "CachyOS packages installed."
        else
            log_warning "No packages/cachyos.txt found. Skipping."
        fi

    else
        log_info "❓ Profile: Generic $OS"
        case $PACKAGE_MANAGER in
            apt) sudo apt install -y fd-find bat lsd 2>/dev/null || true ;;
            pacman) sudo pacman -S --noconfirm fd bat lsd 2>/dev/null || true ;;
            apk) sudo apk add fd bat lsd 2>/dev/null || true ;;
            zypper) sudo zypper install -y fd bat lsd 2>/dev/null || true ;;
            brew) brew install fd bat lsd fzf zoxide tldr ;;
        esac
    fi
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

install_fresh_editor() {
    log_info "Installing fresh-editor from official sources..."
    
    if command -v fresh >/dev/null 2>&1; then
        log_info "fresh-editor is already installed."
        return
    fi

    case $OS in
        macos)
            # Handled automatically by our Brewfile, but here as a fallback
            if ! command -v fresh >/dev/null 2>&1; then
                brew tap sinelaw/fresh
                brew install fresh-editor
            fi
            ;;
        arch)
            # CachyOS / Arch: The repo recommends the binary AUR package
            log_info "Installing via AUR (fresh-editor-bin)..."
            if command -v yay >/dev/null 2>&1; then
                yay -S --noconfirm fresh-editor-bin
            elif command -v paru >/dev/null 2>&1; then
                paru -S --noconfirm fresh-editor-bin
            else
                # Fallback to the official auto-detect script if no AUR helper is found
                curl -fsSL https://raw.githubusercontent.com/sinelaw/fresh/refs/heads/master/scripts/install.sh | sh
            fi
            ;;
        debian)
            # Debian / Proxmox LXC: Download and install the latest .deb natively
            log_info "Fetching latest .deb release for Debian..."
            local DEB_URL=$(curl -s https://api.github.com/repos/sinelaw/fresh/releases/latest | grep "browser_download_url.*_$(dpkg --print-architecture)\.deb" | cut -d '"' -f 4)
            
            if [[ -n "$DEB_URL" ]]; then
                curl -sL "$DEB_URL" -o /tmp/fresh-editor.deb
                sudo dpkg -i /tmp/fresh-editor.deb
                rm /tmp/fresh-editor.deb
            else
                # Fallback to the official auto-detect script
                curl -fsSL https://raw.githubusercontent.com/sinelaw/fresh/refs/heads/master/scripts/install.sh | sh
            fi
            ;;
        *)
            # Universal fallback for any other OS
            curl -fsSL https://raw.githubusercontent.com/sinelaw/fresh/refs/heads/master/scripts/install.sh | sh
            ;;
    esac
    
    log_success "fresh-editor installed successfully!"
}

main() {
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
    
    detect_os
    check_root
    update_packages
    
    # 💥 The newly ordered installation flow
    install_baseline
    setup_dotfiles
    install_profile_packages
    
    install_starship
    install_additional_tools
    install_tldr
    backup_configs
    install_configs
    create_private_aliases

    install_fresh_editor
    
    echo -e "${GREEN}🎉 ZSH and Starship have been installed successfully!${NC}"
    if [[ "$0" != *"zsh"* ]] && [[ -z "$ZSH_VERSION" ]]; then
        exec zsh
    fi
}

main "$@"