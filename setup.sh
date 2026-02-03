#!/bin/bash

# Solus Conky Theme Installer

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="$HOME/.config/solus-conky"

if [ ! -d "solus-conky/assets" ] || [ ! -f "solus-conky/conky.conf" ]; then
    echo -e "${BLUE}[!] It looks like you're running this script remotely.${NC}"
    echo -e "${GREEN}[+] Cloning the repository...${NC}"
    
    if ! command -v git &> /dev/null; then
        echo "Git is not installed. Please install git first."
        exit 1
    fi
    
    TEMP_DIR=$(mktemp -d)
    git clone --depth 1 https://github.com/sniper1720/solus-conky-themes.git "$TEMP_DIR"
    
    echo -e "${GREEN}[+] Repository cloned. Moving to project directory...${NC}"
    cd "$TEMP_DIR"
    
    bash ./setup.sh local < /dev/tty
    
    # Cleanup temp dir after install
    cd
    rm -rf "$TEMP_DIR"
    exit 0
fi

[ "$1" == "local" ] && shift

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}    Solus Conky Theme Installer        ${NC}"
echo -e "${BLUE}=======================================${NC}"

echo -e "\n${GREEN}[+] Checking Dependencies...${NC}"

if ! command -v conky &> /dev/null; then
    if [ -f /etc/solus-release ]; then
        echo "Installing Conky for Solus..."
        sudo eopkg it conky
    else
        echo -e "Conky not found.\nThis theme is designed for Solus, but can work on others."
        echo "Please install 'conky' manually using your package manager."
        exit 1
    fi
else
    echo "Conky is installed."
fi

echo -e "\n${GREEN}[+] Installing Fonts...${NC}"
mkdir -p "$HOME/.local/share/fonts"
cp solus-conky/assets/fonts/*.ttf "$HOME/.local/share/fonts/" 2>/dev/null || echo "No fonts found in solus-conky/assets/fonts/"
if command -v fc-cache &> /dev/null; then
    fc-cache -fv &> /dev/null
    echo "Fonts cache updated."
fi

echo -e "\n${GREEN}[+] Installing Theme Files...${NC}"
# Remove old install if exists
if [ -d "$INSTALL_DIR" ]; then
    echo "Removing existing installation at $INSTALL_DIR..."
    rm -rf "$INSTALL_DIR"
fi

mkdir -p "$INSTALL_DIR"
cp -r solus-conky/* "$INSTALL_DIR/"
echo "Theme installed to $INSTALL_DIR"

echo -e "\n${BLUE}=======================================${NC}"
echo -e "${BLUE}         Configuration Setup           ${NC}"
echo -e "${BLUE}=======================================${NC}"

SETTINGS_FILE="$INSTALL_DIR/settings.lua"

echo -e "\nAvailable Network Interfaces:"
ip -o link show | awk -F': ' '{print $2}' | grep -v "lo"
echo
read -p "Enter your network interface (e.g., wlo1): " USER_INTERFACE < /dev/tty

if [ -z "$USER_INTERFACE" ]; then
    USER_INTERFACE="wlo1"
    echo "Defaulting to wlo1"
fi

echo -e "\nSelect Theme Mode:"
echo "1) Dark (Default)"
echo "2) White"
read -p "Choice [1-2]: " THEME_CHOICE < /dev/tty

if [ "$THEME_CHOICE" == "2" ]; then
    THEME_MODE="WHITE"
else
    THEME_MODE="DARK"
fi

echo -e "\n${GREEN}[+] Applying Configuration...${NC}"

sed -i "s/network_interface = \".*\"/network_interface = \"$USER_INTERFACE\"/" "$SETTINGS_FILE"
sed -i "s/theme_mode = \".*\"/theme_mode = \"$THEME_MODE\"/" "$SETTINGS_FILE"
sed -i "s|lua_load = 'main.lua'|lua_load = '$INSTALL_DIR/main.lua'|" "$INSTALL_DIR/conky.conf"

echo "Configuration saved."

echo -e "\n${BLUE}=======================================${NC}"
echo -e "${BLUE}          Autostart Setup              ${NC}"
echo -e "${BLUE}=======================================${NC}"

read -p "Do you want to start this theme automatically at login? (y/N) " -n 1 -r < /dev/tty
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p "$HOME/.config/autostart"
    
    cat > "$HOME/.config/autostart/solus-conky.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Solus Conky
Comment=Solus Conky Theme
Exec=env XDG_SESSION_TYPE=x11 conky -c $INSTALL_DIR/conky.conf --daemonize --pause=5
StartupNotify=false
Terminal=false
Hidden=false
EOF
    echo "Autostart entry created at $HOME/.config/autostart/solus-conky.desktop"
    echo -e "\n${GREEN}[+] Setup Complete!${NC}"
    echo "The theme will start automatically on your next login."
else
    echo -e "\n${GREEN}[+] Setup Complete!${NC}"
fi

read -p "Do you want to start it right now? (y/N) " -n 1 -r < /dev/tty
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    killall conky 2>/dev/null || true
    env XDG_SESSION_TYPE=x11 conky -c "$INSTALL_DIR/conky.conf" --daemonize
    echo "Conky started."
else
    echo -e "You can start the theme manually with:"
    echo -e "  ${BLUE}XDG_SESSION_TYPE=x11 conky -c $INSTALL_DIR/conky.conf${NC}"
fi

echo -e "\nEnjoy!"
