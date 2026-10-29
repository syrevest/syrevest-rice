
#!/usr/bin/env bash

set -Eeuo pipefail

# syrevest-rice installer
# Arch Linux + Hyprland

readonly SCRIPT_NAME="syrevest-rice"
readonly REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
readonly BACKUP_DIR="$DATA_DIR/syrevest-rice-backups/$(date +%Y%m%d-%H%M%S)"

DRY_RUN=false
INSTALL_PACKAGES=true
INSTALL_WALLPAPER=true

PACKAGES=(
       # Build tools
       git
       github-cli

       # Display manager
       sddm

       # Hyprland
       hyprland
       xdg-desktop-portal
       xdg-desktop-portal-gtk
       xdg-desktop-portal-hyprland
       qt5-wayland
       qt6-wayland
       qt6ct

       # Panel, launcher and notifications
       waybar
       rofi
       mako

       # Terminal
       kitty
       bash-completion
       blesh
       fastfetch
       btop
       vim

       # Fonts and icons
       ttf-jetbrains-mono-nerd
       papirus-icon-theme
       noto-fonts-emoji

       # Audio
       pipewire
       pipewire-audio
       pipewire-alsa
       pipewire-pulse
       pipewire-jack
       wireplumber
       lib32-libpulse
       lib32-pipewire-jack
       alsa-utils
       pavucontrol
       easyeffects

       # Wallpaper and screenshots
       awww
       grim
       imv

       # Network
       networkmanager

       # Printing
       cups
       cups-filters
       hplip

       # Gaming
       steam
       wine
       winetricks

       # Applications
       vivaldi
       vesktop
       telegram-desktop
       obs-studio
       flatpak
       happ-desktop-bin
)

# ---------- Helpers ----------

log() {
    printf '[INFO] %s\n' "$*"
}

warn() {
    printf '[WARN] %s\n' "$*" >&2
}

die() {
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
syrevest-rice installer

Usage:
  ./install.sh [options]

Options:
  --dry-run          Show actions without changing configs or installing packages
  --no-packages      Skip package installation
  --no-wallpaper     Skip wallpaper installation
  --help             Show this help
EOF
}

on_error() {
    local code=$?
    printf '[ERROR] Failed near line %s (exit code %s).\n' \
        "${BASH_LINENO[0]:-unknown}" "$code" >&2
    exit "$code"
}

trap on_error ERR


configure_sddm() {
    if ! pacman -Qq sddm >/dev/null 2>&1; then
        warn "SDDM is not installed; skipping its theme."
        return 0
    fi

    local theme_source="$REPO_DIR/sddm/themes/syrevest"
    local theme_target="/usr/share/sddm/themes/syrevest"
    local conf_source="$REPO_DIR/sddm/10-syrevest-theme.conf"
    local conf_target="/etc/sddm.conf.d/10-syrevest-theme.conf"
    local backup_theme="$BACKUP_DIR/sddm/themes/syrevest"
    local backup_conf="$BACKUP_DIR/sddm/conf.d/10-syrevest-theme.conf"

    # Back up the existing theme, if present.
    if [[ -d "$theme_target" ]]; then
        mkdir -p "$(dirname -- "$backup_theme")"
        cp -a -- "$theme_target" "$backup_theme"
        log "Backed up SDDM theme to: $backup_theme"
    fi

    # Back up the existing theme selection, if present.
    if [[ -e "$conf_target" || -L "$conf_target" ]]; then
        mkdir -p "$(dirname -- "$backup_conf")"
        cp -a -- "$conf_target" "$backup_conf"
        log "Backed up SDDM settings to: $backup_conf"
    fi

    # Install the theme files into the system directory.
    sudo install -d "$theme_target"
    for file in Main.qml metadata.desktop theme.conf syrevest.jpg; do
        sudo install -m 644 -- "$theme_source/$file" "$theme_target/$file"
    done

    # Install the configuration that selects the syrevest theme.
    sudo install -d /etc/sddm.conf.d
    sudo install -m 644 -- "$conf_source" "$conf_target"

    log "Installed SDDM theme: $theme_target"
    log "Installed SDDM settings: $conf_target"
}


