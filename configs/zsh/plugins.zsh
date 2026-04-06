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
    if fzf --zsh >/dev/null 2>&1; then
        eval "$(fzf --zsh)"
    else
        [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh 2>/dev/null
        [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh 2>/dev/null
        [ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh 2>/dev/null
    fi
    # Immediately reassign ^R to Alt+R BEFORE Atuin loads
    bindkey '^[r' fzf-history-widget
    bindkey -r '^r'  # unbind Ctrl+R from FZF now
fi

# ============================================================================
# ATUIN HISTORY (Local Only) — must load AFTER FZF to win the ^R binding
# ============================================================================
if command -v atuin >/dev/null 2>&1; then
    export ATUIN_NOBIND="true"
    eval "$(atuin init zsh)"

    local atuin_w="atuin-search"
    if [[ -z "${widgets[$atuin_w]}" ]]; then
        atuin_w="_atuin_search_widget"
    fi

    bindkey -M emacs '^r' $atuin_w
    bindkey -M viins '^r' $atuin_w
    bindkey -M vicmd '^r' $atuin_w
    bindkey '^r' $atuin_w
fi
# Note: Alt+R for FZF is already bound above — no second assignment needed here

# ============================================================================
# STARTUP MESSAGE
# ============================================================================
case $ENVIRONMENT in
    "container") echo "📦 Container ZSH loaded successfully!" ;;
    "macos") echo "🍎 macOS ZSH loaded successfully!" ;;
    *) [[ "$IS_CACHYOS" == "true" ]] && echo "🚀 CachyOS ZSH loaded successfully!" || echo "🐧 Linux ZSH loaded successfully!" ;;
esac