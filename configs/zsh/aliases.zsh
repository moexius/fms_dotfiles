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

if command -v lsd >/dev/null 2>&1; then [cite: 74]
    alias ls="lsd"
    alias l="lsd -la"
    alias ll="lsd -l"
    alias la="lsd -la"
    alias lt="lsd --tree"
    alias lsize="lsd -lS"
else
    if [[ "$ENVIRONMENT" == "macos" ]]; then [cite: 75]
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
    alias lsize="ls -lhS" [cite: 76]
fi

alias mkdir='mkdir -pv' [cite: 76]
alias cp='cp -iv' [cite: 76]
alias mv='mv -iv' [cite: 76]
alias rm='rm -iv' [cite: 76]
alias rmf='rm -rf' [cite: 76]
alias ln='ln -iv' [cite: 76]

alias grep='grep --color=auto' [cite: 76]
alias fgrep='fgrep --color=auto' [cite: 76]
alias egrep='egrep --color=auto' [cite: 76]
alias h='history' [cite: 76]
alias hgrep='history | grep' [cite: 76, 77]
alias count='sort | uniq -c | sort -nr' [cite: 77]

# ============================================================================
# UNIVERSAL ALIASES - SYSTEM MONITORING
# ============================================================================
alias df="df -h" [cite: 77]
alias du="du -h" [cite: 77]
alias dus='du -sh * | sort -hr' [cite: 77, 78]
alias free='free -h' [cite: 78]
alias ps='ps aux' [cite: 78]
alias psg='ps aux | grep -v grep | grep -i' [cite: 78]
alias topcpu='ps auxf | sort -nr -k 3 | head -10' [cite: 78, 79]
alias topmem='ps auxf | sort -nr -k 4 | head -10' [cite: 79, 80]

if [[ "$ENVIRONMENT" == "macos" ]]; then [cite: 80]
    alias cpu="top -o cpu" [cite: 81]
    alias mem="top -o mem" [cite: 81]
    alias ports="lsof -i -P -n | grep LISTEN" [cite: 81]
else
    alias cpu="top -o %CPU" [cite: 81]
    alias mem="top -o %MEM" [cite: 81]
    alias ports="ss -tuln" [cite: 81]
fi

# ============================================================================
# UNIVERSAL ALIASES - NETWORK
# ============================================================================
alias ping="ping -c 5" [cite: 81]
alias myip="curl -s https://icanhazip.com && echo" [cite: 81]

if [[ "$ENVIRONMENT" == "macos" ]]; then [cite: 81]
    alias localip="ipconfig getifaddr en0" [cite: 82]
    alias rwlan="networksetup -setairportpower en0 off && networksetup -setairportpower en0 on" [cite: 82]
else
    alias localip="hostname -I | awk '{print \$1}'" [cite: 82]
fi

alias listening='netstat -tlnp' [cite: 82]
alias connections='netstat -an' [cite: 82]

# ============================================================================
# UNIVERSAL ALIASES - DEVELOPMENT
# ============================================================================
if command -v bat >/dev/null 2>&1; then [cite: 82]
    alias b="bat" [cite: 83]
elif command -v batcat >/dev/null 2>&1; then [cite: 83]
    alias b="batcat" [cite: 84]
else
    alias b="cat" [cite: 84]
fi

alias t="tldr" [cite: 84]
alias f="fzf" [cite: 84]

alias g="git" [cite: 84]
alias gs="git status" [cite: 84]
alias ga="git add" [cite: 84]
alias gaa="git add --all" [cite: 84]
alias gc="git commit" [cite: 84]
alias gcm="git commit -m" [cite: 84]
alias gp="git push" [cite: 84]
alias gpl="git pull" [cite: 84]
alias gl="git log --oneline" [cite: 84]
alias gd="git diff" [cite: 84]
alias gb="git branch" [cite: 84]
alias gco="git checkout" [cite: 84]
alias gcb="git checkout -b" [cite: 84]
alias gm="git merge" [cite: 84]
alias gr="git remote -v" [cite: 84]
alias gf="git fetch" [cite: 84]

