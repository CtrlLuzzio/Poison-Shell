#!/bin/bash

# Color Codes

GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0n' #No Color

# Script

THEME="$1"

THEME_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "$THEME_DIR"

if [ -z "$THEME" ]; then
    echo -e "${YELLOW}Uso: $0 <theme-name>${NC}"
    exit 1
fi

if [ ! -d "$THEME_DIR" ]; then
    echo -e "${YELLOW}El tema '${THEME}' no existe en $THEME_DIR{NC}"
    notify-send "Error de Tema" "El tema '$THEME' no fue encontrado" -u critical
    exit 1
fi

# Track current theme

CURRENT_THEME_FILE="./.current-theme"
echo "$THEME" > "$CURRENT_THEME_FILE"

echo -e "${GREEN}Aplicando Tema: $THEME${NC}\n"
notify-send "Cambiando Tema" "Aplicando tema: $THEME" -t 3000

# Hyprland

echo -e "${CYAN} => Actualizando tema de Hyprland... ${NC}"
cp "$THEME_DIR/hypr/colors.conf" "$HOME/.config/hypr/colors/colors.conf" > /dev/null 2>&1
if [ \"$XDG_CURRENT_DESKTOP\" = \"Hyprland\" ]; then 
    hyprctl reload & disown
fi
echo -e "${GREEN}Tema de Hyprland actualizado ${NC}"
echo ""

# Wallpaper

echo -e "${CYAN} => Cambiando fondo de pantalla... ${NC}"

WALLPAPER_DIR="$THEME_DIR/wallpapers"
WALLPAPER_STATE="./.wallpaper-state"
WAYPAPER_CONFIG="$HOME/.config/waypaper/config.ini"

if [ ! -f "$WALLPAPER_STATE" ]; then
    touch "$WALLPAPER_STATE"
fi

SAVED_WALLPAPER=$(grep "^$THEME:" "$WALLPAPER_STATE" | cut -d':' -f2-)

if [ -n "$SAVED_WALLPAPER" ] && [ -f "$SAVED_WALLPAPER" ]; then
    WALLPAPER="$SAVED_WALLPAPER"
    echo -e "${CYAN}   Usando fondo de pantalla guardado${NC}"
elif [ -d "$WALLPAPER_DIR" ]; then
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | sort | head -n1 )
    if [ -n "$WALLPAPER" ]; then
        sed -i "/^$THEME:/d" "$WALLPAPER_STATE"
        echo "$THEME:$WALLPAPER" >> "$WALLPAPER_STATE"
        echo -e "${CYAN} Usando el primer fondo de pantalla (por defecto)${NC}"
    else
        echo -e "${YELLOW} No se encontraron fondos de pantalla en $WALLPAPER_DIR${NC}"
    fi
else
    echo -e "${YELLOW} No se encontró el directorio de fondos de pantalla: $WALLPAPER_DIR${NC}"
fi

if [ -f "$WAYPAPER_CONFIG" ]; then
    echo -e "${CYAN} => Actualizando configuración de Waypaper... ${NC}"
    ESCAPED_DIR=$(echo "$WALLPAPER_DIR" | sed 's/\//\\\//g')
    sed -i "s/^folder = .*/folder = $ESCAPED_DIR/" "$WAYPAPER_CONFIG"    
    sed -i "s/^backend = .*/backend = awww/" "$WAYPAPER_CONFIG"
    echo -e "${CYAN}   Carpeta de Waypaper actualizada a: $WALLPAPER_DIR${NC}"
fi

if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
    awww img "$WALLPAPER" --transition-type grow --transition-fps 75 --transition-step 255 > /dev/null 2>&1
    mkdir -p "$HOME/.config/hypr/hyprlock"
    ln -sf "$WALLPAPER" "$HOME/.config/hypr/hyprlock/wallpaper" > /dev/null 2>&1
    echo -e "${GREEN}Wallpaper aplicado correctamente${NC}"
else
    echo -e "${YELLOW}No se pudo establecer el wallpaper${NC}"
fi
echo ""

# GTK

