# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Cross-platform ZSH + Starship dotfiles for Linux (Debian, Ubuntu, Arch/CachyOS, Fedora, Alpine, openSUSE), macOS, and containers (Docker/LXC).

## Installation

```bash
./install.sh              # Interactive full install (OS-detect, packages, symlinks, shell change)
```

Partial re-run flows (OS-specific):
```bash
./install/os-arch.sh      # Arch/CachyOS only
./install/os-debian.sh    # Debian/Ubuntu only
./install/os-macos.sh     # macOS only
./install/setup-workstation.sh  # Workstation-level setup
./scripts/update.sh       # Pull latest and re-symlink
```

## Symlinks Created by Installer

| Symlink | Source |
|---|---|
| `~/.zshrc` | `configs/zsh/zshrc` |
| `~/.config/starship.toml` | `configs/starship.toml` |
| `~/.config/atuin/config.toml` | `configs/atuin/config.toml` |

Private aliases (never committed) live in `~/.zsh_private_aliases`.

## ZSH Config Architecture

`configs/zsh/zshrc` sources modules in this order:

1. **`os_specific.zsh`** — Sets `$DETECTED_OS`, `$PKG_MANAGER`, `$ENVIRONMENT`, `$IS_CACHYOS` via `detect_os()`. Must run first; all other files branch on these vars.
2. **`plugins.zsh`** — Zinit plugin manager, Starship init, zoxide init, fzf keybindings, Atuin history (wins `^R`; fzf gets `Alt+R`). Skips `zsh-autocomplete` inside LXC containers.
3. **`aliases.zsh`** — Universal aliases first, then OS-gated blocks (`if [[ "$DETECTED_OS" == "arch" ]]`). Includes the `alias_search`/`alias_list`/`alias_os` help system.
4. **`functions.zsh`** — Shell functions: `mkcd`, `extract`, `ff`, `sysinfo`, `killp`, `fzf_git_branch`, `docker_exec`, plus CachyOS-gated (`cachy_maintenance`) and openSUSE-gated (`zinstall`, `cleanup`) functions.

## Package Lists

| File | Used for |
|---|---|
| `packages/Brewfile` | macOS (Homebrew bundle) |
| `packages/cachyos.txt` | CachyOS / Arch pacman |
| `packages/lxc.txt` | LXC headless containers (apt) |
| `packages/arch-core.txt` | Core Arch packages |
| `packages/debian-core.txt` | Core Debian packages |
| `packages/debian-gui.txt` | Debian GUI packages |

Comment lines (`#`) in `.txt` files are stripped before passing to the package manager.

## Key Design Patterns

- **OS detection** is the central gate. Always check `$DETECTED_OS` / `$IS_CACHYOS` / `$ENVIRONMENT` before adding OS-specific code; match the existing pattern in `os_specific.zsh`.
- **Tool availability guards**: wrap aliases/functions in `if command -v <tool> >/dev/null 2>&1` so configs degrade gracefully when tools are absent.
- **Container awareness**: heavy plugins and startup messages are conditioned on `! grep -qa 'container=lxc' /proc/1/environ`.
- **Default editor**: `$EDITOR` is set to `fresh` (fresh-editor). `nano` is aliased to `fresh`.
- **Atuin vs fzf history**: Atuin owns `^R`; fzf history is on `Alt+R`. Load order in `plugins.zsh` enforces this — don't change it.

## Testing Changes

No automated test suite. To validate changes:

```bash
source ~/.zshrc          # Reload config in current shell
reload                   # Alias for the above
sa                       # Alias: reload + success message
```

To test OS-specific branches without switching OS, temporarily override the detection vars:

```bash
DETECTED_OS=debian source configs/zsh/aliases.zsh
```
