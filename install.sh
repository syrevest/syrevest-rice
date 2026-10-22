#!/usr/bin/env bash

set -euo pipefail

# Pure White — installer
# Arch Linux + Hyprland

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config/pure-white-backup-$(date +%Y%m%d-%H%M%S)"

echo "Pure White installer"
echo "Repository: $REPO_DIR"

if [[ ! -f /etc/arch-release ]]; then
    echo "Error: this installer is intended for Arch Linux."
    exit 1
fi

echo
echo "A backup of existing configs will be saved to:"
echo "$BACKUP_DIR"
echo

read -r -p "Continue? [y/N] " answer
if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo "Cancelled."
    exit 0
fi

mkdir -p "$BACKUP_DIR"

# Back up existing configuration directories.
for item in hypr waybar kitty rofi; do
    if [[ -e "$CONFIG_DIR/$item" ]]; then
        cp -a "$CONFIG_DIR/$item" "$BACKUP_DIR/"
        echo "Backed up: $item"
    fi
done

echo
echo "Backup complete."
echo "The next step will install dependencies and copy Pure White configs."

# Install packages using yay (official repositories + AUR).
PACKAGES=(
    hyprland
    waybar
    kitty
    rofi
    nemo
    papirus-icon-theme
    ttf-jetbrains-mono-nerd
    pipewire
    wireplumber
    pavucontrol
    network-manager-applet
)

# Install yay if it is missing.
if ! command -v yay >/dev/null 2>&1; then
    echo "yay not found. Installing dependencies..."

    sudo pacman -S --needed git base-devel

    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' EXIT

    git clone https://aur.archlinux.org/yay.git "$TEMP_DIR/yay"
    (
        cd "$TEMP_DIR/yay"
        makepkg -si
    )

    if ! command -v yay >/dev/null 2>&1; then
        echo "Error: yay installation failed."
        exit 1
    fi

    echo "yay installed successfully."
fi

echo
echo "Installing required packages using yay..."
yay -S --needed "${PACKAGES[@]}"

echo
echo "Package installation complete."
echo "Existing configurations have only been backed up so far."
echo "No configurations have been replaced yet."

