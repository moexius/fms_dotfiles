# ============================================================================
# ALIAS SEARCH AND HELP SYSTEM
# ============================================================================
alias_help() {
    echo "🔍 Alias Search and Help System\n================================"
    echo "\nUsage:"
    echo "  alias_search <term>     - Search for aliases containing term"
    echo "  alias_list [category]   - List aliases by category"
    echo "  alias_os               - Show OS-specific aliases"
    echo "\nCategories:"
    echo "  package, system, service, network, file, git, dev, docker, misc"
    [[ "$IS_CACHYOS" == "true" ]] && echo "  cachyos    - CachyOS specific commands"
}

alias_search() {
    if [ $# -eq 0 ]; then echo "Usage: alias_search <search_term>"; return 1; fi
    echo "🔍 Searching for aliases containing '$1':"
    alias | grep -i "$1" | sort | sed 's/^/  /'
}

alias_list() {
    local category="$1"
    case "$category" in
        package) echo "📦 Package Aliases:"; alias | grep -E "(install|remove|update|upgrade|search|clean|brew|apt|dnf|yum|zypper|pacman|apk)" | sort | sed 's/^/  /' ;;
        system) echo "🖥️ System Aliases:"; alias | grep -E "(info|cpu|mem|disk|temp|battery|df|du|free|top|ps)" | sort | sed 's/^/  /' ;;
        service) echo "⚙️ Service Aliases:"; alias | grep -E "(start|stop|restart|status|enable|disable|systemctl|service)" | sort | sed 's/^/  /' ;;
        network) echo "🌐 Network Aliases:"; alias | grep -E "(ping|ip|port|connection|myip|localip|netstat|ss)" | sort | sed 's/^/  /' ;;
        file) echo "📁 File Aliases:"; alias | grep -E "(ls|ll|la|cp|mv|rm|mkdir|tar|extract)" | sort | sed 's/^/  /' ;;
        git) echo "🔧 Git Aliases:"; alias | grep -E "git|^g[a-z]=" | sort | sed 's/^/  /' ;;
        dev) echo "💻 Development Aliases:"; alias | grep -E "(python|pip|node|npm|serve|json|vim|nvim)" | sort | sed 's/^/  /' ;;
        docker) echo "🐳 Docker Aliases:"; alias | grep -E "docker|^d[a-z]=" | sort | sed 's/^/  /' ;;
        cachyos) [[ "$IS_CACHYOS" == "true" ]] && { echo "🚀 CachyOS Aliases:"; alias | grep -E "(cachy|kernel|perf|governor)" | sort | sed 's/^/  /'; } || echo "❌ CachyOS aliases only available on CachyOS systems" ;;
        misc) echo "🔧 Misc Aliases:"; alias | grep -E "(weather|clear|history|reload|sa)" | sort | sed 's/^/  /' ;;
        *) echo "📋 Categories: package, system, service, network, file, git, dev, docker, misc"; [[ "$IS_CACHYOS" == "true" ]] && echo "  cachyos"; echo "\nUse: alias_list <category>" ;;
    esac
}

alias_os() {
    echo "🖥️  Current OS: $DETECTED_OS\n📦 Package Manager: $PKG_MANAGER"
    [[ "$IS_CACHYOS" == "true" ]] && echo "🚀 CachyOS Features: Enabled"
    echo "\nOS-Specific Aliases Available:\n============================="
    case "$DETECTED_OS" in
        macos) echo "  🍎 macOS aliases loaded"; alias | grep -E "(brew|darwin|mac|launchctl)" | sort | sed 's/^/    /' ;;
        debian) echo "  🐧 Debian/Ubuntu aliases loaded"; alias | grep -E "(apt|dpkg)" | sort | sed 's/^/    /' ;;
        fedora|rhel) echo "  🎩 Fedora/RHEL aliases loaded"; alias | grep -E "(dnf|yum|rpm)" | sort | sed 's/^/    /' ;;
        opensuse) echo "  🦎 openSUSE aliases loaded"; alias | grep -E "(zypper|yast|snap)" | sort | sed 's/^/    /' ;;
        arch) [[ "$IS_CACHYOS" == "true" ]] && { echo "  🚀 CachyOS aliases loaded"; alias | grep -E "(pacman|yay|aur|cachy|kernel|perf)" | sort | sed 's/^/    /'; } || { echo "  🏛️ Arch Linux aliases loaded"; alias | grep -E "(pacman|yay|aur)" | sort | sed 's/^/    /'; } ;;
        alpine) echo "  🏔️ Alpine Linux aliases loaded"; alias | grep -E "(apk)" | sort | sed 's/^/    /' ;;
        *) echo "  ❓ Unknown OS - using generic aliases" ;;
    esac
}

