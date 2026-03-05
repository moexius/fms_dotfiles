# Install configurations
install_configs() {
    log_info "Installing configurations..."
    
    # Create necessary directories
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.config/zsh"
    
    # Install main .zshrc via symlink
    if [[ -f "$DOTFILES_DIR/configs/zsh/zshrc" ]]; then
        # Create a symlink instead of copying so updates sync automatically
        ln -sf "$DOTFILES_DIR/configs/zsh/zshrc" "$HOME/.zshrc"
        log_success "ZSH configuration symlinked"
    else
        log_error "ZSH configuration not found in dotfiles"
        exit 1
    fi
    
    # Install starship.toml
    if [[ -f "$DOTFILES_DIR/configs/starship.toml" ]]; then
        ln -sf "$DOTFILES_DIR/configs/starship.toml" "$HOME/.config/starship.toml"
        log_success "Starship configuration symlinked"
    else
        log_error "Starship configuration not found in dotfiles"
        exit 1
    fi
    
    # Set ZSH as default shell
    set_default_shell
}