if [ -f "$THEME_DIR/gtk-theme" ]; then
    GTK_THEME_NAME=$(cat "$THEME_DIR/gtk-theme")
    echo -e "${CYAN} => Estableciendo tema GTK a '$GTK_THEME_NAME'... ${NC}"
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_NAME"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

    echo -e "[Settings]\ngtk-theme-name=$GTK_THEME_NAME\ngtk-application-prefer-dark-theme=1" > "$HOME/.config/gtk-3.0/settings.ini"
else
    echo -e "${YELLOW} => Archivo 'gtk-theme' no encontrado en $THEME_DIR. Saltando.${NC}"
fi
echo ""

GTK4_SRC="$THEME_DIR/gtk-4.0"
GTK4_DST="$HOME/.config/gtk-4.0"

if [ -d "$GTK4_SRC" ]; then
    echo -e "${CYAN} => Enlazando archivos de tema GTK4... ${NC}"
    mkdir -p "$GTK4_DST"
    ln -sf "$GTK4_SRC/gtk.css" "$GTK4_DST/gtk.css"
    ln -sf "$GTK4_SRC/gtk-dark.css" "$GTK4_DST/gtk-dark.css"
    ln -sfn "$GTK4_SRC/assets" "$GTK4_DST/assets"
else
    echo -e "${YELLOW} => No se encontraron archivos GTK4 en $GTK4_SRC. Saltando.${NC}"
fi
echo ""

# Kitty

echo -e "${CYAN} => Actualizando tema de la terminal Kitty... ${NC}"
cp "$THEME_DIR/kitty/theme.conf" "$HOME/.config/kitty/theme.conf" > /dev/null 2>&1
echo -e "${GREEN}Tema de la terminal Kitty actualizado ${NC}"
echo ""

# Rofi

echo -e "${CYAN} => Actualizando tema de Rofi... ${NC}"
cp "$THEME_DIR/rofi/theme.rasi" "$HOME/.config/rofi/theme.rasi" > /dev/null 2>&1
echo -e "${GREEN}Tema de Rofi actualizado ${NC}"
echo ""

# Waybar and SwayNC

echo -e "${CYAN} => Actualizando tema de Waybar y SwayNC... ${NC}"
cp "$THEME_DIR/waybar/colors.css" "$HOME/.config/waybar/colors.css" > /dev/null 2>&1
pkill waybar > /dev/null 2>&1 && waybar > /dev/null 2>&1 & disown
cp "$THEME_DIR/swaync/theme.scss" "$HOME/.config/swaync/colors/theme.scss" > /dev/null 2>&1
pkill swaync > /dev/null 2>&1 && swaync > /dev/null 2>&1 & disown
echo -e "${GREEN}Tema de Waybar y SwayNC actualizado ${NC}"
echo ""

# wlogout
echo -e "${CYAN} => Actualizando tema de wlogout... ${NC}"
cp "$THEME_DIR/wlogout/colors.css" "$HOME/.config/wlogout/colors.css" > /dev/null 2>&1
cp -r "$THEME_DIR/wlogout/icons/"* "$HOME/.config/wlogout/icons" > /dev/null 2>&1
echo -e "${GREEN}Tema de wlogout actualizado ${NC}"
echo ""

# Spotify/Spicetify

echo -e "${CYAN} => Actualizando tema de Spotify... ${NC}"
spicetify config current_theme catppuccin
spicetify config color_scheme mocha
spicetify config inject_css 1 inject_theme_js 1 replace_colors 1 overwrite_assets 1
spicetify apply -n
spicetify refresh
echo -e "${GREEN}Tema de Spotify actualizado ${NC}"
echo ""

# VSCode

VSCODE_SETTINGS="$HOME/.config/Code/User/settings.json"