alias py='python3' [cite: 84]
alias pip='pip3' [cite: 84]
alias serve='python3 -m http.server' [cite: 84]
alias json='python3 -m json.tool' [cite: 84]
alias urlencode='python3 -c "import sys, urllib.parse as ul; print(ul.quote_plus(sys.argv[1]))"' [cite: 84]
alias urldecode='python3 -c "import sys, urllib.parse as ul; print(ul.unquote_plus(sys.argv[1]))"' [cite: 84]

alias zshrc="$EDITOR ~/.zshrc" [cite: 84]
alias starshipconfig="$EDITOR ~/.config/starship.toml" [cite: 84]
alias starship-config="$EDITOR ~/.config/starship.toml" [cite: 84]

# ============================================================================
# MACOS SPECIFIC ALIASES
# ============================================================================
if [[ "$DETECTED_OS" == "macos" ]]; then [cite: 84]
    alias bo="brew outdated && echo '\nRun bg to upgrade all packages'" [cite: 85]
    alias bu="brew update" [cite: 85]
    alias bg="brew upgrade" [cite: 85]
    alias bi="brew install" [cite: 85]
    alias bs="brew search" [cite: 85]
    alias bl="brew list" [cite: 85]
    alias bc="brew cleanup" [cite: 85]
    alias buc="brew update && brew cleanup" [cite: 85]
    alias binfo="brew info" [cite: 85]
    alias bdeps="brew deps --tree" [cite: 85]
    alias bservices="brew services list" [cite: 85]
    alias bstart="brew services start" [cite: 85]
    alias bstop="brew services stop" [cite: 85]
    alias brestart="brew services restart" [cite: 86]
    
    alias hosts="sudo $EDITOR /etc/hosts" [cite: 86]
    alias vimrc="$EDITOR ~/.vimrc" [cite: 86]
    alias flush="sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder" [cite: 86]
    alias lscleanup="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder" [cite: 86]
    alias showfiles="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder" [cite: 86]
    alias hidefiles="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder" [cite: 86]
    alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder" [cite: 86]
    alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder" [cite: 87]
    
    alias safari="open -a Safari" [cite: 87]
    alias firefox="open -a Firefox" [cite: 87]
    alias chrome="open -a 'Google Chrome'" [cite: 87]
    alias finder="open -a Finder" [cite: 87]
    alias preview="open -a Preview" [cite: 87]
    
    alias startgp="launchctl load /Library/LaunchAgents/com.paloaltonetworks.gp.pangp*" [cite: 87]
    alias stopgp="launchctl unload /Library/LaunchAgents/com.paloaltonetworks.gp.pangp*" [cite: 87]
    alias ts="/Applications/Tailscale.app/Contents/MacOS/Tailscale" [cite: 87]
    
    alias battery="pmset -g batt" [cite: 88]
    alias sleep="pmset sleepnow" [cite: 88]
    alias lock="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend" [cite: 88]
    alias screensaver="open -a ScreenSaverEngine" [cite: 88]
fi

# ============================================================================
# DEBIAN/UBUNTU SPECIFIC ALIASES
# ============================================================================
if [[ "$DETECTED_OS" == "debian" ]]; then [cite: 88]
    alias upd="sudo apt update" [cite: 89]
    alias upgrade="sudo apt upgrade" [cite: 89]
    alias install="sudo apt install" [cite: 89]
    alias search="apt search" [cite: 89]
    alias show="apt show" [cite: 89]
    alias remove="sudo apt remove" [cite: 89]
    alias autoremove="sudo apt autoremove" [cite: 89]
    alias purge="sudo apt purge" [cite: 89]
    alias clean="sudo apt clean && sudo apt autoclean" [cite: 89]
    alias installed="apt list --installed" [cite: 89]
    alias upgradable="apt list --upgradable" [cite: 89]
    
    alias sstart="sudo systemctl start" [cite: 90]
    alias sstop="sudo systemctl stop" [cite: 90]
    alias srestart="sudo systemctl restart" [cite: 90]
    alias sstatus="systemctl status" [cite: 90]
    alias senable="sudo systemctl enable" [cite: 90]
    alias sdisable="sudo systemctl disable" [cite: 90]
    alias sreload="sudo systemctl reload" [cite: 90]
    alias slist="systemctl list-units --type=service" [cite: 90]
    alias sfailed="systemctl --failed" [cite: 90]
    
    alias logs="sudo journalctl -f" [cite: 90]
    alias logsboot="sudo journalctl -b" [cite: 90]
    alias logserr="sudo journalctl -p err" [cite: 90]
    alias logsservice="sudo journalctl -u" [cite: 90]
    
    alias sources="sudo $EDITOR /etc/apt/sources.list" [cite: 91]
    alias fstab="sudo $EDITOR /etc/fstab" [cite: 91]
    alias ufw="sudo ufw" [cite: 91]
    alias ufwstatus="sudo ufw status" [cite: 91]
