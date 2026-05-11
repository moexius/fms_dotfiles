#!/bin/bash
# Create virtual headless output for Sunshine streaming on KDE Plasma 6

export XDG_RUNTIME_DIR=/run/user/$(id -u)
export WAYLAND_DISPLAY=$(systemctl --user show-environment | grep '^WAYLAND_DISPLAY=' | cut -d= -f2-)

if [ -z "$WAYLAND_DISPLAY" ]; then
    echo "create-headless: WAYLAND_DISPLAY not set" >&2
    exit 1
fi

# Find virtual/headless output (requires drm_vkms or similar to already expose one)
HEADLESS=$(kscreen-doctor -o 2>/dev/null \
    | grep -E 'Output:.*[Vv]irtual|Output:.*HEADLESS' \
    | awk '{print $3}' | head -1)

if [ -z "$HEADLESS" ]; then
    echo "create-headless: no virtual output found" >&2
    echo "  enable drm_vkms: echo drm_vkms | sudo tee /etc/modules-load.d/vkms.conf && sudo modprobe vkms" >&2
    exit 1
fi

# Enable and set mode
kscreen-doctor \
    "output.${HEADLESS}.enable" \
    "output.${HEADLESS}.mode.1920x1080@120"

# Update sunshine.conf
SUNSHINE_CONF="/home/moexius/.config/sunshine/sunshine.conf"
if grep -q '^output_name' "$SUNSHINE_CONF"; then
    sed -i "s|^output_name.*|output_name = ${HEADLESS}|" "$SUNSHINE_CONF"
else
    echo "output_name = ${HEADLESS}" >> "$SUNSHINE_CONF"
fi

echo "create-headless: ${HEADLESS} enabled; sunshine.conf updated"