if [ -r "$VSCODE_SETTINGS" ]; then
    if [ -f "$THEME_DIR/vscode-theme" ]; then
        VSCODE_THEME=$(cat "$THEME_DIR/vscode-theme")
        echo -e "${CYAN} => Estableciendo tema de VSCode a '$VSCODE_THEME'... ${NC}"
        sed -i "s/\"workbench.colorTheme\": \".*\"/\"workbench.colorTheme\": \"$VSCODE_THEME\"/" "$VSCODE_SETTINGS"
    else
        echo -e "${YELLOW} => Archivo 'vscode-theme' no encontrado en $THEME_DIR. Saltando.${NC}"
    fi
    if [ -f "$THEME_DIR/vscode-icontheme" ]; then
        VSCODE_ICONTHEME=$(cat "$THEME_DIR/vscode-icontheme")
        echo -e "${CYAN} => Estableciendo íconos de VSCode a '$VSCODE_ICONTHEME'... ${NC}"
        sed -i "s/\"workbench.iconTheme\": \".*\"/\"workbench.iconTheme\": \"$VSCODE_ICONTHEME\"/" "$VSCODE_SETTINGS"
    else
        echo -e "${YELLOW} => Archivo 'vscode-icontheme' no encontrado en $THEME_DIR. Saltando.${NC}"
    fi
    if [ -f "$THEME_DIR/vscode-accent" ]; then
        VSCODE_ACCENT=$(cat "$THEME_DIR/vscode-accent")
        echo -e "${CYAN} => Estableciendo acento de VSCode a '$VSCODE_ACCENT'... ${NC}"
        
        if grep -q "catppuccin.accentColor" "$VSCODE_SETTINGS"; then
            sed -i "s/\"catppuccin.accentColor\": \".*\"/\"catppuccin.accentColor\": \"$VSCODE_ACCENT\"/" "$VSCODE_SETTINGS"
        else
            sed -i "/\"workbench.colorTheme\":/a \    \"catppuccin.accentColor\": \"$VSCODE_ACCENT\"," "$VSCODE_SETTINGS"
        fi
    fi
else
    echo -e "${YELLOW} => No se encontró '$VSCODE_SETTINGS'. Asegúrate de haber ejecutado VSCode al menos una vez.${NC}"
fi

echo ""

# Kvantum

KVANTUM_SRC="$THEME_DIR/kvantum"
KVANTUM_DST="$HOME/.config/Kvantum"

if [ -d "$KVANTUM_SRC" ]; then
    echo -e "${CYAN} => Enlazando temas de Kvantum... ${NC}"
    mkdir -p "$KVANTUM_DST"
    cp -rsf "$KVANTUM_SRC/"* "$KVANTUM_DST/" 2>/dev/null || ln -sf "$KVANTUM_SRC/"* "$KVANTUM_DST/"
fi

if [ -f "$THEME_DIR/kvantum-theme" ]; then
    KVANTUM_THEME_NAME=$(cat "$THEME_DIR/kvantum-theme")
    echo -e "${CYAN} => Estableciendo estilo Qt6 y Qt5 (Kvantum) a '$KVANTUM_THEME_NAME'... ${NC}"

    KVANTUM_CONFIG="$HOME/.config/Kvantum/kvantum.kvconfig"
    
    if [ ! -f "$KVANTUM_CONFIG" ]; then
        echo -e "[General]\ntheme=$KVANTUM_THEME_NAME" > "$KVANTUM_CONFIG"
    else
        if grep -q "^theme=" "$KVANTUM_CONFIG"; then
            sed -i "s/^theme=.*/theme=$KVANTUM_THEME_NAME/" "$KVANTUM_CONFIG"
        else
            echo "theme=$KVANTUM_THEME_NAME" >> "$KVANTUM_CONFIG"
        fi
    fi

    QT6CT_CONFIG="$HOME/.config/qt6ct/qt6ct.conf"
    if [ -f "$QT6CT_CONFIG" ]; then
        if grep -q "^style=" "$QT6CT_CONFIG"; then
             sed -i 's/^style=.*/style=kvantum/' "$QT6CT_CONFIG"
        fi
    fi
    QT5CT_CONFIG="$HOME/.config/qt5ct/qt5ct.conf"
    if [ -f "$QT5CT_CONFIG" ]; then
        if grep -q "^style=" "$QT5CT_CONFIG"; then
             sed -i 's/^style=.*/style=kvantum/' "$QT5CT_CONFIG"
        fi
    fi
    
    
else
    echo -e "${YELLOW} => Archivo 'kvantum-theme' no encontrado. Saltando.${NC}"
fi

echo ""

# Qt6

QT6CT_SRC="$THEME_DIR/qt6ct"
QT6CT_COLORS="$HOME/.config/qt6ct/colors"
QT6CT_CONF="$HOME/.config/qt6ct/qt6ct.conf"

