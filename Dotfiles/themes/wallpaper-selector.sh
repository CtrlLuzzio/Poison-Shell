#!/bin/bash

GREEN='\033[1;32m'
NC='\033[0m'

THEMES=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
WALLPAPER_STATE="$THEMES/.wallpaper-state"
SELECTED_THEME=$(cat $THEMES/.current-theme)
SELECTED_THEME_WALLPAPERS="$THEMES/$SELECTED_THEME/wallpapers"

if [ ! -f "$WALLPAPER_STATE" ]; then
    touch "$WALLPAPER_STATE"
fi

SELECT_WALLPAPER=$(find "$SELECTED_THEME_WALLPAPERS" -mindepth 1 -maxdepth 1 -type f -printf "%f\0icon\037%p\n" | 
                    rofi -dmenu -show-icons -p "Selecciona un fondo de pantalla" -config $THEMES/rofi-wallpaper-selector.rasi)

if [ -n "$SELECT_WALLPAPER" ]; then
    WALLPAPER_PATH="$SELECTED_THEME_WALLPAPERS/$SELECT_WALLPAPER"
    sed -i "/^$SELECTED_THEME:/d" "$WALLPAPER_STATE"
    echo "$SELECTED_THEME:$WALLPAPER_PATH" >> "$WALLPAPER_STATE"
    awww img "$WALLPAPER_PATH" --transition-type wipe --transition-fps 75 --transition-step 255 > /dev/null 2>&1
    mkdir -p "$HOME/.config/hypr/hyprlock"
    ln -sf "$WALLPAPER_PATH" "$HOME/.config/hypr/hyprlock/wallpaper" > /dev/null 2>&1
    echo -e "${GREEN}Wallpaper aplicado correctamente${NC}"
    notify-send "Fondo de Pantalla Cambiado" "Fondo de Pantalla cambiado a $SELECT_WALLPAPER" -t 3000
else
    echo "Ningún tema seleccionado."
fi