fi

# ============================================================================
# FEDORA/RHEL SPECIFIC ALIASES
# ============================================================================
if [[ "$DETECTED_OS" == "fedora" || "$DETECTED_OS" == "rhel" ]]; then [cite: 91, 92]
    if [[ "$PKG_MANAGER" == "dnf" ]]; then [cite: 92]
        alias upd="sudo dnf update" [cite: 93]
        alias upgrade="sudo dnf upgrade" [cite: 93]
        alias install="sudo dnf install" [cite: 93]
        alias search="dnf search" [cite: 93]
        alias info="dnf info" [cite: 93]
        alias remove="sudo dnf remove" [cite: 93]
        alias autoremove="sudo dnf autoremove" [cite: 93]
        alias clean="sudo dnf clean all" [cite: 93]
        alias history="dnf history" [cite: 93]
        alias installed="dnf list installed" [cite: 94]
        alias available="dnf list available" [cite: 94]
    else
        alias upd="sudo yum update" [cite: 94]
        alias upgrade="sudo yum upgrade" [cite: 94]
        alias install="sudo yum install" [cite: 94]
        alias search="yum search" [cite: 94]
        alias info="yum info" [cite: 94]
        alias remove="sudo yum remove" [cite: 94]
        alias clean="sudo yum clean all" [cite: 94]
        alias history="yum history" [cite: 95]
        alias installed="yum list installed" [cite: 95]
        alias available="yum list available" [cite: 95]
    fi
    
    alias sstart="sudo systemctl start" [cite: 95]
    alias sstop="sudo systemctl stop" [cite: 95]
    alias srestart="sudo systemctl restart" [cite: 95]
    alias sstatus="systemctl status" [cite: 95]
    alias senable="sudo systemctl enable" [cite: 95]
    alias sdisable="sudo systemctl disable" [cite: 95]
    alias sreload="sudo systemctl reload" [cite: 95]
    alias slist="systemctl list-units --type=service" [cite: 96]
    alias sfailed="systemctl --failed" [cite: 96]
    
    alias logs="sudo journalctl -f" [cite: 96]
    alias logsboot="sudo journalctl -b" [cite: 96]
    alias logserr="sudo journalctl -p err" [cite: 96]
    alias logsservice="sudo journalctl -u" [cite: 96]
    
    alias fwstatus="sudo firewall-cmd --state" [cite: 96]
    alias fwlist="sudo firewall-cmd --list-all" [cite: 96]
    alias fwreload="sudo firewall-cmd --reload" [cite: 96]
fi

