# ============================================================================
# ENVIRONMENT DETECTION
# ============================================================================

# Detect environment type
if [[ -f /.dockerenv ]] || [[ -n "${container}" ]]; then
    ENVIRONMENT="container"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    ENVIRONMENT="macos"
else
    ENVIRONMENT="linux"
fi

# Detect OS and package manager for Linux
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        export DETECTED_OS="macos"
        export PKG_MANAGER="brew"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case $ID in
            debian|ubuntu)
                export DETECTED_OS="debian"
                export PKG_MANAGER="apt"
                ;;
            centos|rhel|rocky|almalinux)
                export DETECTED_OS="rhel"
                export PKG_MANAGER="yum"
                ;;
            fedora)
                export DETECTED_OS="fedora"
                export PKG_MANAGER="dnf"
                ;;
            opensuse*|sles)
                export DETECTED_OS="opensuse"
                export PKG_MANAGER="zypper"
                ;;
            arch|manjaro|cachyos)
                export DETECTED_OS="arch"
                export PKG_MANAGER="pacman"
                if [[ "$ID" == "cachyos" ]]; then
                    export IS_CACHYOS="true"
                fi
                ;;
            alpine)
                export DETECTED_OS="alpine"
                export PKG_MANAGER="apk"
                ;;
            *)
                export DETECTED_OS="unknown"
                export PKG_MANAGER="unknown"
                ;;
        esac
    else
        export DETECTED_OS="unknown"
        export PKG_MANAGER="unknown"
    fi
}

# Run OS detection
detect_os