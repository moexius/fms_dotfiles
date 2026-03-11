# ============================================================================
# UNIVERSAL FUNCTIONS
# ============================================================================

function mkcd() {
    if [ $# -ne 1 ]; then echo "Usage: mkcd <directory_name>"; return 1; fi
    mkdir -p "$1" && cd "$1"
}

function weather() {
    local city="${1:-Madrid}"
    curl -s "wttr.in/${city}?format=3"
}

# Find files by name (Optimized to use fd if available)
function ff() {
    local file
    if command -v fd >/dev/null 2>&1; then
        file=$(fd --type f --hidden --exclude .git 2>/dev/null | fzf --prompt="Find file: " --preview="bat --color=always --line-range :20 {} 2>/dev/null || head -20 {}")
    else
        file=$(find . -type f 2>/dev/null | fzf --prompt="Find file: " --preview="head -20 {}")
    fi
    [ -n "$file" ] && echo "$file"
}

# Find directories (Optimized to use fd if available)
function fd_dir() {
    local dir
    if command -v fd >/dev/null 2>&1; then
        dir=$(fd --type d --hidden --exclude .git 2>/dev/null | fzf --prompt="Find directory: ")
    else
        dir=$(find . -type d 2>/dev/null | fzf --prompt="Find directory: ")
    fi
    [ -n "$dir" ] && cd "$dir"
}

# Modern Extractor Tool
function extract() {
    if [ $# -ne 1 ]; then echo "Usage: extract <archive_file>"; return 1; fi
    if [ ! -f "$1" ]; then echo "Error: '$1' is not a valid file"; return 1; fi
    
    local filename=$(basename "$1")
    local folder_name="${filename%.*}"
    [[ "$filename" == *.tar.* ]] && folder_name="${filename%.tar.*}"
    
    # Handle existing directories
    local counter=1
    local original_folder_name="$folder_name"
    while [ -d "$folder_name" ]; do
        folder_name="${original_folder_name}_${counter}"
        ((counter++))
    done
    
    mkdir -p "$folder_name"
    echo "Extracting '$1' to folder '$folder_name'..."

    # Use modern extractors if available for speed and wider format support
    if command -v bsdtar >/dev/null 2>&1; then
        bsdtar -xf "$1" -C "$folder_name"
    elif command -v 7z >/dev/null 2>&1 && [[ "$1" != *.tar.* ]]; then
        7z x "$1" -o"$folder_name"
    else
        # Fallback to standard tools
        case "$1" in
            *.tar.bz2|*.tbz2) tar xjf "$1" -C "$folder_name" ;;
            *.tar.gz|*.tgz)   tar xzf "$1" -C "$folder_name" ;;
            *.tar.xz)         tar xJf "$1" -C "$folder_name" ;;
            *.bz2)            cp "$1" "$folder_name/" && (cd "$folder_name" && bunzip2 "$(basename "$1")") ;;
            *.rar)            unrar x "$1" "$folder_name/" ;;
            *.gz)             cp "$1" "$folder_name/" && (cd "$folder_name" && gunzip "$(basename "$1")") ;;
            *.tar)            tar xf "$1" -C "$folder_name" ;;
            *.zip)            unzip "$1" -d "$folder_name" ;;
            *.Z)              cp "$1" "$folder_name/" && (cd "$folder_name" && uncompress "$(basename "$1")") ;;
            *)                echo "Error: Format not supported."; rmdir "$folder_name" 2>/dev/null; return 1 ;;
        esac
    fi
    echo "Successfully extracted to '$folder_name/'"
}

