
#!/usr/bin/env bash

set -Eeuo pipefail

# Pure White installer
# Arch Linux + Hyprland

readonly SCRIPT_NAME="syrevest's rice"
readonly REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
readonly BACKUP_DIR="$DATA_DIR/pure-white-backups/$(date +%Y%m%d-%H%M%S)"

DRY_RUN=false
INSTALL_PACKAGES=true
INSTALL_WALLPAPER=true

PACKAGES=(
    linux
    linux-firmware
    base
    base-devel
    networkmanager
    grub
    imv
    mpv
    noto-fonts-emoji
    qt5-wayland
    qt6-wayland
    qt6ct
    efibootmgr
    vim
    vi
    reflector
    git
    hyprland
    kitty
    pipewire
    pipewire-audio
    pipewire-alsa
    pipewire-pulse
    pipewire-jack
    lib32-libpulse
    lib32-pipewire-jack
    wireplumber
    nemo
    waybar
    rofi
    mako
    ttf-jetbrains-mono-nerd
    papirus-icon-theme
    awww
    pavucontrol
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
    wine
    vivaldi
    vesktop
    alsa-utils
    easyeffects
    cups
    cups-filters
    blesh
    bash-completion
    fastfetch
    btop
    obs-studio
    steam
    telegram-desktop
    winetricks
    
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
Pure White installer

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
    missing_packages=()

    for package in "${PACKAGES[@]}"; do
        if ! pacman -Si "$package" >/dev/null 2>&1; then
            missing_packages+=("$package")
        fi
    done

    if ((${#missing_packages[@]} > 0)); then
        warn "These packages were not found in enabled official repositories:"
        printf '  - %s\n' "${missing_packages[@]}"
        die "Review the package names or install unavailable packages separately."
    fi
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
        "$CONFIG_DIR/rofi/syrevest.rasi"

    if [[ "$INSTALL_WALLPAPER" == true ]]; then
        printf '  %s\n' "$DATA_DIR/pure-white/wallpapers/syrevest.jpg"
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
    log "Installing packages using pacman..."
    sudo pacman -S --needed "${PACKAGES[@]}"
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
    wallpaper_dir="$DATA_DIR/pure-white/wallpapers"
    mkdir -p "$wallpaper_dir"
    install -m 644 \
        "$REPO_DIR/wallpapers/syrevest.jpg" \
        "$wallpaper_dir/syrevest.jpg"
    log "Installed wallpaper: $wallpaper_dir/syrevest.jpg"
fi

# ---------- Summary ----------

cat <<EOF

Pure White installation finished.

Backup:
  $BACKUP_DIR

Installed configs:
  $CONFIG_DIR/hypr/hyprland.lua
  $CONFIG_DIR/waybar/
  $CONFIG_DIR/kitty/kitty.conf
  $CONFIG_DIR/rofi/syrevest.rasi

EOF

if [[ "$INSTALL_WALLPAPER" == true ]]; then
    printf 'Wallpaper:\n  %s\n\n' "$DATA_DIR/pure-white/wallpapers/syrevest.jpg"
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
