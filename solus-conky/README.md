
# Solus Conky Theme (Modernized)

Originally created in 2016, I have completely modernized the classic Octupi/Solus theme, refactoring the codebase to utilize the latest Lua API and Cairo graphics engine for enhanced stability and high-performance rendering.

## Features
- **Visuals**: A sleek, Octupi-inspired dashboard design featuring CPU, RAM, Network, and Disk stats.
- **Unified Theme**: Switch between **Dark** and **Light** modes (previously separate themes) via the `settings.lua` configuration module.
- **Native Wayland**: Automatically detects your session (Wayland/X11) and adapts natively.
- **Performance**: Optimized Lua code that uses Cairo graphics for smooth rendering.
- **Configuration**: One simple file (`settings.lua`) controls everything.

## Quick Start (Automated Install)

The setup script handles everything: **Dependencies, Fonts, Configuration, and Autostart**.

```bash
curl -sL https://raw.githubusercontent.com/sniper1720/solus-conky-themes/main/solus-conky/setup.sh | bash
```

*Simply follow the on-screen prompts to select your theme preference (Dark/Light) and network interface.*

## Manual Installation (Alternative)

**Only use this if you prefer manual setup over the script.**

### 1. Dependencies
This theme is primarily designed for **Solus**, but works on any distro with Conky (Lua + Cairo enabled).

**Solus**
```bash
sudo eopkg it conky
```

*Note: For Arch, Debian, Ubuntu, etc., install `conky` via your package manager.*

### 2. Fonts & Assets
```bash
mkdir -p ~/.local/share/fonts
cp assets/fonts/*.ttf ~/.local/share/fonts/
fc-cache -fv
```

### 3. Configuration
Edit `settings.lua` manually to match your system:

```lua
return {
    -- Window Dimensions
    width = 1366,
    height = 748,

    -- Network Interface (ip link)
    network_interface = "wlo1",

    -- Theme Mode: "DARK" or "WHITE"
    theme_mode = "DARK",
}
```

### 4. Usage
```bash
# Run from the theme directory
conky -c conky.conf
```

## Technical Details

For developers or power users who want to extend the theme:

### Architecture
- **conky.conf**: The entry point. Defines the window properties, refresh rates, and hooks into `main.lua`.
- **main.lua**: The core logic.
    - Uses `cairo` for drawing 2D vector graphics (rings, shapes).
    - Implements a `conky_main()` hook that runs every update cycle.
    - Dynamically loads assets based on the `settings.theme_mode`.
- **settings.lua**: A pure Lua module returning a table. Decouples config from logic.

### Customization
To add new rings or modify graphics, edit `conky_main()` in `main.lua`. The `draw_section()` helper function handles the geometry for standard rings:

```lua
-- Example: Adding a new ring at 250 degrees
draw_section(250, "LABEL", "Value", "icon_name", is_gauge_boolean, gauge_value)
```

## ❤️ Support the Project

If you find this theme helpful, there are many ways to support the project:

### Financial Support
If you'd like to support the development financially:

<a href="https://www.buymeacoffee.com/linuxtechmore"><img src="https://img.shields.io/badge/Fuel%20the%20next%20commit-f1fa8c?style=for-the-badge&logo=buy-me-a-coffee&logoColor=282a36" height="32" /></a>
<a href="https://github.com/sponsors/sniper1720"><img src="https://img.shields.io/badge/Become%20a%20Sponsor-bd93f9?style=for-the-badge&logo=github&logoColor=white" height="32" /></a>

#### Bitcoin (BTC) Support
<img src="https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=1ALZQ6F2CkjQMP8rJrUnXgfVdWwbc6RPYu" alt="BTC QR Code" width="150" />

```text
1ALZQ6F2CkjQMP8rJrUnXgfVdWwbc6RPYu
```

### Contribute & Support
Financial contributions are not the only way to help! Here are other options:
- **Star the Repository**: It helps more people find the project!
- **Report Bugs**: Found an issue? Open a ticket on GitHub.
- **Suggest Features**: Have a cool idea? Let me know!
- **Share**: Tell your friends!

Every bit of support helps keep the project alive and ensures I can spend more time developing open source tools for the Linux community!

## License

This project is licensed under the **GPL-3.0 License**. See the [LICENSE](../LICENSE) file for details.
