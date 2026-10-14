# syrevest-rice

<p align="center">
  <strong>My personal Arch Linux + Hyprland rice.</strong>
  <br />
  A minimal, customizable Linux desktop setup.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OS-Arch%20Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white" alt="Arch Linux" />
  <img src="https://img.shields.io/badge/WM-Hyprland-58E1FF?style=for-the-badge&logo=hyprland&logoColor=black" alt="Hyprland" />
  <img src="https://img.shields.io/badge/Launcher-Rofi-7E9CD8?style=for-the-badge&logo=linux&logoColor=white" alt="Rofi" />
</p>

---

## About

Welcome to **syrevest-rice** — my personal desktop configuration for Arch Linux and Hyprland.

This repository contains the configuration files I use to customize my Linux desktop. The goal is to keep the setup clean, practical, and easy to maintain.

## Components

| Component | Purpose |
| --- | --- |
| Arch Linux | Operating system |
| Hyprland | Wayland compositor |
| Rofi | Application launcher |
| awww | Wallpaper management |

## Repository Structure

```text
syrevest-rice/
├── hypr/
│   └── hyprland.lua
├── rofi/
│   └── syrevest.rasi
├── .gitignore
└── README.md
```

## Features

- Personal Hyprland configuration
- Custom Rofi theme
- Wallpaper management with awww
- Simple, organized configuration files

## Installation

> **Important:** These are personal configuration files. Review them before using them on another system. Back up your existing configuration first.

### 1. Clone the repository

```bash
git clone https://github.com/syrevest/syrevest-rice.git
cd syrevest-rice
```

### 2. Back up existing configurations

```bash
mkdir -p ~/.config/rice-backup
```

If the destination files already exist, back them up before replacing anything:

```bash
cp -a ~/.config/hypr ~/.config/rice-backup/hypr
cp -a ~/.config/rofi ~/.config/rice-backup/rofi
```

Skip a backup command if its source directory does not exist.

### 3. Review the configuration

Inspect the files before installing them. Check file paths, keybindings, commands, and dependencies. The Hyprland configuration in this repository is named `hyprland.lua`; verify how your particular setup loads Lua configuration before copying it into place.

### 4. Apply the configuration

Copy only the files you have reviewed and adapted for your system. Do not overwrite your working configuration blindly.

## Notes

- This repository reflects my personal setup and may require adjustments on other systems.
- Package availability and configuration requirements can change.
- Wallpapers are not included unless explicitly added to the repository.

## Credits

Thanks to the developers and communities behind Arch Linux, Hyprland, Rofi, and awww.

## Author

**syrevest**

[GitHub Profile](https://github.com/syrevest)

