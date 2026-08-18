# ✨ Pixie SDDM (Legacy Qt5 Branch)

> [!WARNING]
> This is the **Legacy Qt5 Branch**. If you are on a modern system (Fedora 40+, Arch, NixOS, etc.), please use the [**main branch (Qt6)**](https://github.com/xCaptaiN09/pixie-sddm) for the best quality and compatibility.

A clean, modern, and minimal SDDM theme inspired by Google Pixel UI and Material Design 3. 

---

## 🌟 Features (Qt5)

- **Pixel Aesthetic:** Clean typography and a unique two-tone stacked clock.
- **Material You Dynamic Colors:** Intelligent color extraction that samples your wallpaper for UI accents.
- **Universal Circle Avatar:** A bulletproof, anti-aliased circular profile mask.
- **Material Design 3:** Dark card UI with smooth interactions and responsive dropdowns.
- **Keyboard Navigation:** Full support for navigating menus with arrows and `Enter`.

---

## 🧩 Compatibility

Pixie ships as two independent pieces:

- **SDDM theme** (`src/`) — the login screen shown at boot/logout.
- **KDE lock screen** (`lockscreen/`, installed by `install-lockscreen.sh`) — the
  session lock (`Super+L`), KDE Plasma 5 only.

### By OS

| OS | SDDM greeter | Qt | Branch | Install |
|---|---|---|---|---|
| NixOS | `sddm-greeter-qt6` | Qt6 | `main` | `flake.nix` |
| Arch | `sddm-greeter-qt6` | Qt6 | `main` | `install.sh` |
| Debian | `sddm-greeter` | Qt5 | `qt5` | `install.sh` |
| Kubuntu | `sddm-greeter` | Qt5 | `qt5` | `install.sh` |

`install.sh` auto-detects the installed greeter (`sddm-greeter-qt6` vs
`sddm-greeter`) and checks out the matching branch; on NixOS it points you to
the declarative flake instead.

### By display server

- **SDDM theme** — works on both X11 and Wayland: it is pure QML with no
  display-specific code. Wayland availability depends on SDDM itself (the
  Wayland greeter exists since SDDM 0.20 and is still experimental), not on the
  theme.
- **KDE lock screen** — works on both X11 and Wayland (`kscreenlocker`/KWin).

### Summary matrix

| Component | Nix | Arch | Debian | Kubuntu | X11 | Wayland | Limit |
|---|---|---|---|---|---|---|---|
| SDDM theme | ✓ (flake, Qt6) | ✓ (Qt6) | ✓ (Qt5) | ✓ (Qt5) | ✓ | ✓ (SDDM 0.20+) | branch by greeter Qt |
| Lock screen | ✗¹ | ✓ (Plasma 5) | ✓ (Plasma 5) | ✓ (Plasma 5.27) | ✓ | ✓ | KDE Plasma 5 only |

¹ Possible on NixOS with Plasma 5 set up manually, but the flake does not
package the lock screen port.

The lock screen is **not** available for GNOME, Hyprland, sway or plain X11
window managers — those use their own lockers (`gdm`/`gnome-shell`, `hyprlock`,
`swaylock`, `i3lock`, …), and Pixie has no port for them. The SDDM theme, in
contrast, runs before any session and is desktop-environment agnostic.

---

## 🛠 1. Prerequisites (Qt5)

Before installing, ensure you have the required Qt5 modules installed to avoid a black screen:

```bash
# Ubuntu / Debian / Mint:
sudo apt update && sudo apt install qml-module-qtgraphicaleffects qml-module-qtquick-controls2

# Arch Linux:
sudo pacman -S qt5-graphicaleffects qt5-quickcontrols2
```

---

## 📦 2. Installation

> [!TIP]
> The **Automatic Script** will intelligently detect your system and switch to this branch if needed.

### Method A: Automatic Script (Recommended)
```bash
git clone https://github.com/xCaptaiN09/pixie-sddm.git
cd pixie-sddm
sudo ./install.sh
```

### Method B: Manual
1. Copy the theme source and bundled fonts into the SDDM themes directory:
   ```bash
   sudo mkdir -p /usr/share/sddm/themes/pixie/assets/fonts
   sudo cp -r src/* /usr/share/sddm/themes/pixie/
   sudo cp LICENSE /usr/share/sddm/themes/pixie/
   sudo cp vendor/fonts/FlexRounded-*.ttf vendor/fonts/MaterialDesignIcons.ttf /usr/share/sddm/themes/pixie/assets/fonts/
   ```
2. Set the theme in `/etc/sddm.conf`:
   ```ini
   [Theme]
   Current=pixie
   ```

---

## 🛠 Configuration & Testing

### Preview Without Logging Out
Run this command to preview the theme safely:
```bash
sddm-greeter --test-mode --theme /usr/share/sddm/themes/pixie
```

### Customization
Edit `src/theme.conf` or replace assets in `src/assets/`:
- **Wallpaper:** Replace `src/assets/background.jpg`.
- **Avatar:** Replace `src/assets/avatar.jpg`.

## 🤝 Credits

- **Author:** [xCaptaiN09](https://github.com/xCaptaiN09)
- **Design:** Inspired by Google Pixel and MD3.
- **Font:** Google Sans Flex (included).

---
*Made with ❤️ for the Linux community.*