# ============================================================================
# OPENSUSE SPECIFIC ALIASES
# ============================================================================
if [[ "$DETECTED_OS" == "opensuse" ]]; then [cite: 96]
    alias zr='sudo zypper refresh' [cite: 97]
    alias zu='sudo zypper update' [cite: 97]
    alias zup='sudo zypper dup' [cite: 97]
    alias zi='sudo zypper install' [cite: 97]
    alias zs='zypper search' [cite: 97]
    alias zinfo='zypper info' [cite: 97]
    alias zrm='sudo zypper remove' [cite: 97]
    alias zps='zypper ps' [cite: 97]
    alias zpatches='sudo zypper patches' [cite: 97]
    alias zpatch='sudo zypper patch' [cite: 97]
    alias zrepos='zypper repos' [cite: 97]
    alias zaddrepo='sudo zypper addrepo' [cite: 97]
    alias zremoverepo='sudo zypper removerepo' [cite: 97]
    alias zclean='sudo zypper clean' [cite: 97, 98]
    alias zhistory='zypper history' [cite: 98]
    
    alias install='sudo zypper install' [cite: 98]
    alias remove='sudo zypper remove' [cite: 98]
    alias search='zypper search' [cite: 98]
    alias upd='sudo zypper update' [cite: 98]
    alias upgrade='sudo zypper dup' [cite: 98]
    alias refresh='sudo zypper refresh' [cite: 98]
    
    alias sstart='sudo systemctl start' [cite: 98]
    alias sstop='sudo systemctl stop' [cite: 98]
    alias srestart='sudo systemctl restart' [cite: 98]
    alias sstatus='systemctl status' [cite: 98]
    alias senable='sudo systemctl enable' [cite: 99]
    alias sdisable='sudo systemctl disable' [cite: 99]
    alias sreload='sudo systemctl reload' [cite: 99]
    alias slist='systemctl list-units --type=service' [cite: 99]
    alias sfailed='systemctl --failed' [cite: 99]
    
    alias logs='sudo journalctl -f' [cite: 99]
    alias logsboot='sudo journalctl -b' [cite: 99]
    alias logserr='sudo journalctl -p err' [cite: 99]
    alias logsservice='sudo journalctl -u' [cite: 99]
    
    alias yast='sudo yast2' [cite: 99]
    alias yastnet='sudo yast2 lan' [cite: 99]
    alias yastuser='sudo yast2 users' [cite: 99]
    alias yastsoft='sudo yast2 sw_single' [cite: 100]
    alias yastboot='sudo yast2 bootloader' [cite: 100]
    
    alias snaplist='sudo snapper list' [cite: 100]
    alias snapcreate='sudo snapper create -d' [cite: 100]
    alias snapdelete='sudo snapper delete' [cite: 100]
    alias snapstatus='sudo snapper status' [cite: 100]
    
    alias fwstatus='sudo firewall-cmd --state' [cite: 100]
    alias fwlist='sudo firewall-cmd --list-all' [cite: 100]
    alias fwreload='sudo firewall-cmd --reload' [cite: 100]
fi

# ============================================================================
# ARCH LINUX / CACHYOS SPECIFIC ALIASES
# ============================================================================
if [[ "$DETECTED_OS" == "arch" ]]; then [cite: 100]
    alias upd="sudo pacman -Sy" [cite: 101]
    alias upgrade="sudo pacman -Syu" [cite: 101]
    alias install="sudo pacman -S" [cite: 101]
    alias search="pacman -Ss" [cite: 101]
    alias info="pacman -Si" [cite: 101]
    alias remove="sudo pacman -R" [cite: 101]
    alias removeall="sudo pacman -Rns" [cite: 101]
    alias clean="sudo pacman -Sc" [cite: 101]
    alias cleanall="sudo pacman -Scc" [cite: 101]
    alias installed="pacman -Q" [cite: 101]
    alias orphans="pacman -Qdt" [cite: 101]
    alias removeorphans="sudo pacman -Rns \$(pacman -Qtdq)" [cite: 101]
    
    if command -v yay >/dev/null 2>&1; then [cite: 102]
        alias yayupdate="yay -Syu" [cite: 103]
        alias yayinstall="yay -S" [cite: 103]
        alias yaysearch="yay -Ss" [cite: 103]
        alias yayremove="yay -R" [cite: 103]
        alias yayclean="yay -Sc" [cite: 103]
    fi
    
    alias sstart="sudo systemctl start" [cite: 103]
    alias sstop="sudo systemctl stop" [cite: 103]
    alias srestart="sudo systemctl restart" [cite: 103]
    alias sstatus="systemctl status" [cite: 103]
    alias senable="sudo systemctl enable" [cite: 103]
    alias sdisable="sudo systemctl disable" [cite: 104]
    alias sreload="sudo systemctl reload" [cite: 104]
    alias slist="systemctl list-units --type=service" [cite: 104]
    alias sfailed="systemctl --failed" [cite: 104]
    
    alias logs="sudo journalctl -f" [cite: 104]
    alias logsboot="sudo journalctl -b" [cite: 104]
    alias logserr="sudo journalctl -p err" [cite: 104]
    alias logsservice="sudo journalctl -u" [cite: 104]
    
    if [[ "$IS_CACHYOS" == "true" ]]; then [cite: 104]
        alias kernel-list="pacman -Q | grep -E '(linux|kernel)'" [cite: 105]
        alias kernel-install="sudo pacman -S" [cite: 105]
        alias kernel-remove="sudo pacman -R" [cite: 105]
        
        alias cachy-repo="sudo pacman -Sy cachyos-keyring cachyos-mirrorlist" [cite: 105]
        alias cachy-update="sudo pacman -Sy && sudo pacman -Su" [cite: 105]
        
        alias perf-cpu="sudo cpupower frequency-info" [cite: 106]
        alias perf-gov="sudo cpupower frequency-set -g" [cite: 106]
        alias perf-sched="cat /sys/kernel/debug/sched_features 2>/dev/null || echo 'Scheduler features not available'" [cite: 106]
        
        alias cachy-settings="cachyos-hello" [cite: 106]
        alias cachy-kernel-manager="cachyos-kernel-manager" [cite: 106]
        alias cachy-welcome="cachyos-hello" [cite: 106, 107]
        
        alias performance="sudo cpupower frequency-set -g performance && echo '🚀 Performance mode enabled'" [cite: 107]
        alias powersave="sudo cpupower frequency-set -g powersave && echo '🔋 Powersave mode enabled'" [cite: 107]
        alias balanced="sudo cpupower frequency-set -g schedutil && echo '⚖️  Balanced mode enabled'" [cite: 107]
    fi
