#!/usr/bin/env bash
# ============================================================================
# Universal Dotfiles Update Script (Optimized)
# ============================================================================

set -e

# ... (Keep your color definitions, logging functions, and detect_os function here)

DOTFILES_DIR="$HOME/.dotfiles"

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
        [[ -f "$HOME/.zshrc" ]] && mv "$HOME/.zshrc" "$backup_dir/"
        ln -sf "$DOTFILES_DIR/configs/zsh/zshrc" "$HOME/.zshrc"
        ((updated++))
    fi

    # Backup & Copy Starship
    if [[ -f "$DOTFILES_DIR/configs/starship.toml" ]]; then
        [[ -f "$HOME/.config/starship.toml" ]] && mv "$HOME/.config/starship.toml" "$backup_dir/"
        ln -sf "$DOTFILES_DIR/configs/starship.toml" "$HOME/.config/starship.toml"
        ((updated++))
    fi

    # Cleanup backup dir if empty
    rmdir "$backup_dir" 2>/dev/null || log_info "Old configs backed up to $backup_dir"
    log_success "$updated core configuration files linked."
}

# ... (Keep your update_tools and show_summary functions here)

main() {
    # ... (Keep your arg parsing and confirmation logic here)
    
    detect_os
    check_dotfiles_dir
    update_repository
    update_configs
    
    if [[ "$update_tools_flag" == true ]]; then update_tools; fi
    show_summary
    
    if [[ -n "$ZSH_VERSION" ]]; then
        source ~/.zshrc
    fi
}

main "$@"