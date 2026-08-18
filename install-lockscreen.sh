#!/bin/bash

# Pixie SDDM - KDE Plasma 5 Lock Screen installer
# Author: xCaptaiN09
#
# Installs the pixie-style kscreenlocker theme. The lock screen is provided by
# the "Plasma/LookAndFeel" package that the active theme falls back to
# (org.kde.breeze.desktop on a default install). We copy that whole package to
# the user data dir and swap in the pixie lock screen, so the system theme files
# are never touched (and survive package updates). No root required.
#
#   ./install-lockscreen.sh              install
#   ./install-lockscreen.sh --uninstall  restore the previous lock screen

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$REPO_DIR/lockscreen"
VENDOR_FONTS_DIR="$REPO_DIR/vendor/fonts"
SYSTEM_LNF_ROOT="/usr/share/plasma/look-and-feel"
USER_LNF_ROOT="$HOME/.local/share/plasma/look-and-feel"
DEFAULT_LNF="org.kde.breeze.desktop"

# ---- resolve the look-and-feel package that actually provides the lock screen ----
resolve_lockscreen_package() {
    local active=""
    for f in "$HOME/.config/kdeglobals" "/etc/xdg/kdeglobals"; do
        if [ -f "$f" ]; then
            active="$(sed -n 's/^LookAndFeelPackage=//p' "$f" | tail -n1)"
            [ -n "$active" ] && break
        fi
    done
    [ -z "$active" ] && active="$DEFAULT_LNF"

    # If the active theme ships its own lockscreen, target it; otherwise use the
    # universal fallback package.
    if [ -d "$SYSTEM_LNF_ROOT/$active/contents/lockscreen" ]; then
        echo "$active"
    else
        echo "$DEFAULT_LNF"
    fi
}

PACKAGE="$(resolve_lockscreen_package)"
USER_PKG="$USER_LNF_ROOT/$PACKAGE"
SYSTEM_PKG="$SYSTEM_LNF_ROOT/$PACKAGE"
TARGET="$USER_PKG/contents/lockscreen"
BACKUP="$USER_LNF_ROOT/$PACKAGE.pixie-backup"

echo -e "${BLUE}==>${NC} Lock screen package resolved to: ${GREEN}$PACKAGE${NC}"

uninstall() {
    echo -e "${BLUE}==>${NC} Restoring previous lock screen for ${GREEN}$PACKAGE${NC}..."
    rm -rf "$USER_PKG"
    if [ -d "$BACKUP" ]; then
        mv "$BACKUP" "$USER_PKG"
        echo -e "${GREEN}Done!${NC} Previous lock screen restored."
    else
        echo -e "${GREEN}Done!${NC} User override removed (system lock screen will be used)."
    fi
}

if [ "$1" = "--uninstall" ]; then
    uninstall
    exit 0
fi

if [ ! -f "$SOURCE_DIR/LockScreen.qml" ]; then
    echo -e "${RED}Error:${NC} lockscreen sources not found at $SOURCE_DIR"
    exit 1
fi

if [ ! -d "$SYSTEM_PKG" ]; then
    echo -e "${RED}Error:${NC} system package not found at $SYSTEM_PKG"
    exit 1
fi

echo -e "${BLUE}==>${NC} Installing Pixie lock screen to ${TARGET}..."

mkdir -p "$USER_LNF_ROOT"

# Preserve any pre-existing user override so uninstall can restore it.
if [ -d "$USER_PKG" ] && [ ! -d "$BACKUP" ]; then
    echo -e "${YELLOW}==>${NC} Backing up existing override to $BACKUP"
    mv "$USER_PKG" "$BACKUP"
fi

# Copy the whole fallback package (metadata.json + contents) so other
# look-and-feel components (logout, splash, osd...) keep working.
rm -rf "$USER_PKG"
cp -r "$SYSTEM_PKG" "$USER_PKG"

# Swap in the pixie lock screen.
rm -rf "$TARGET"
mkdir -p "$TARGET"
cp -r "$SOURCE_DIR"/* "$TARGET/"
mkdir -p "$TARGET/assets/fonts"
cp "$VENDOR_FONTS_DIR"/FlexRounded-*.ttf "$VENDOR_FONTS_DIR"/MaterialDesignIcons.ttf "$TARGET/assets/fonts/"
chmod -R 755 "$USER_PKG"

echo -e "${GREEN}Done!${NC} Pixie lock screen is installed."

echo -e ""
echo -e "Test it now with:"
echo -e "  ${BLUE}kscreenlocker_greet --testing${NC}"
echo -e "  (full path may be needed, e.g. ${BLUE}/usr/lib/x86_64-linux-gnu/libexec/kscreenlocker_greet --testing${NC})"
echo -e ""
echo -e "Then lock your session with ${BLUE}loginctl lock-session${NC} or ${BLUE}Super+L${NC}."
echo -e ""
echo -e "To revert: ${BLUE}./install-lockscreen.sh --uninstall${NC}"
