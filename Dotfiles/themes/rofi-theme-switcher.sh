#!/bin/bash

THEMES_ROOT=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TARGET_SCRIPT="$THEMES_ROOT/apply-theme.sh"

if [ ! -x "$TARGET_SCRIPT" ]; then
    rofi -e "Error: No se encontró el script en $TARGET_SCRIPT"
    exit 1
fi

SELECT_THEME=$(find "$THEMES_ROOT" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | grep -v '^\.$' | rofi -dmenu -p "Selecciona un tema")

if [ -n "$SELECT_THEME" ]; then
    "$TARGET_SCRIPT" "$SELECT_THEME"
else
    echo "Ningún tema seleccionado."
fi