# System Information
function sysinfo() {
    local icon
    local distro_info=""
    
    case $ENVIRONMENT in
        "container") icon="📦" ;;
        "macos") icon="🍎" ;;
        *) 
            icon="🐧"
            if [[ "$IS_CACHYOS" == "true" ]]; then
                icon="🚀"
                distro_info=" (CachyOS - Performance Optimized)"
            fi
            ;;
    esac
    
    echo "$icon System Information ($ENVIRONMENT)$distro_info"
    echo "================================"
    echo "OS: $(uname -s) $(uname -r)"
    echo "Hostname: $(hostname)"
    
    if [[ "$ENVIRONMENT" == "macos" ]]; then
        echo "macOS Version: $(sw_vers -productVersion)"
        echo "Uptime: $(uptime | awk '{print $3,$4}' | sed 's/,//')"
    else
        echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
        free -h 2>/dev/null || echo "Memory info not available"
    fi
    
    echo "Disk Usage:"
    df -h | head -5
}

# Find and kill process by name with fzf
function killp() {
    if [ $# -eq 0 ]; then echo "Usage: killp <process_name_pattern>"; return 1; fi
    local pid
    pid=$(ps aux | grep -i "$1" | grep -v grep | fzf --prompt="Select process to kill: " | awk '{print $2}')
    if [ -n "$pid" ]; then
        kill -9 "$pid" && echo "Process killed successfully" || echo "Failed to kill process"
    fi
}

# Git branch switcher with fzf
function fzf_git_branch() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then echo "Not in a git repository"; return 1; fi
    local branch
    branch=$(git branch -a | grep -v HEAD | sed 's/^..//' | sed 's/remotes\///' | sort -u | fzf --prompt="Switch to branch: ")
    [ -n "$branch" ] && git checkout "$branch"
}

# Docker container management
function docker_exec() {
    if ! command -v docker >/dev/null 2>&1; then echo "Docker not installed"; return 1; fi
    local container
    container=$(docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | fzf --header-lines=1 --prompt="Select container: " | awk '{print $1}')
    if [ -n "$container" ]; then
        docker exec -it "$container" /bin/bash || docker exec -it "$container" /bin/sh
    fi
}

# History search with fzf
function fzf_history() {
    local selected
    selected=$(history | fzf --tac --no-sort --height 40% --reverse --border | sed 's/^[ ]*[0-9]*[ ]*//')
    [ -n "$selected" ] && print -z "$selected"
}

# ============================================================================
# CACHYOS SPECIFIC FUNCTIONS
# ============================================================================
if [[ "$IS_CACHYOS" == "true" ]]; then
    function set_performance() {
        if command -v cpupower >/dev/null 2>&1; then
            sudo cpupower frequency-set -g performance
            echo "🚀 CPU governor set to performance mode"
        fi
    }
    
    function set_powersave() {
        if command -v cpupower >/dev/null 2>&1; then
            sudo cpupower frequency-set -g powersave
            echo "🔋 CPU governor set to powersave mode"
        fi
    }
    
    function cachy_maintenance() {
        echo "🔧 Running CachyOS system maintenance..."
        sudo pacman -Sy cachyos-keyring --noconfirm 2>/dev/null || true
        sudo pacman -Syu
        sudo pacman -Sc --noconfirm
        local orphans=$(pacman -Qtdq 2>/dev/null)
        [[ -n "$orphans" ]] && sudo pacman -Rns $orphans
        sudo updatedb 2>/dev/null || echo "updatedb not available"
        echo "✅ CachyOS maintenance completed!"
    }
    
    alias cm='cachy_maintenance'
    alias perf='set_performance'
    alias power='set_powersave'
fi

# ============================================================================
# OPENSUSE SPECIFIC FUNCTIONS
# ============================================================================
if [[ "$DETECTED_OS" == "opensuse" ]]; then
    zinstall() {
        if [ $# -eq 0 ]; then echo "Usage: zinstall <search_term>"; return 1; fi
        zypper search "$1"
        read -p "Enter package name to install (or press Enter to cancel): " package
        [ -n "$package" ] && sudo zypper install "$package"
    }
    
    cleanup() {
        sudo zypper clean -a
        sudo zypper packages --orphaned
        sudo journalctl --vacuum-time=2weeks
        echo "Cleanup completed!"
    }
fi