# 🍎⚡ Universal ZSH + Starship Dotfiles

A comprehensive, cross-platform dotfiles setup that provides a beautiful and functional shell environment with ZSH, Starship prompt, and Apple Watch SSH authentication.

## ✨ Features

### 🌍 Universal Compatibility
- **Linux**: Debian, Ubuntu, CentOS/RHEL, Fedora, Arch, Alpine, openSUSE
- **macOS**: Full Homebrew integration with Apple-specific features
- **Containers**: Optimized for Docker/LXC environments

### 🎨 Beautiful Interface
- **Starship Prompt**: Custom configuration showing OS, user, hostname, time, Git status, and more
- **Smart Icons**: Environment-aware icons (🍎 macOS, 🐧 Linux, 📦 Container)
- **Color Themes**: Consistent color scheme across all tools

### ⚡ Performance Optimized
- **Lazy Loading**: Tools load only when needed for faster startup
- **Smart Caching**: Intelligent completion and history management
- **Container Aware**: Disables heavy plugins in containerized environments

### 🔧 Rich Toolset
- **Navigation**: `zoxide` for smart directory jumping
- **Search**: `fzf` for fuzzy finding files, history, and processes
- **File Viewing**: `bat` for syntax-highlighted file viewing
- **Listing**: `lsd` for beautiful directory listings
- **Documentation**: `tldr` for quick command references

### 🔒 Security & Privacy
- **Private Aliases**: Sensitive server information kept separate from public repo
- **Apple Watch SSH**: Biometric authentication for SSH connections (macOS only)
- **Secure Key Management**: SSH keys stored in macOS Keychain with Secure Enclave support

### 🎯 Smart Features
- **Environment Detection**: Automatic OS and package manager detection
- **Alias System**: Searchable, categorized aliases with help system
- **Git Integration**: Enhanced Git workflow with shortcuts and branch switching
- **System Monitoring**: Built-in system information and monitoring tools

## 🚀 Quick Install

### One-line install:
```bash
curl -fsSL https://raw.githubusercontent.com/moexius/fms_dotfiles/main/install.sh -o install.sh && chmod +x install.sh && ./install.sh && rm install.sh