configure_blesh() {
    local bashrc="$HOME/.bashrc"
    local blerc_source="$REPO_DIR/bash/blerc"
    local blerc_target="$HOME/.blerc"
    local tmp

    if [[ ! -f /usr/share/blesh/ble.sh ]]; then
        log "ble.sh not found; skipping Bash suggestions."
        return 0
    fi

    [[ -f "$blerc_source" ]] ||
        die "Required file is missing: $blerc_source"

    mkdir -p "$BACKUP_DIR"

    # Back up existing files before changing them.
    if [[ -f "$bashrc" ]]; then
        cp -a -- "$bashrc" "$BACKUP_DIR/bashrc"
        log "Backed up: $bashrc"
    else
        touch "$bashrc"
    fi

    if [[ -e "$blerc_target" || -L "$blerc_target" ]]; then
        cp -a -- "$blerc_target" "$BACKUP_DIR/blerc"
        log "Backed up: $blerc_target"
    fi

    # Install the project's ble.sh settings.
    install -m 644 -- "$blerc_source" "$blerc_target"
    log "Installed: $blerc_target"

    # Remove the old manual source line or a previously managed block.
    tmp="$(mktemp "${bashrc}.XXXXXX")"

    awk '
        /^# >>> syrevest-rice: ble\.sh >>>$/ { skip=1; next }
        /^# <<< syrevest-rice: ble\.sh <<</ { skip=0; next }
        skip { next }
        /^# ble\.sh$/ { next }
        /^[[:space:]]*\[\[ \$- == \*i\* \]\] && source \/usr\/share\/blesh\/ble\.sh[[:space:]]*$/ { next }
        { print }
    ' "$bashrc" > "$tmp"

    cat >> "$tmp" <<'EOF'

# >>> syrevest-rice: ble.sh >>>
if [[ $- == *i* ]] && [[ -f /usr/share/blesh/ble.sh ]]; then
    source /usr/share/blesh/ble.sh
fi
# <<< syrevest-rice: ble.sh <<<
EOF

    chmod --reference="$bashrc" "$tmp" 2>/dev/null || chmod 644 "$tmp"
    mv -- "$tmp" "$bashrc"

    log "Configured ble.sh and removed duplicate source lines."
}

ensure_yay() {
    if [[ $EUID -eq 0 ]]; then
        die "Do not run this installer as root."
    fi

    if command -v yay >/dev/null 2>&1; then
        log "yay is already installed."
        return 0
    fi

    command -v sudo >/dev/null 2>&1 ||
        die "sudo is required to install yay."

    log "Installing prerequisites for yay..."

    if ! sudo pacman -S --needed base-devel git; then
        die "Failed to install prerequisites for yay."
    fi

    local build_dir

    if ! build_dir="$(mktemp -d)"; then
        die "Failed to create a temporary directory."
    fi

    log "Downloading yay build files from the AUR..."

    if ! git clone https://aur.archlinux.org/yay.git "$build_dir/yay"; then
        rm -rf -- "$build_dir"
        die "Failed to download yay."
    fi

    log "Building and installing yay..."

    if ! (cd "$build_dir/yay" && makepkg -si); then
        rm -rf -- "$build_dir"
        die "Failed to build or install yay."
    fi

    rm -rf -- "$build_dir"

    command -v yay >/dev/null 2>&1 ||
        die "yay installation could not be verified."

    log "yay installed successfully."
}

# ---------- Arguments ----------

while (($# > 0)); do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            ;;
        --no-packages)
            INSTALL_PACKAGES=false
            ;;
        --no-wallpaper)
            INSTALL_WALLPAPER=false
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            die "Unknown option: $1. Use --help."
            ;;
    esac
    shift
done

# ---------- Preflight checks ----------

log "$SCRIPT_NAME installer"
log "Repository: $REPO_DIR"
log "Config directory: $CONFIG_DIR"

[[ $EUID -ne 0 ]] || die "Do not run this installer with sudo."
[[ -f /etc/arch-release ]] || die "This installer is intended for Arch Linux."
command -v bash >/dev/null 2>&1 || die "Bash is required."
command -v pacman >/dev/null 2>&1 || die "pacman was not found."

required_files=(
    "hypr/hyprland.lua"
    "waybar/config.jsonc"
    "waybar/style.css"
    "kitty/kitty.conf"
    "rofi/syrevest.rasi"
    "bash/blerc"
    "sddm/10-syrevest-theme.conf"
    "sddm/themes/syrevest/Main.qml"
    "sddm/themes/syrevest/metadata.desktop"
    "sddm/themes/syrevest/theme.conf"
    "sddm/themes/syrevest/syrevest.jpg"
)

for file in "${required_files[@]}"; do
    [[ -f "$REPO_DIR/$file" ]] || die "Required project file is missing: $file"
done

if [[ ! -d "$REPO_DIR/waybar/scripts" ]]; then
    die "Required directory is missing: waybar/scripts"
fi

if [[ "$INSTALL_WALLPAPER" == true &&
      ! -f "$REPO_DIR/wallpapers/syrevest.jpg" ]]; then
    warn "Wallpaper wallpapers/syrevest.jpg was not found."
    INSTALL_WALLPAPER=false
fi

if [[ "$DRY_RUN" == true ]]; then
    log "Dry-run enabled: no packages or configuration files will be changed."
fi

# ---------- Package checks ----------

if [[ "$INSTALL_PACKAGES" == true ]]; then
    if command -v yay >/dev/null 2>&1; then
        log "yay found."
    else
        log "yay will be installed before the other packages."
    fi

    log "Package availability will be checked during dependency resolution."
fi

# ---------- Plan ----------

cat <<EOF

Installation plan
-----------------
Repository: $REPO_DIR
Config path: $CONFIG_DIR
Backup path: $BACKUP_DIR
Install packages: $INSTALL_PACKAGES
Install wallpaper: $INSTALL_WALLPAPER
Dry run: $DRY_RUN

The installer will back up existing configs before replacing them.
EOF

