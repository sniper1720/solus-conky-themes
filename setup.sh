#!/bin/bash
# Solus Conky Themes Installer

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Remote Clone Support
if [ ! -d "solus-pure-conky-wayland" ] && [ ! -d "solus-octopus-conky-x11" ]; then
    echo -e "${BLUE}Cloning the repository...${NC}"
    
    if ! command -v git &> /dev/null; then
        echo "Git is not installed. Please install git first."
        exit 1
    fi
    
    TEMP_DIR=$(mktemp -d)
    git clone --depth 1 https://github.com/sniper1720/solus-conky-themes.git "$TEMP_DIR"
    cd "$TEMP_DIR"
    bash ./setup.sh local < /dev/tty
    cd && rm -rf "$TEMP_DIR"
    exit 0
fi

[ "$1" == "local" ] && shift

echo -e "${CYAN}"
echo "  ____        _             "
echo " / ___|  ___ | |_   _ ___   "
echo " \___ \ / _ \| | | | / __|  "
echo "  ___) | (_) | | |_| \__ \  "
echo " |____/ \___/|_|\__,_|___/  "
echo -e "${NC}"
echo -e "${BLUE}    Conky Themes Installer${NC}"
echo

# Dependency Check
echo -e "${GREEN}Checking Dependencies...${NC}"

if ! command -v conky &> /dev/null; then
    if [ -f /etc/solus-release ]; then
        sudo eopkg it conky
    else
        echo "Conky not found. Please install 'conky' manually."
        exit 1
    fi
else
    echo "✓ Conky is installed."
fi

# Session Detection
echo
CURRENT_SESSION="${XDG_SESSION_TYPE:-unknown}"
echo -e "Detected session: ${CYAN}$CURRENT_SESSION${NC}"

if [ "$CURRENT_SESSION" == "wayland" ]; then
    RECOMMENDED="pure"
    echo -e "${GREEN}→ Recommended: Pure (Native Wayland)${NC}"
else
    RECOMMENDED="octopus"
    echo -e "${GREEN}→ Recommended: Octopus (X11)${NC}"
fi

# Theme Selection
echo
if [ "$RECOMMENDED" == "pure" ]; then
    echo -e "  ${GREEN}1) Pure (Native Wayland)${NC} ${YELLOW}[Recommended]${NC}"
    echo -e "     Clean, text-based theme with bars and stats."
    echo
    echo -e "  ${GREEN}2) Octopus (X11/XWayland)${NC}"
    echo -e "     Full graphics with Lua Cairo curves."
else
    echo -e "  ${GREEN}1) Octopus (X11)${NC} ${YELLOW}[Recommended]${NC}"
    echo -e "     Full graphics with Lua Cairo curves."
    echo
    echo -e "  ${GREEN}2) Pure (Text-based)${NC}"
    echo -e "     Clean, minimalist theme with bars."
fi

echo
read -p "Select theme [1-2]: " THEME_CHOICE < /dev/tty

if [ "$RECOMMENDED" == "pure" ]; then
    case $THEME_CHOICE in
        2) THEME_DIR="solus-octopus-conky-x11"; THEME_NAME="solus-octopus"; USE_LUA=true ;;
        *) THEME_DIR="solus-pure-conky-wayland"; THEME_NAME="solus-pure"; USE_LUA=false ;;
    esac
else
    case $THEME_CHOICE in
        2) THEME_DIR="solus-pure-conky-wayland"; THEME_NAME="solus-pure"; USE_LUA=false ;;
        *) THEME_DIR="solus-octopus-conky-x11"; THEME_NAME="solus-octopus"; USE_LUA=true ;;
    esac
fi

INSTALL_DIR="$HOME/.config/conky/$THEME_NAME"

echo -e "${GREEN}✓ Selected: $THEME_NAME${NC}"

if [ ! -d "$THEME_DIR" ]; then
    echo -e "${RED}Error: Theme directory '$THEME_DIR' not found.${NC}"
    exit 1
fi

# Font Installation
echo -e "\n${GREEN}Installing Fonts...${NC}"
mkdir -p "$HOME/.local/share/fonts"
if [ -d "$THEME_DIR/assets/fonts" ]; then
    cp "$THEME_DIR/assets/fonts/"*.ttf "$HOME/.local/share/fonts/" 2>/dev/null || true
fi
command -v fc-cache &> /dev/null && fc-cache -fv &> /dev/null

# Theme Installation
echo -e "${GREEN}Installing Theme...${NC}"
[ -d "$INSTALL_DIR" ] && rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cp -r "$THEME_DIR/"* "$INSTALL_DIR/"

echo "✓ Installed to $INSTALL_DIR"

# Configuration
echo -e "\n${GREEN}Configuration${NC}"

echo "Available Network Interfaces:"
ip -o link show | awk -F': ' '{print $2}' | grep -v "lo"
read -p "Enter network interface (e.g., wlan0): " USER_INTERFACE < /dev/tty
USER_INTERFACE=${USER_INTERFACE:-wlan0}

echo -e "\nScale (adjust to fit your display, e.g., 1.0, 1.2, 1.5, 2.0)"
read -p "Enter scale [1.0]: " SCALE < /dev/tty
SCALE=${SCALE:-1.0}

if [ "$USE_LUA" = true ]; then
    SETTINGS_FILE="$INSTALL_DIR/settings.lua"
    
    echo -e "\nTheme Mode: 1) Dark  2) White"
    read -p "Choice [1]: " MODE_CHOICE < /dev/tty
    [ "$MODE_CHOICE" == "2" ] && THEME_MODE="WHITE" || THEME_MODE="DARK"

    sed -i "s/network_interface = \".*\"/network_interface = \"$USER_INTERFACE\"/" "$SETTINGS_FILE"
    sed -i "s/theme_mode = \".*\"/theme_mode = \"$THEME_MODE\"/" "$SETTINGS_FILE"
    sed -i "s/scale = .*/scale = $SCALE,/" "$SETTINGS_FILE"
else
    CONFIG_FILE="$INSTALL_DIR/conky.conf"
    sed -i "s/local network_interface = \".*\"/local network_interface = \"$USER_INTERFACE\"/" "$CONFIG_FILE"
    sed -i "s/local scale = .*/local scale = $SCALE/" "$CONFIG_FILE"
fi

echo "✓ Configuration saved."

# Autostart
echo
read -p "Start at login? (y/N) " -n 1 -r < /dev/tty
echo

AUTOSTART_DIR="$HOME/.config/autostart"
DESKTOP_FILE="$AUTOSTART_DIR/solus-conky.desktop"

if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p "$AUTOSTART_DIR"
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=Solus Conky ($THEME_NAME)
Exec=conky -c $INSTALL_DIR/conky.conf
Hidden=false
X-GNOME-Autostart-enabled=true
StartupNotify=false
Terminal=false
EOF
    echo -e "${GREEN}✓ Autostart enabled.${NC}"
else
    [ -f "$DESKTOP_FILE" ] && rm -f "$DESKTOP_FILE"
fi

# Start Now
echo -e "\n${GREEN}Setup Complete!${NC}"
read -p "Start now? (y/N) " -n 1 -r < /dev/tty
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    pkill conky 2>/dev/null || true
    sleep 0.5
    conky -c "$INSTALL_DIR/conky.conf" &
    echo -e "${GREEN}✓ Conky started.${NC}"
fi

echo -e "\n${CYAN}Enjoy!${NC} Config: $INSTALL_DIR"