alias ah='alias_help'
alias as='alias_search'
alias al='alias_list'
alias ao='alias_os'

# ============================================================================
# UNIVERSAL ALIASES - NAVIGATION & BASIC COMMANDS
# ============================================================================
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias h="cd ~"
alias c="clear"
alias cls="clear"

if command -v lsd >/dev/null 2>&1; then
    alias ls="lsd"
    alias l="lsd -la"
    alias ll="lsd -l"
    alias la="lsd -la"
    alias lt="lsd --tree"
    alias lsize="lsd -lS"
else
    if [[ "$ENVIRONMENT" == "macos" ]]; then
        alias ls="ls -G"
        alias l="ls -la -G"
        alias ll="ls -l -G"
        alias la="ls -la -G"
    else
        alias ls="ls --color=auto"
        alias l="ls -la --color=auto"
        alias ll="ls -l --color=auto"
        alias la="ls -la --color=auto"
    fi
    alias lsize="ls -lhS"
fi

alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias rmf='rm -rf'
alias ln='ln -iv'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias h='history'
alias hgrep='history | grep'
alias count='sort | uniq -c | sort -nr'

# ============================================================================
# UNIVERSAL ALIASES - SYSTEM MONITORING
# ============================================================================
alias df="df -h"
alias du="du -h"
alias dus='du -sh * | sort -hr'
alias free='free -h'
alias ps='ps aux'
alias psg='ps aux | grep -v grep | grep -i'
alias topcpu='ps auxf | sort -nr -k 3 | head -10'
alias topmem='ps auxf | sort -nr -k 4 | head -10'

if [[ "$ENVIRONMENT" == "macos" ]]; then
    alias cpu="top -o cpu"
    alias mem="top -o mem"
    alias ports="lsof -i -P -n | grep LISTEN"
else
    alias cpu="top -o %CPU"
    alias mem="top -o %MEM"
    alias ports="ss -tuln"
fi

# ============================================================================
# UNIVERSAL ALIASES - NETWORK
# ============================================================================
alias ping="ping -c 5"
alias myip="curl -s [https://icanhazip.com](https://icanhazip.com) && echo"

if [[ "$ENVIRONMENT" == "macos" ]]; then
    alias localip="ipconfig getifaddr en0"
    alias rwlan="networksetup -setairportpower en0 off && networksetup -setairportpower en0 on"
else
    alias localip="hostname -I | awk '{print \$1}'"
fi

alias listening='netstat -tlnp'
alias connections='netstat -an'

# ============================================================================
# UNIVERSAL ALIASES - DEVELOPMENT
# ============================================================================
if command -v bat >/dev/null 2>&1; then
    alias b="bat"
elif command -v batcat >/dev/null 2>&1; then
    alias b="batcat"
else
    alias b="cat"
fi

alias t="tldr"
alias f="fzf"

alias nano="fresh"

alias g="git"
alias gs="git status"
alias ga="git add"
alias gaa="git add --all"
alias gc="git commit"
alias gcm="git commit -m"
alias gp="git push"
alias gpl="git pull"
alias gl="git log --oneline"
alias gd="git diff"
alias gb="git branch"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gm="git merge"
alias gr="git remote -v"
alias gf="git fetch"

alias py='python3'
alias pip='pip3'
alias serve='python3 -m http.server'
alias json='python3 -m json.tool'
alias urlencode='python3 -c "import sys, urllib.parse as ul; print(ul.quote_plus(sys.argv[1]))"'
alias urldecode='python3 -c "import sys, urllib.parse as ul; print(ul.unquote_plus(sys.argv[1]))"'