if [[ "$DRY_RUN" == true ]]; then
    log "Planned config targets:"
    printf '  %s\n' \
        "$CONFIG_DIR/hypr/hyprland.lua" \
        "$CONFIG_DIR/waybar/config.jsonc" \
        "$CONFIG_DIR/waybar/style.css" \
        "$CONFIG_DIR/waybar/scripts/" \
        "$CONFIG_DIR/kitty/kitty.conf" \
        "$CONFIG_DIR/rofi/syrevest.rasi" \
        "/usr/share/sddm/themes/syrevest/" \
        "/etc/sddm.conf.d/10-syrevest-theme.conf" \
        "$HOME/.blerc" \
        "$HOME/.bashrc"

    if [[ "$INSTALL_WALLPAPER" == true ]]; then
        printf '  %s\n' "$DATA_DIR/wallpapers/syrevest.jpg"
    fi

    log "Dry-run finished. No changes were made."
    exit 0
fi

read -r -p "Continue with installation? [y/N] " answer
[[ "$answer" == "y" || "$answer" == "Y" ]] || {
    log "Installation cancelled."
    exit 0
}

# ---------- Backup ----------

backup_path() {
    local target="$1"
    local relative="${target#"$CONFIG_DIR"/}"
    local destination="$BACKUP_DIR/$relative"

    if [[ -e "$target" || -L "$target" ]]; then
        mkdir -p "$(dirname -- "$destination")"
        cp -a -- "$target" "$destination"
        log "Backed up: $target"
    fi
}

mkdir -p "$BACKUP_DIR"
mkdir -p "$CONFIG_DIR"

backup_path "$CONFIG_DIR/hypr"
backup_path "$CONFIG_DIR/waybar"
backup_path "$CONFIG_DIR/kitty"
backup_path "$CONFIG_DIR/rofi"

log "Backup created at: $BACKUP_DIR"

# ---------- Package installation ----------

if [[ "$INSTALL_PACKAGES" == true ]]; then
    ensure_yay

    log "Installing packages through yay..."
    yay -S --needed "${PACKAGES[@]}"
fi

# ---------- Config installation ----------

copy_file() {
    local source="$1"
    local target="$2"

    mkdir -p "$(dirname -- "$target")"
    install -m 644 -- "$source" "$target"
    log "Installed: $target"
}

copy_file \
    "$REPO_DIR/hypr/hyprland.lua" \
    "$CONFIG_DIR/hypr/hyprland.lua"

copy_file \
    "$REPO_DIR/waybar/config.jsonc" \
    "$CONFIG_DIR/waybar/config.jsonc"

copy_file \
    "$REPO_DIR/waybar/style.css" \
    "$CONFIG_DIR/waybar/style.css"

mkdir -p "$CONFIG_DIR/waybar/scripts"

while IFS= read -r -d '' script; do
    name="${script##*/}"
    install -m 755 -- "$script" "$CONFIG_DIR/waybar/scripts/$name"
    log "Installed Waybar script: $name"
done < <(find "$REPO_DIR/waybar/scripts" -maxdepth 1 -type f -name '*.sh' -print0)

copy_file \
    "$REPO_DIR/kitty/kitty.conf" \
    "$CONFIG_DIR/kitty/kitty.conf"

copy_file \
    "$REPO_DIR/rofi/syrevest.rasi" \
    "$CONFIG_DIR/rofi/syrevest.rasi"

# ---------- Wallpaper ----------

if [[ "$INSTALL_WALLPAPER" == true ]]; then
    wallpaper_dir="$DATA_DIR/wallpapers"
    mkdir -p "$wallpaper_dir"
    install -m 644 \
        "$REPO_DIR/wallpapers/syrevest.jpg" \
        "$wallpaper_dir/syrevest.jpg"
    log "Installed wallpaper: $wallpaper_dir/syrevest.jpg"
fi

# ---------- SDDM theme ----------

configure_sddm

# ---------- Bash suggestions ----------

configure_blesh

# ---------- Summary ----------

cat <<EOF

syrevest-rice installation finished.

Backup:
  $BACKUP_DIR

Installed configs:
  $CONFIG_DIR/hypr/hyprland.lua
  $CONFIG_DIR/waybar/
  $CONFIG_DIR/kitty/kitty.conf
  $CONFIG_DIR/rofi/syrevest.rasi

EOF

if [[ "$INSTALL_WALLPAPER" == true ]]; then
    printf 'Wallpaper:\n  %s\n\n' "$DATA_DIR/wallpapers/syrevest.jpg"
fi

warn "Review the Hyprland monitor name, browser command, and wallpaper daemon before restarting Hyprland."
warn "The installer does not automatically restart your desktop session."

log "Checking installed configuration files..."

installed_files=(
    "$CONFIG_DIR/hypr/hyprland.lua"
    "$CONFIG_DIR/waybar/config.jsonc"
    "$CONFIG_DIR/waybar/style.css"
    "$CONFIG_DIR/kitty/kitty.conf"
    "$CONFIG_DIR/rofi/syrevest.rasi"
)

for file in "${installed_files[@]}"; do
    if [[ -f "$file" ]]; then
        log "OK: $file"
    else
        die "Installed file is missing: $file"
    fi
done
