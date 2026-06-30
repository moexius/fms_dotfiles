#!/bin/bash
# Resolves the Obsidian vault path for this machine — differs by OS/mount.
if [[ -d "$HOME/obsidian" ]]; then
    echo "$HOME/obsidian"
elif [[ -d "/mnt/flash/obsidian" ]]; then
    echo "/mnt/flash/obsidian"
else
    echo "$HOME/obsidian"
fi