alias zshrc="$EDITOR ~/.zshrc"
alias starshipconfig="$EDITOR ~/.config/starship.toml"
alias starship-config="$EDITOR ~/.config/starship.toml"

# ============================================================================
# MACOS SPECIFIC ALIASES
# ============================================================================
if [[ "$DETECTED_OS" == "macos" ]]; then
    alias bo="brew outdated && echo '\nRun bg to upgrade all packages'"
    alias bu="brew update"
    alias bg="brew upgrade"
    alias bi="brew install"
    alias bs="brew search"
    alias bl="brew list"
    alias bc="brew cleanup"
    alias buc="brew update && brew cleanup"
    alias binfo="brew info"
    alias bdeps="brew deps --tree"
    alias bservices="brew services list"
    alias bstart="brew services start"
    alias bstop="brew services stop"
    alias brestart="brew services restart"
    
    alias hosts="sudo $EDITOR /etc/hosts"
    alias vimrc="$EDITOR ~/.vimrc"
    alias flush="sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
    alias lscleanup="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder"
    alias showfiles="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
    alias hidefiles="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"
    alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"
    alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
    
    alias safari="open -a Safari"
    alias firefox="open -a Firefox"
    alias chrome="open -a 'Google Chrome'"
    alias finder="open -a Finder"
    alias preview="open -a Preview"
    
    alias startgp="launchctl load /Library/LaunchAgents/com.paloaltonetworks.gp.pangp*"
    alias stopgp="launchctl unload /Library/LaunchAgents/com.paloaltonetworks.gp.pangp*"
    alias ts="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
    
    alias battery="pmset -g batt"
    alias sleep="pmset sleepnow"
    alias lock="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"
    alias screensaver="open -a ScreenSaverEngine"
fi

# ============================================================================
# DEBIAN/UBUNTU SPECIFIC ALIASES
# ============================================================================
if [[ "$DETECTED_OS" == "debian" ]]; then
    alias upd="sudo apt update"
    alias upgrade="sudo apt upgrade"
    alias install="sudo apt install"
    alias search="apt search"
    alias show="apt show"
    alias remove="sudo apt remove"
    alias autoremove="sudo apt autoremove"
    alias purge="sudo apt purge"
    alias clean="sudo apt clean && sudo apt autoclean"
    alias installed="apt list --installed"
    alias upgradable="apt list --upgradable"
    
    alias sstart="sudo systemctl start"
    alias sstop="sudo systemctl stop"
    alias srestart="sudo systemctl restart"
    alias sstatus="systemctl status"
    alias senable="sudo systemctl enable"
    alias sdisable="sudo systemctl disable"
    alias sreload="sudo systemctl reload"
    alias slist="systemctl list-units --type=service"
    alias sfailed="systemctl --failed"
    
    alias logs="sudo journalctl -f"
    alias logsboot="sudo journalctl -b"
    alias logserr="sudo journalctl -p err"
    alias logsservice="sudo journalctl -u"
    
    alias sources="sudo $EDITOR /etc/apt/sources.list"
    alias fstab="sudo $EDITOR /etc/fstab"
    alias ufw="sudo ufw"
    alias ufwstatus="sudo ufw status"
fi