fi

# ============================================================================
# ALPINE LINUX SPECIFIC ALIASES
# ============================================================================
if [[ "$DETECTED_OS" == "alpine" ]]; then [cite: 108]
    alias upd="sudo apk update" [cite: 109]
    alias upgrade="sudo apk upgrade" [cite: 109]
    alias install="sudo apk add" [cite: 109]
    alias search="apk search" [cite: 109]
    alias info="apk info" [cite: 109]
    alias remove="sudo apk del" [cite: 109]
    alias clean="sudo apk cache clean" [cite: 109]
    alias installed="apk info -vv | sort" [cite: 109]
    
    alias services="rc-status" [cite: 109]
    alias addservice="sudo rc-update add" [cite: 109]
    alias delservice="sudo rc-update del" [cite: 109]
    alias startservice="sudo rc-service" [cite: 109]
    alias stopservice="sudo rc-service" [cite: 110]
fi

# ============================================================================
# DOCKER & FLATPAK ALIASES
# ============================================================================
if command -v docker >/dev/null 2>&1; then [cite: 110]
    alias dps='docker ps' [cite: 111]
    alias dpsa='docker ps -a' [cite: 111]
    alias di='docker images' [cite: 111]
    alias dstop='docker stop $(docker ps -q)' [cite: 111]
    alias drm='docker rm $(docker ps -aq)' [cite: 111]
    alias drmi='docker rmi $(docker images -q)' [cite: 111]
    alias dprune='docker system prune -af' [cite: 111]
    alias dlog='docker logs' [cite: 111]
    alias dexec='docker exec -it' [cite: 111]
    alias dbuild='docker build' [cite: 111]
    alias drun='docker run' [cite: 111]
    alias dpull='docker pull' [cite: 111]
    alias dpush='docker push' [cite: 111]
fi

if command -v flatpak >/dev/null 2>&1; then [cite: 111, 112]
    alias fplist='flatpak list' [cite: 112]
    alias fpinstall='flatpak install' [cite: 112]
    alias fpremove='flatpak uninstall' [cite: 112]
    alias fpupdate='flatpak update' [cite: 112]
    alias fpsearch='flatpak search' [cite: 112]
    alias fprun='flatpak run' [cite: 112]
fi

# ============================================================================
# MISCELLANEOUS ALIASES
# ============================================================================
alias now='date +"%T"' [cite: 112]
alias nowdate='date +"%d-%m-%Y"' [cite: 112]
alias path='echo -e ${PATH//:/\\n}' [cite: 112]
alias j='jobs -l' [cite: 112]
alias reload='source ~/.zshrc' [cite: 112]
alias sa='source ~/.zshrc && echo "🚀 ZSH configuration reloaded successfully!"' [cite: 112]

alias weather='curl wttr.in' [cite: 112]
alias weatherlocal='curl wttr.in/$(curl -s ipinfo.io/city 2>/dev/null)' [cite: 112]