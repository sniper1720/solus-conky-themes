#!/bin/bash

# Solus Conky Theme Installer
# Supports both X11 and native Wayland

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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
    
    cd
    rm -rf "$TEMP_DIR"
    exit 0
fi

[ "$1" == "local" ] && shift

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}    Solus Conky Theme Installer        ${NC}"
echo -e "${BLUE}=======================================${NC}"

# ─────────────────────────────────────────────────────────────────────────────
# Dependency Check
# ─────────────────────────────────────────────────────────────────────────────
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

# ─────────────────────────────────────────────────────────────────────────────
# Font Installation
# ─────────────────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}[+] Installing Fonts...${NC}"
mkdir -p "$HOME/.local/share/fonts"
cp solus-conky/assets/fonts/*.ttf "$HOME/.local/share/fonts/" 2>/dev/null || echo "No fonts found in solus-conky/assets/fonts/"
if command -v fc-cache &> /dev/null; then
    fc-cache -fv &> /dev/null
    echo "Fonts cache updated."
fi

# ─────────────────────────────────────────────────────────────────────────────
# Theme Installation
# ─────────────────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}[+] Installing Theme Files...${NC}"
if [ -d "$INSTALL_DIR" ]; then
    echo "Removing existing installation at $INSTALL_DIR..."
    rm -rf "$INSTALL_DIR"
fi

mkdir -p "$INSTALL_DIR"
cp -r solus-conky/* "$INSTALL_DIR/"
echo "Theme installed to $INSTALL_DIR"

# ─────────────────────────────────────────────────────────────────────────────
# Configuration Setup
# ─────────────────────────────────────────────────────────────────────────────
echo -e "\n${BLUE}=======================================${NC}"
echo -e "${BLUE}         Configuration Setup           ${NC}"
echo -e "${BLUE}=======================================${NC}"

SETTINGS_FILE="$INSTALL_DIR/settings.lua"

# Network Interface
echo -e "\nAvailable Network Interfaces:"
ip -o link show | awk -F': ' '{print $2}' | grep -v "lo"
echo
read -p "Enter your network interface (e.g., wlo1): " USER_INTERFACE < /dev/tty

if [ -z "$USER_INTERFACE" ]; then
    USER_INTERFACE="wlo1"
    echo "Defaulting to wlo1"
fi

# Theme Mode
echo -e "\nSelect Theme Mode:"
echo "1) Dark (Default)"
echo "2) White"
read -p "Choice [1-2]: " THEME_CHOICE < /dev/tty

if [ "$THEME_CHOICE" == "2" ]; then
    THEME_MODE="WHITE"
else
    THEME_MODE="DARK"
fi

# Scaling Factor
echo -e "\n${GREEN}[+] Scaling Configuration...${NC}"
read -p "Enter Scaling Factor (1.0 for 1080p, 1.5 for 2K, 2.0 for 4K) [1.0]: " SCALE < /dev/tty
SCALE=${SCALE:-1.0}
SCALE=$(echo "$SCALE" | sed 's/\[//g; s/\]//g')

# ─────────────────────────────────────────────────────────────────────────────
# Display Server Selection
# ─────────────────────────────────────────────────────────────────────────────
echo -e "\n${BLUE}=======================================${NC}"
echo -e "${BLUE}      Display Server Selection         ${NC}"
echo -e "${BLUE}=======================================${NC}"

CURRENT_SESSION="${XDG_SESSION_TYPE:-unknown}"
echo -e "\nDetected session: ${YELLOW}$CURRENT_SESSION${NC}"
echo
echo -e "${YELLOW}NOTE: Lua ring graphics REQUIRE X11 mode.${NC}"
echo -e "${YELLOW}Native Wayland only displays text (no rings).${NC}"
echo

echo "Select Display Server Mode:"
echo "1) X11/XWayland (Recommended - Full graphics)"
echo "2) Native Wayland (Text only, no rings)"
read -p "Choice [1-2]: " DS_CHOICE < /dev/tty

FORCE_X11="true"
USE_ENV_OVERRIDE="yes"

case $DS_CHOICE in
    2)
        FORCE_X11="false"
        USE_ENV_OVERRIDE="no"
        echo -e "${YELLOW}Using native Wayland (text only, no rings).${NC}"
        ;;
    *)
        FORCE_X11="true"
        USE_ENV_OVERRIDE="yes"
        echo -e "${GREEN}Using X11 mode via XWayland (full graphics).${NC}"
        ;;
esac

# ─────────────────────────────────────────────────────────────────────────────
# Apply Configuration
# ─────────────────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}[+] Applying Configuration...${NC}"

sed -i "s/network_interface = \".*\"/network_interface = \"$USER_INTERFACE\"/" "$SETTINGS_FILE"
sed -i "s/theme_mode = \".*\"/theme_mode = \"$THEME_MODE\"/" "$SETTINGS_FILE"
sed -i "s/scale = .*/scale = $SCALE,/" "$SETTINGS_FILE"
sed -i "s/force_x11 = .*/force_x11 = $FORCE_X11,/" "$SETTINGS_FILE"

echo "Configuration saved."

# ─────────────────────────────────────────────────────────────────────────────
# Autostart Setup
# ─────────────────────────────────────────────────────────────────────────────
echo -e "\n${BLUE}=======================================${NC}"
echo -e "${BLUE}          Autostart Setup              ${NC}"
echo -e "${BLUE}=======================================${NC}"

read -p "Do you want to start this theme automatically at login? (y/N) " -n 1 -r < /dev/tty
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p "$HOME/.config/autostart"
    
    if [ "$USE_ENV_OVERRIDE" == "yes" ]; then
        EXEC_CMD="env XDG_SESSION_TYPE=x11 conky -c $INSTALL_DIR/conky.conf --daemonize --pause=5"
    else
        EXEC_CMD="conky -c $INSTALL_DIR/conky.conf --daemonize --pause=5"
    fi
    
    cat > "$HOME/.config/autostart/solus-conky.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Solus Conky
Comment=Solus Conky Theme
Exec=$EXEC_CMD
StartupNotify=false
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
EOF
    echo "Autostart entry created at $HOME/.config/autostart/solus-conky.desktop"
    echo -e "\n${GREEN}[+] Setup Complete!${NC}"
    echo "The theme will start automatically on your next login."
else
    echo -e "\n${GREEN}[+] Setup Complete!${NC}"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Start Now
# ─────────────────────────────────────────────────────────────────────────────
read -p "Do you want to start it right now? (y/N) " -n 1 -r < /dev/tty
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    killall conky 2>/dev/null || true
    
    if [ "$USE_ENV_OVERRIDE" == "yes" ]; then
        env XDG_SESSION_TYPE=x11 conky -c "$INSTALL_DIR/conky.conf" --daemonize
    else
        conky -c "$INSTALL_DIR/conky.conf" --daemonize
    fi
    
    echo "Conky started."
else
    if [ "$USE_ENV_OVERRIDE" == "yes" ]; then
        echo -e "You can start the theme manually with:"
        echo -e "  ${BLUE}XDG_SESSION_TYPE=x11 conky -c $INSTALL_DIR/conky.conf${NC}"
    else
        echo -e "You can start the theme manually with:"
        echo -e "  ${BLUE}conky -c $INSTALL_DIR/conky.conf${NC}"
    fi
fi

echo -e "\nEnjoy!"
