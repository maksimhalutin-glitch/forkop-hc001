#!/bin/sh

set -e

REPO_RAW="https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/HC-001-Forkop/main"

FORKOP_VERSION="1.0.5"
SINGBOX_VERSION="1.12.0"

TMP_DIR="/tmp/hc001-forkop"

echo "=========================================="
echo " HC-001 Forkop Installer"
echo " OpenLumi 23.05.4 / Cortex-A7"
echo "=========================================="
echo

# --------------------------------------------------
# Root check
# --------------------------------------------------

if [ "$(id -u)" != "0" ]; then
    echo "ERROR: run this script as root."
    exit 1
fi

# --------------------------------------------------
# Architecture check
# --------------------------------------------------

ARCH="$(. /etc/openwrt_release 2>/dev/null && echo "$DISTRIB_ARCH")"
TARGET="$(. /etc/openwrt_release 2>/dev/null && echo "$DISTRIB_TARGET")"

echo "Architecture: $ARCH"
echo "Target:       $TARGET"
echo

if [ "$ARCH" != "arm_cortex-a7_neon-vfpv4" ]; then
    echo "ERROR: unsupported architecture."
    echo "This installer is intended for:"
    echo "  arm_cortex-a7_neon-vfpv4"
    exit 1
fi

if [ "$TARGET" != "imx/cortexa7" ]; then
    echo "WARNING: target is not imx/cortexa7."
    echo "Detected: $TARGET"
    echo
    echo "Continue? [y/N]"
    read answer
    case "$answer" in
        y|Y) ;;
        *) exit 1 ;;
    esac
fi

# --------------------------------------------------
# OpenLumi check
# --------------------------------------------------

if [ -f /etc/openwrt_release ]; then
    . /etc/openwrt_release
fi

echo "Distribution: ${DISTRIB_ID:-unknown}"
echo "Release:      ${DISTRIB_RELEASE:-unknown}"
echo

if [ "${DISTRIB_ID:-}" != "OpenLumi" ]; then
    echo "WARNING: this does not appear to be OpenLumi."
    echo "Detected: ${DISTRIB_ID:-unknown}"
    echo
    echo "Continue? [y/N]"
    read answer
    case "$answer" in
        y|Y) ;;
        *) exit 1 ;;
    esac
fi

# --------------------------------------------------
# Prepare
# --------------------------------------------------

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

cd "$TMP_DIR"

echo
echo "[1/6] Updating package lists..."
opkg update

# --------------------------------------------------
# Download Forkop packages
# --------------------------------------------------

echo
echo "[2/6] Downloading Forkop ${FORKOP_VERSION}..."

wget -O forkop.ipk \
    "$REPO_RAW/packages/forkop_${FORKOP_VERSION}.ipk"

wget -O luci-app-forkop.ipk \
    "$REPO_RAW/packages/luci-app-forkop_${FORKOP_VERSION}.ipk"

wget -O luci-i18n-forkop-ru.ipk \
    "$REPO_RAW/packages/luci-i18n-forkop-ru_${FORKOP_VERSION}.ipk"

# --------------------------------------------------
# Install Forkop
# --------------------------------------------------

echo
echo "[3/6] Installing Forkop..."

opkg install \
    "$TMP_DIR/forkop.ipk" \
    "$TMP_DIR/luci-app-forkop.ipk" \
    "$TMP_DIR/luci-i18n-forkop-ru.ipk"

# --------------------------------------------------
# Download sing-box
# --------------------------------------------------

echo
echo "[4/6] Installing sing-box ${SINGBOX_VERSION}..."

SINGBOX_PACKAGE="sing-box_${SINGBOX_VERSION}_openwrt_arm_cortex-a7_neon-vfpv4.ipk"

SINGBOX_URL="https://github.com/SagerNet/sing-box/releases/download/v${SINGBOX_VERSION}/${SINGBOX_PACKAGE}"

wget -O "$TMP_DIR/$SINGBOX_PACKAGE" "$SINGBOX_URL"

opkg install "$TMP_DIR/$SINGBOX_PACKAGE"

# --------------------------------------------------
# Enable services
# --------------------------------------------------

echo
echo "[5/6] Enabling services..."

if [ -x /etc/init.d/forkop ]; then
    /etc/init.d/forkop enable
    /etc/init.d/forkop restart || true
fi

# --------------------------------------------------
# Verify
# --------------------------------------------------

echo
echo "[6/6] Checking installation..."
echo

echo "Forkop:"
if command -v forkop >/dev/null 2>&1; then
    forkop show_version
    forkop get_status
else
    echo "ERROR: Forkop command not found."
    exit 1
fi

echo
echo "sing-box:"
if command -v sing-box >/dev/null 2>&1; then
    sing-box version
else
    echo "ERROR: sing-box command not found."
    exit 1
fi

# --------------------------------------------------
# Cleanup
# --------------------------------------------------

rm -rf "$TMP_DIR"

echo
echo "=========================================="
echo " Installation completed successfully!"
echo "=========================================="
echo
echo "Forkop:"
forkop show_version
echo
echo "sing-box:"
sing-box version
echo
echo "Forkop status:"
forkop get_status
echos