if [ -d "$QT6CT_SRC" ]; then
    echo -e "${CYAN} => Configurando Qt6... ${NC}"
    
    mkdir -p "$QT6CT_COLORS"
    mkdir -p "$(dirname "$QT6CT_CONF")"

    COLOR_SCHEME_FILE=$(find "$QT6CT_SRC" -maxdepth 1 -name "*.conf" | head -n 1)

    if [ -f "$COLOR_SCHEME_FILE" ]; then
        COLOR_FILENAME=$(basename "$COLOR_SCHEME_FILE")
        
        cp "$COLOR_SCHEME_FILE" "$QT6CT_COLORS/$COLOR_FILENAME"

        if [ ! -f "$QT6CT_CONF" ]; then
            echo -e "[Appearance]\ncustom_palette=false\nstandard_dialogs=default" > "$QT6CT_CONF"
        fi
        
        sed -i 's/^custom_palette=.*/custom_palette=false/' "$QT6CT_CONF"
        
        FULL_COLOR_PATH="$QT6CT_COLORS/$COLOR_FILENAME"
        if grep -q "color_scheme_path=" "$QT6CT_CONF"; then
            sed -i "s|^color_scheme_path=.*|color_scheme_path=$FULL_COLOR_PATH|" "$QT6CT_CONF"
        else
            echo "color_scheme_path=$FULL_COLOR_PATH" >> "$QT6CT_CONF"
        fi
        
        echo -e "${GREEN}Tema Qt6 directo aplicado ($COLOR_FILENAME) ${NC}"
    else
        echo -e "${YELLOW} => No se encontró archivo .conf de colores en $QT6CT_SRC ${NC}"
    fi
else
    echo -e "${YELLOW} => Carpeta 'qt6ct' no encontrada en el tema. Saltando configuración directa.${NC}"
fi

echo ""

# Qt5

QT5CT_SRC="$THEME_DIR/qt5ct"
QT5CT_COLORS="$HOME/.config/qt5ct/colors"
QT5CT_CONF="$HOME/.config/qt5ct/qt5ct.conf"

if [ -d "$QT5CT_SRC" ]; then
    echo -e "${CYAN} => Configurando Qt5... ${NC}"
    
    mkdir -p "$QT5CT_COLORS"
    mkdir -p "$(dirname "$QT5CT_CONF")"

    COLOR_SCHEME_FILE=$(find "$QT5CT_SRC" -maxdepth 1 -name "*.conf" | head -n 1)

    if [ -f "$COLOR_SCHEME_FILE" ]; then
        COLOR_FILENAME=$(basename "$COLOR_SCHEME_FILE")
        
        cp "$COLOR_SCHEME_FILE" "$QT5CT_COLORS/$COLOR_FILENAME"

        if [ ! -f "$QT5CT_CONF" ]; then
            echo -e "[Appearance]\ncustom_palette=false\nstandard_dialogs=default" > "$QT5CT_CONF"
        fi
        
        sed -i 's/^custom_palette=.*/custom_palette=false/' "$QT5CT_CONF"
        
        FULL_COLOR_PATH="$QT5CT_COLORS/$COLOR_FILENAME"
        if grep -q "color_scheme_path=" "$QT5CT_CONF"; then
            sed -i "s|^color_scheme_path=.*|color_scheme_path=$FULL_COLOR_PATH|" "$QT5CT_CONF"
        else
            echo "color_scheme_path=$FULL_COLOR_PATH" >> "$QT5CT_CONF"
        fi
        
        echo -e "${GREEN}Tema Qt5 directo aplicado ($COLOR_FILENAME) ${NC}"
    else
        echo -e "${YELLOW} => No se encontró archivo .conf de colores en $QT5CT_SRC ${NC}"
    fi
else
    echo -e "${YELLOW} => Carpeta 'qt5ct' no encontrada en el tema. Saltando configuración directa.${NC}"
fi

echo ""

# Btop++

if [ -f "$HOME/.config/btop/btop.conf" ]; then
    echo -e "${CYAN} => Actualizando tema de Btop... ${NC}"
    BTOP_THEME="catppuccin_mocha.theme" 
    
    sed -i "s/^color_theme = .*/color_theme = \"$BTOP_THEME\"/" "$HOME/.config/btop/btop.conf"
    echo -e "${GREEN}Tema de Btop actualizado${NC}"
fi

notify-send "Tema Cambiado" "Tema Cambiado Correctamente a: $THEME" -t 3000