# ============================================================================
# ALIAS SEARCH AND HELP SYSTEM
# ============================================================================
alias_help() {
    echo "🔍 Alias Search and Help System\n================================"
    echo "\nUsage:"
    echo "  alias_search <term>     - Search for aliases"
    echo "  alias_list [category]   - List aliases by category"
    echo "  alias_os               - Show OS-specific aliases"
}

alias_search() {
    if [ $# -eq 0 ]; then echo "Usage: alias_search <search_term>"; return 1; fi
    echo "🔍 Searching for aliases containing '$1':"
    alias | grep -i "$1" | sort | sed 's/^/  /'
}

alias_list() {
    local category="$1"
    case "$category" in
        package) echo "📦 Package Aliases:"; alias | grep -E "(install|remove|update|brew|apt|dnf|pacman|zypper)" | sort | sed 's/^/  /' ;;
        system) echo "🖥️ System Aliases:"; alias | grep -E "(info|cpu|mem|disk|temp|df|du|free|top|ps)" | sort | sed 's/^/  /' ;;
        *) echo "📋 Categories: package, system, service, network, file, git, dev, docker, misc" ;;
    esac
}

alias_os() {
    echo "🖥️  Current OS: $DETECTED_OS\n📦 Package Manager: $PKG_MANAGER"
    case "$DETECTED_OS" in
        macos) alias | grep -E "(brew|darwin|mac|launchctl)" | sort | sed 's/^/    /' ;;
        debian) alias | grep -E "(apt|dpkg)" | sort | sed 's/^/    /' ;;
        fedora|rhel) alias | grep -E "(dnf|yum|rpm)" | sort | sed 's/^/    /' ;;
        opensuse) alias | grep -E "(zypper|yast|snap)" | sort | sed 's/^/    /' ;;
        arch) alias | grep -E "(pacman|yay|aur|cachy)" | sort | sed 's/^/    /' ;;
        *) echo "  ❓ Unknown OS - using generic aliases" ;;
    esac
}

alias ah='alias_help'
alias as='alias_search'
alias al='alias_list'
alias ao='alias_os'

# ============================================================================
# UNIVERSAL ALIASES
# ============================================================================
alias ..="cd .."
alias ...="cd ../.."
alias ~="cd ~"
alias c="clear"
alias cls="clear"
alias reload='source ~/.zshrc'
alias sa='source ~/.zshrc && echo "🚀 ZSH configuration reloaded successfully!"'

if command -v lsd >/dev/null 2>&1; then
    alias ls="lsd"
    alias l="lsd -la"
    alias ll="lsd -l"
    alias la="lsd -la"
else
    alias ls="ls --color=auto"
    alias ll="ls -l --color=auto"
    alias la="ls -la --color=auto"
fi

alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias df="df -h"
alias du="du -h"
alias free='free -h'
alias ps='ps aux'
alias ping="ping -c 5"
alias myip="curl -s https://icanhazip.com && echo"

if command -v bat >/dev/null 2>&1; then alias b="bat"
elif command -v batcat >/dev/null 2>&1; then alias b="batcat"
else alias b="cat"; fi

alias t="tldr"
alias f="fzf"

# Git
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gpl="git pull"

# Docker & Flatpak
if command -v docker >/dev/null 2>&1; then
    alias dps='docker ps'
    alias di='docker images'
    alias dbuild='docker build'
    alias drun='docker run'
fi

if command -v flatpak >/dev/null 2>&1; then
    alias fplist='flatpak list'
    alias fpinstall='flatpak install'
    alias fpupdate='flatpak update'
fi