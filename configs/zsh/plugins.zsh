# ============================================================================
# ZINIT PLUGIN MANAGER
# ============================================================================
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [[ ! -f $ZINIT_HOME/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing ZINIT…%f"
    command mkdir -p "$(dirname $ZINIT_HOME)" && command chmod g-rwX "$(dirname $ZINIT_HOME)"
    command git clone https://github.com/zdharma-continuum/zinit "$ZINIT_HOME"
fi

source "$ZINIT_HOME/zinit.zsh"

# Load plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-history-substring-search
zinit light zsh-users/zsh-completions

ZSH_AUTOCOMPLETE_LOADED=false
if ! command -v systemd-detect-virt >/dev/null 2>&1 || [[ "$(systemd-detect-virt 2>/dev/null)" != "lxc" ]]; then
    zinit light marlonrichert/zsh-autocomplete
    ZSH_AUTOCOMPLETE_LOADED=true
fi

zinit snippet OMZP::git
zinit snippet OMZP::colored-man-pages
zinit snippet OMZP::command-not-found

# ============================================================================
# STARSHIP PROMPT & TOOLS
# ============================================================================
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
    export STARSHIP_CONFIG=~/.config/starship.toml
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

if [[ "$ENVIRONMENT" == "macos" ]]; then
    test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
fi

# ============================================================================
# FZF CONFIGURATION
# ============================================================================
export FZF_DEFAULT_OPTS="
    --height 40% --reverse --border --preview-window=right:60%:wrap
    --bind='ctrl-u:preview-page-up,ctrl-d:preview-page-down'
    --color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796
    --color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6
    --color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796"

export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'

if command -v fzf >/dev/null 2>&1; then
    # Completely silence the test. If it succeeds, run it.
    if fzf --zsh >/dev/null 2>&1; then
        eval "$(fzf --zsh)"
    else
        # Fallback for older versions
        [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh 2>/dev/null
        [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh 2>/dev/null
        [ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh 2>/dev/null
    fi
fi

# ============================================================================
# COMPLETION & BINDINGS
# ============================================================================
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*' group-name ''

if [[ -n "${functions[_zsh_highlight]}" ]]; then
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    bindkey '^P' history-substring-search-up
    bindkey '^N' history-substring-search-down
fi

bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# ============================================================================
# ATUIN HISTORY (Local Only)
# ============================================================================
# We load this last so it successfully overrides the history-substring-search 
# bindings for the Up Arrow and Ctrl+R.
if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh --disable-up-arrow)"
fi

# ============================================================================
# STARTUP MESSAGE
# ============================================================================
case $ENVIRONMENT in
    "container") echo "📦 Container ZSH loaded successfully!" ;;
    "macos") echo "🍎 macOS ZSH loaded successfully!" ;;
    *) [[ "$IS_CACHYOS" == "true" ]] && echo "🚀 CachyOS ZSH loaded successfully!" || echo "🐧 Linux ZSH loaded successfully!" ;;
esac