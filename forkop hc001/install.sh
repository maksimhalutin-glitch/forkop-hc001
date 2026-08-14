#!/bin/sh

set -e

REPO_RAW="https://raw.githubusercontent.com/maksimhalutin-glitch/forkop-hc001/main/forkop%20hc001"

FORKOP_VERSION="1.0.5"
SINGBOX_VERSION="1.12.0"

TMP_DIR="/tmp/hc001-forkop"

echo "=========================================="
echo " HC-001 Forkop Installer"
echo " OpenLumi 23.05.4 / Cortex-A7"
echo "=========================================="
echo

if [ "$(id -u)" != "0" ]; then
    echo "ERROR: Run this script as root."
    exit 1
fi

. /etc/openwrt_release

echo "Detected:"
echo "  Distribution: $DISTRIB_ID"
echo "  Release:      $DISTRIB_RELEASE"
echo "  Target:       $DISTRIB_TARGET"
echo "  Architecture: $DISTRIB_ARCH"
echo

if [ "$DISTRIB_ARCH" != "arm_cortex-a7_neon-vfpv4" ]; then
    echo "ERROR: Unsupported architecture."
    echo "Required: arm_cortex-a7_neon-vfpv4"
    echo "Detected: $DISTRIB_ARCH"
    exit 1
fi

if [ "$DISTRIB_TARGET" != "imx/cortexa7" ]; then
    echo "ERROR: Unsupported target."
    echo "Required: imx/cortexa7"
    echo "Detected: $DISTRIB_TARGET"
    exit 1
fi

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

echo "[1/5] Updating package lists..."
opkg update

echo "[2/5] Downloading Forkop..."

wget -O "$TMP_DIR/forkop.ipk" \
    "$REPO_RAW/packages/forkop_${FORKOP_VERSION}.ipk"

wget -O "$TMP_DIR/luci-app-forkop.ipk" \
    "$REPO_RAW/packages/luci-app-forkop_${FORKOP_VERSION}.ipk"

wget -O "$TMP_DIR/luci-i18n-forkop-ru.ipk" \
    "$REPO_RAW/packages/luci-i18n-forkop-ru_${FORKOP_VERSION}.ipk"

echo "[3/5] Installing Forkop..."

opkg install \
    "$TMP_DIR/forkop.ipk" \
    "$TMP_DIR/luci-app-forkop.ipk" \
    "$TMP_DIR/luci-i18n-forkop-ru.ipk"

echo "[4/5] Installing sing-box ${SINGBOX_VERSION}..."

SINGBOX_PACKAGE="sing-box_${SINGBOX_VERSION}_openwrt_arm_cortex-a7_neon-vfpv4.ipk"

SINGBOX_URL="https://github.com/SagerNet/sing-box/releases/download/v${SINGBOX_VERSION}/${SINGBOX_PACKAGE}"

wget -O "$TMP_DIR/$SINGBOX_PACKAGE" "$SINGBOX_URL"

opkg install "$TMP_DIR/$SINGBOX_PACKAGE"

echo "[5/5] Starting Forkop..."

if [ -x /etc/init.d/forkop ]; then
    /etc/init.d/forkop enable
    /etc/init.d/forkop restart
fi

rm -rf "$TMP_DIR"

echo
echo "=========================================="
echo " Installation completed!"
echo "=========================================="
echo

echo "Forkop:"
forkop show_version
forkop get_status

echo
echo "sing-box:"
sing-box version

echo
echo "Done!"