# ============================================================================
# FEDORA/RHEL SPECIFIC ALIASES
# ============================================================================
if [[ "$DETECTED_OS" == "fedora" || "$DETECTED_OS" == "rhel" ]]; then
    if [[ "$PKG_MANAGER" == "dnf" ]]; then
        alias upd="sudo dnf update"
        alias upgrade="sudo dnf upgrade"
        alias install="sudo dnf install"
        alias search="dnf search"
        alias info="dnf info"
        alias remove="sudo dnf remove"
        alias autoremove="sudo dnf autoremove"
        alias clean="sudo dnf clean all"
        alias history="dnf history"
        alias installed="dnf list installed"
        alias available="dnf list available"
    else
        alias upd="sudo yum update"
        alias upgrade="sudo yum upgrade"
        alias install="sudo yum install"
        alias search="yum search"
        alias info="yum info"
        alias remove="sudo yum remove"
        alias clean="sudo yum clean all"
        alias history="yum history"
        alias installed="yum list installed"
        alias available="yum list available"
    fi
    
    alias sstart="sudo systemctl start"
    alias sstop="sudo systemctl stop"
    alias srestart="sudo systemctl restart"
    alias sstatus="systemctl status"
    alias senable="sudo systemctl enable"
    alias sdisable="sudo systemctl disable"
    alias sreload="sudo systemctl reload"
    alias slist="systemctl list-units --type=service"
    alias sfailed="systemctl --failed"
    
    alias logs="sudo journalctl -f"
    alias logsboot="sudo journalctl -b"
    alias logserr="sudo journalctl -p err"
    alias logsservice="sudo journalctl -u"
    
    alias fwstatus="sudo firewall-cmd --state"
    alias fwlist="sudo firewall-cmd --list-all"
    alias fwreload="sudo firewall-cmd --reload"
fi

# ============================================================================
# OPENSUSE SPECIFIC ALIASES
# ============================================================================
if [[ "$DETECTED_OS" == "opensuse" ]]; then
    alias zr='sudo zypper refresh'
    alias zu='sudo zypper update'
    alias zup='sudo zypper dup'
    alias zi='sudo zypper install'
    alias zs='zypper search'
    alias zinfo='zypper info'
    alias zrm='sudo zypper remove'
    alias zps='zypper ps'
    alias zpatches='sudo zypper patches'
    alias zpatch='sudo zypper patch'
    alias zrepos='zypper repos'
    alias zaddrepo='sudo zypper addrepo'
    alias zremoverepo='sudo zypper removerepo'
    alias zclean='sudo zypper clean'
    alias zhistory='zypper history'
    
    alias install='sudo zypper install'
    alias remove='sudo zypper remove'
    alias search='zypper search'
    alias upd='sudo zypper update'
    alias upgrade='sudo zypper dup'
    alias refresh='sudo zypper refresh'
    
    alias sstart='sudo systemctl start'
    alias sstop='sudo systemctl stop'
    alias srestart='sudo systemctl restart'
    alias sstatus='systemctl status'
    alias senable='sudo systemctl enable'
    alias sdisable='sudo systemctl disable'
    alias sreload='sudo systemctl reload'
    alias slist='systemctl list-units --type=service'
    alias sfailed='systemctl --failed'
    
    alias logs='sudo journalctl -f'
    alias logsboot='sudo journalctl -b'
    alias logserr='sudo journalctl -p err'
    alias logsservice='sudo journalctl -u'
    
    alias yast='sudo yast2'
    alias yastnet='sudo yast2 lan'
    alias yastuser='sudo yast2 users'
    alias yastsoft='sudo yast2 sw_single'
    alias yastboot='sudo yast2 bootloader'
    
    alias snaplist='sudo snapper list'
    alias snapcreate='sudo snapper create -d'
    alias snapdelete='sudo snapper delete'
    alias snapstatus='sudo snapper status'
    
    alias fwstatus='sudo firewall-cmd --state'
    alias fwlist='sudo firewall-cmd --list-all'
    alias fwreload='sudo firewall-cmd --reload'
fi

