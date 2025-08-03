#!/usr/bin/env bash
# ============================================================================
# Dotfiles Update Script
# ============================================================================

set -e

DOTFILES_DIR="$HOME/.dotfiles"

log_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
log_success() { echo -e "\033[0;32m[SUCCESS]\033[0m $1"; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

if [[ ! -d "$DOTFILES_DIR" ]]; then
    log_error "Dotfiles directory not found. Please run the installer first."
    exit 1
fi

log_info "Updating dotfiles..."
cd "$DOTFILES_DIR"
git pull origin main

log_info "Updating configurations..."
cp "$DOTFILES_DIR/configs/zshrc" "$HOME/.zshrc"
cp "$DOTFILES_DIR/configs/starship.toml" "$HOME/.config/starship.toml"

log_success "Dotfiles updated successfully!"
log_info "Please restart your terminal or run: source ~/.zshrc"