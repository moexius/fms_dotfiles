#!/usr/bin/env bash
# ============================================================================
# Universal Dotfiles Update Script (Optimized)
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

DOTFILES_DIR="$HOME/.dotfiles"

# Detect OS and package manager
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
            *) OS="unknown"; PACKAGE_MANAGER="unknown" ;;
        esac
    else
        OS="unknown"
        PACKAGE_MANAGER="unknown"
    fi
    log_info "Detected OS: $OS with package manager: $PACKAGE_MANAGER"
}

check_dotfiles_dir() {
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "Dotfiles directory not found at: $DOTFILES_DIR"
        exit 1
    fi
}

update_repository() {
    log_info "Updating dotfiles repository..."
    cd "$DOTFILES_DIR"
    
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        log_warning "You have uncommitted changes in your dotfiles repository."
        git stash push -m "Auto-stash before update $(date)"
    fi
    
    git pull origin main 2>/dev/null || git pull origin master 2>/dev/null
    log_success "Repository updated."
}

update_configs() {
    log_info "Applying configurations..."
    local backup_dir="$HOME/.config-backup-$(date +%Y%m%d_%H%M%S)"
    local updated=0

    # Ensure target directories exist
    mkdir -p "$HOME/.config" "$backup_dir"

    # Backup & Copy zshrc
    if [[ -f "$DOTFILES_DIR/configs/zsh/zshrc" ]]; then
        if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
            mv "$HOME/.zshrc" "$backup_dir/"
        fi
        ln -sf "$DOTFILES_DIR/configs/zsh/zshrc" "$HOME/.zshrc"
        updated=$((updated + 1))
    fi

    # Backup & Copy Starship
    if [[ -f "$DOTFILES_DIR/configs/starship.toml" ]]; then
        if [[ -f "$HOME/.config/starship.toml" && ! -L "$HOME/.config/starship.toml" ]]; then
            mv "$HOME/.config/starship.toml" "$backup_dir/"
        fi
        ln -sf "$DOTFILES_DIR/configs/starship.toml" "$HOME/.config/starship.toml"
        updated=$((updated + 1))
    fi

    # Cleanup backup dir if empty
    rmdir "$backup_dir" 2>/dev/null || log_info "Old configs backed up to $backup_dir"
    log_success "$updated core configuration files linked."
}

sync_manifest_packages() {
    log_info "Syncing installed apps with package manifests..."

    if grep -qa container=lxc /proc/1/environ 2>/dev/null; then
        if [[ -f "$DOTFILES_DIR/packages/lxc.txt" ]]; then
            local pkgs=$(grep -vE "^\s*#" "$DOTFILES_DIR/packages/lxc.txt" | tr '\n' ' ')
            if [[ -n "$pkgs" ]]; then
                sudo apt install -y $pkgs
                log_success "LXC manifest packages synced."
            fi
        fi

    elif [[ "$OS" == "macos" ]]; then
        if [[ -f "$DOTFILES_DIR/packages/Brewfile" ]]; then
            brew bundle --file="$DOTFILES_DIR/packages/Brewfile"
            log_success "macOS Brewfile synced."
        fi

    elif [[ "$IS_CACHYOS" == "true" ]]; then
        if [[ -f "$DOTFILES_DIR/packages/cachyos.txt" ]]; then
            local pkgs=$(grep -vE "^\s*#" "$DOTFILES_DIR/packages/cachyos.txt" | tr '\n' ' ')
            if [[ -n "$pkgs" ]]; then
                sudo pacman -S --needed --noconfirm $pkgs
                log_success "CachyOS manifest packages synced."
            fi
        fi
    fi
}

ensure_fresh_editor() {
    if command -v fresh >/dev/null 2>&1; then
        log_info "Updating fresh-editor..."
        curl -fsSL https://raw.githubusercontent.com/sinelaw/fresh/refs/heads/master/scripts/install.sh | sh
        return
    fi

    log_info "fresh-editor is missing! Installing from official sources..."
    case $OS in
        macos)
            brew tap sinelaw/fresh 2>/dev/null || true
            brew install fresh-editor
            ;;
        arch)
            if command -v yay >/dev/null 2>&1; then
                yay -S --noconfirm fresh-editor-bin
            else
                curl -fsSL https://raw.githubusercontent.com/sinelaw/fresh/refs/heads/master/scripts/install.sh | sh
            fi
            ;;
        debian)
            local DEB_URL=$(curl -s https://api.github.com/repos/sinelaw/fresh/releases/latest | grep "browser_download_url.*_$(dpkg --print-architecture)\.deb" | cut -d '"' -f 4)
            if [[ -n "$DEB_URL" ]]; then
                curl -sL "$DEB_URL" -o /tmp/fresh-editor.deb
                sudo dpkg -i /tmp/fresh-editor.deb
                rm /tmp/fresh-editor.deb
            else
                curl -fsSL https://raw.githubusercontent.com/sinelaw/fresh/refs/heads/master/scripts/install.sh | sh
            fi
            ;;
        *)
            curl -fsSL https://raw.githubusercontent.com/sinelaw/fresh/refs/heads/master/scripts/install.sh | sh
            ;;
    esac
}

ensure_atuin() {
    if command -v atuin >/dev/null 2>&1; then
        return
    fi

    log_info "Atuin is missing! Installing..."
    case $OS in
        macos) brew install atuin ;;
        arch) sudo pacman -S --needed --noconfirm atuin ;;
        *) curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh ;;
    esac
    log_success "Atuin installed."
}

update_tools() {
    log_info "Checking for tool updates..."
    case $OS in
        macos)
            if command -v brew >/dev/null 2>&1; then
                brew update && brew upgrade
            fi
            ;;
        debian) sudo apt update && sudo apt upgrade -y ;;
        fedora|rhel)
            if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then sudo dnf update -y; else sudo yum update -y; fi
            ;;
        opensuse) sudo zypper refresh && sudo zypper update -y ;;
        arch)
            [[ "$IS_CACHYOS" == "true" ]] && sudo pacman -Sy cachyos-keyring --noconfirm 2>/dev/null || true
            sudo pacman -Syu --noconfirm
            ;;
        alpine) sudo apk update && sudo apk upgrade ;;
    esac

    ensure_fresh_editor
    ensure_atuin

    log_success "System packages updated"
}

show_summary() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                     Update Complete!                         ║"
    echo "║                                                              ║"
    echo "║  ✅ Dotfiles repository updated                              ║"
    echo "║  ✅ Configuration files symlinked                            ║"
    echo "║                                                              ║"
    echo "║  Next steps:                                                 ║"
    echo "║  1. Run 'source ~/.zshrc' if not automatically reloaded      ║"
    echo "║  2. Enjoy your modular dotfiles!                             ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

main() {
    local update_tools_flag=false
    local force_update=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --tools|-t)
                update_tools_flag=true
                shift
                ;;
            --force|-f|--yes|-y)
                force_update=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo "  -t, --tools    Also update system tools and packages"
                echo "  -f, --force    Force update without confirmation"
                echo "  -y, --yes      Alias for --force"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
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
        sync_manifest_packages
    fi
    
    show_summary
    
    # Reload zsh
    if [[ -n "$ZSH_VERSION" ]]; then
        log_info "Reloading ZSH configuration..."
        source ~/.zshrc
    fi
}

main "$@"