# ============================================================================
# ARCH LINUX / CACHYOS SPECIFIC ALIASES
# ============================================================================
if [[ "$DETECTED_OS" == "arch" ]]; then
    alias upd="sudo pacman -Sy"
    alias upgrade="sudo pacman -Syu"
    alias install="sudo pacman -S"
    alias search="pacman -Ss"
    alias info="pacman -Si"
    alias remove="sudo pacman -R"
    alias removeall="sudo pacman -Rns"
    alias clean="sudo pacman -Sc"
    alias cleanall="sudo pacman -Scc"
    alias installed="pacman -Q"
    alias orphans="pacman -Qdt"
    alias removeorphans="sudo pacman -Rns \$(pacman -Qtdq)"
    
    if command -v yay >/dev/null 2>&1; then
        alias yayupdate="yay -Syu"
        alias yayinstall="yay -S"
        alias yaysearch="yay -Ss"
        alias yayremove="yay -R"
        alias yayclean="yay -Sc"
    fi
    
    alias sstart="sudo systemctl start"
    alias sstop="sudo systemctl stop"
    alias srestart="sudo systemctl restart"
    alias sstatus="systemctl status"
    alias senable="sudo systemctl enable"
    alias sdisable="sudo systemctl disable"
    alias sreload="sudo systemctl reload"
    alias slist="systemctl list-units --type=service"
    alias sfailed="systemctl --failed"
    
    alias logs="sudo journalctl -f"
    alias logsboot="sudo journalctl -b"
    alias logserr="sudo journalctl -p err"
    alias logsservice="sudo journalctl -u"
    
    if [[ "$IS_CACHYOS" == "true" ]]; then
        alias kernel-list="pacman -Q | grep -E '(linux|kernel)'"
        alias kernel-install="sudo pacman -S"
        alias kernel-remove="sudo pacman -R"
        
        alias cachy-repo="sudo pacman -Sy cachyos-keyring cachyos-mirrorlist"
        alias cachy-update="sudo pacman -Sy && sudo pacman -Su"
        
        alias perf-cpu="sudo cpupower frequency-info"
        alias perf-gov="sudo cpupower frequency-set -g"
        alias perf-sched="cat /sys/kernel/debug/sched_features 2>/dev/null || echo 'Scheduler features not available'"
        
        alias cachy-settings="cachyos-hello"
        alias cachy-kernel-manager="cachyos-kernel-manager"
        alias cachy-welcome="cachyos-hello"
        
        alias performance="sudo cpupower frequency-set -g performance && echo '🚀 Performance mode enabled'"
        alias powersave="sudo cpupower frequency-set -g powersave && echo '🔋 Powersave mode enabled'"
        alias balanced="sudo cpupower frequency-set -g schedutil && echo '⚖️  Balanced mode enabled'"
    fi
fi

# ============================================================================
# ALPINE LINUX SPECIFIC ALIASES
# ============================================================================
if [[ "$DETECTED_OS" == "alpine" ]]; then
    alias upd="sudo apk update"
    alias upgrade="sudo apk upgrade"
    alias install="sudo apk add"
    alias search="apk search"
    alias info="apk info"
    alias remove="sudo apk del"
    alias clean="sudo apk cache clean"
    alias installed="apk info -vv | sort"
    
    alias services="rc-status"
    alias addservice="sudo rc-update add"
    alias delservice="sudo rc-update del"
    alias startservice="sudo rc-service"
    alias stopservice="sudo rc-service"
fi

# ============================================================================
# DOCKER & FLATPAK ALIASES
# ============================================================================
if command -v docker >/dev/null 2>&1; then
    alias dps='docker ps'
    alias dpsa='docker ps -a'
    alias di='docker images'
    alias dstop='docker stop $(docker ps -q)'
    alias drm='docker rm $(docker ps -aq)'
    alias drmi='docker rmi $(docker images -q)'
    alias dprune='docker system prune -af'
    alias dlog='docker logs'
    alias dexec='docker exec -it'
    alias dbuild='docker build'
    alias drun='docker run'
    alias dpull='docker pull'
    alias dpush='docker push'
fi

if command -v flatpak >/dev/null 2>&1; then
    alias fplist='flatpak list'
    alias fpinstall='flatpak install'
    alias fpremove='flatpak uninstall'
    alias fpupdate='flatpak update'
    alias fpsearch='flatpak search'
    alias fprun='flatpak run'
fi

# ============================================================================
# MISCELLANEOUS ALIASES
# ============================================================================
alias now='date +"%T"'
alias nowdate='date +"%d-%m-%Y"'
alias path='echo -e ${PATH//:/\\n}'
alias j='jobs -l'
alias reload='source ~/.zshrc'
alias sa='source ~/.zshrc && echo "🚀 ZSH configuration reloaded successfully!"'

alias weather='curl wttr.in'
alias weatherlocal='curl wttr.in/$(curl -s ipinfo.io/city 2>/dev/null)'