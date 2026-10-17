#!/usr/bin/env bash
choice=$(printf 'Выключить\nПерезагрузить\nВыйти из Hyprland\nОтмена' |
    rofi -dmenu -i -p 'Питание')

case "$choice" in
    "Выключить")
        systemctl poweroff
        ;;
    "Перезагрузить")
        systemctl reboot
        ;;
    "Выйти из Hyprland")
        hyprctl dispatch exit
        ;;
esac
