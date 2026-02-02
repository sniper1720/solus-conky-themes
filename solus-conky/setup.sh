#!/bin/bash

# Solus Conky Theme Installer

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ ! -d "assets" ] || [ ! -f "conky.conf" ]; then
    echo -e "${BLUE}[!] It looks like you're running this script remotely.${NC}"
    echo -e "${GREEN}[+] Cloning the repository...${NC}"
    
    if ! command -v git &> /dev/null; then
        echo "Git is not installed. Please install git first."
        exit 1
    fi
    
    TEMP_DIR=$(mktemp -d)
    git clone --depth 1 https://github.com/sniper1720/solus-conky-themes.git "$TEMP_DIR"
    
    echo -e "${GREEN}[+] Repository cloned. Moving to project directory...${NC}"
    cd "$TEMP_DIR/solus-conky"
    
    bash ./setup.sh local
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
cp assets/fonts/*.ttf "$HOME/.local/share/fonts/" 2>/dev/null || echo "No fonts found in assets/fonts/"
if command -v fc-cache &> /dev/null; then
    fc-cache -fv &> /dev/null
    echo "Fonts cache updated."
fi

echo -e "\n${BLUE}=======================================${NC}"
echo -e "${BLUE}         Configuration Setup           ${NC}"
echo -e "${BLUE}=======================================${NC}"

SETTINGS_FILE="settings.lua"

echo -e "\nAvailable Network Interfaces:"
ip -o link show | awk -F': ' '{print $2}' | grep -v "lo"
echo
read -p "Enter your network interface (e.g., wlo1): " USER_INTERFACE

if [ -z "$USER_INTERFACE" ]; then
    USER_INTERFACE="wlo1"
    echo "Defaulting to wlo1"
fi

echo -e "\nSelect Theme Mode:"
echo "1) Dark (Default)"
echo "2) White"
read -p "Choice [1-2]: " THEME_CHOICE

if [ "$THEME_CHOICE" == "2" ]; then
    THEME_MODE="WHITE"
else
    THEME_MODE="DARK"
fi

echo -e "\n${GREEN}[+] Applying Configuration...${NC}"

sed -i "s/network_interface = \".*\"/network_interface = \"$USER_INTERFACE\"/" "$SETTINGS_FILE"
sed -i "s/theme_mode = \".*\"/theme_mode = \"$THEME_MODE\"/" "$SETTINGS_FILE"

echo "Configuration saved."

echo -e "\n${BLUE}=======================================${NC}"
echo -e "${BLUE}          Autostart Setup              ${NC}"
echo -e "${BLUE}=======================================${NC}"

read -p "Do you want to start this theme automatically at login? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p "$HOME/.config/autostart"
    
    cat > "$HOME/.config/autostart/solus-conky.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Solus Conky
Comment=Solus Conky Theme
Exec=conky -c $(pwd)/conky.conf --daemonize --pause=5
StartupNotify=false
Terminal=false
Hidden=false
EOF
    echo "Autostart entry created at $HOME/.config/autostart/solus-conky.desktop"
    
    echo -e "\n${GREEN}[+] Setup Complete!${NC}"
    echo "The theme will start automatically on your next login."
    
    read -p "Do you want to start it right now? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        killall conky 2>/dev/null || true
        conky -c "$(pwd)/conky.conf" --daemonize
        echo "Conky started."
    fi
else
    echo -e "\n${GREEN}[+] Setup Complete!${NC}"
    echo -e "You can start the theme manually with:"
    echo -e "  ${BLUE}conky -c $(pwd)/conky.conf${NC}"
fi

echo -e "\nEnjoy!"
