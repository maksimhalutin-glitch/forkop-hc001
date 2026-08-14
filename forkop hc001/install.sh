#!/bin/sh

set -e

# ============================================================
# HC-001 Forkop Installer
# OpenLumi 23.05.4 / i.MX Cortex-A7
# ============================================================

REPO_RAW="https://raw.githubusercontent.com/maksimhalutin-glitch/forkop-hc001/main/forkop%20hc001"

FORKOP_VERSION="1.0.5"
SINGBOX_VERSION="1.12.0"

TMP_DIR="/tmp/hc001-forkop"

echo
echo "=========================================="
echo "        HC-001 Forkop Installer"
echo "=========================================="
echo

# ------------------------------------------------------------
# Root check
# ------------------------------------------------------------

if [ "$(id -u)" != "0" ]; then
    echo "ERROR: This installer must be run as root."
    exit 1
fi

# ------------------------------------------------------------
# Read OpenWrt/OpenLumi information
# ------------------------------------------------------------

if [ ! -f /etc/openwrt_release ]; then
    echo "ERROR: /etc/openwrt_release not found."
    echo "This does not appear to be OpenWrt/OpenLumi."
    exit 1
fi

. /etc/openwrt_release

echo "Detected system:"
echo "  Distribution : ${DISTRIB_ID}"
echo "  Release      : ${DISTRIB_RELEASE}"
echo "  Target       : ${DISTRIB_TARGET}"
echo "  Architecture : ${DISTRIB_ARCH}"
echo

# ------------------------------------------------------------
# Architecture check
# ------------------------------------------------------------

if [ "${DISTRIB_ARCH}" != "arm_cortex-a7_neon-vfpv4" ]; then
    echo "ERROR: Unsupported architecture."
    echo
    echo "Required:"
    echo "  arm_cortex-a7_neon-vfpv4"
    echo
    echo "Detected:"
    echo "  ${DISTRIB_ARCH}"
    exit 1
fi

if [ "${DISTRIB_TARGET}" != "imx/cortexa7" ]; then
    echo "ERROR: Unsupported OpenWrt target."
    echo
    echo "Required:"
    echo "  imx/cortexa7"
    echo
    echo "Detected:"
    echo "  ${DISTRIB_TARGET}"
    exit 1
fi

echo "Architecture check: OK"
echo "Target check:       OK"
echo

# ------------------------------------------------------------
# Prepare temporary directory
# ------------------------------------------------------------

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

# ------------------------------------------------------------
# Update package lists
# ------------------------------------------------------------

echo "[1/6] Updating package lists..."

opkg update

echo

# ------------------------------------------------------------
# Download Forkop packages
# ------------------------------------------------------------

echo "[2/6] Downloading Forkop ${FORKOP_VERSION}..."

wget -q --show-progress \
    -O "${TMP_DIR}/forkop.ipk" \
    "${REPO_RAW}/packages/forkop_${FORKOP_VERSION}.ipk"

wget -q --show-progress \
    -O "${TMP_DIR}/luci-app-forkop.ipk" \
    "${REPO_RAW}/packages/luci-app-forkop_${FORKOP_VERSION}.ipk"

wget -q --show-progress \
    -O "${TMP_DIR}/luci-i18n-forkop-ru.ipk" \
    "${REPO_RAW}/packages/luci-i18n-forkop-ru_${FORKOP_VERSION}.ipk"

echo
echo "Forkop packages downloaded."
echo

# ------------------------------------------------------------
# Install Forkop
# ------------------------------------------------------------

echo "[3/6] Installing Forkop ${FORKOP_VERSION}..."

opkg install \
    "${TMP_DIR}/forkop.ipk" \
    "${TMP_DIR}/luci-app-forkop.ipk" \
    "${TMP_DIR}/luci-i18n-forkop-ru.ipk"

echo
echo "Forkop installed."
echo

# ------------------------------------------------------------
# Download sing-box
# ------------------------------------------------------------

echo "[4/6] Downloading sing-box ${SINGBOX_VERSION}..."

SINGBOX_PACKAGE="sing-box_${SINGBOX_VERSION}_openwrt_arm_cortex-a7_neon-vfpv4.ipk"

SINGBOX_URL="https://github.com/SagerNet/sing-box/releases/download/v${SINGBOX_VERSION}/${SINGBOX_PACKAGE}"

wget -q --show-progress \
    -O "${TMP_DIR}/${SINGBOX_PACKAGE}" \
    "${SINGBOX_URL}"

echo
echo "sing-box package downloaded."
echo

# ------------------------------------------------------------
# Install sing-box
# ------------------------------------------------------------

echo "[5/6] Installing sing-box ${SINGBOX_VERSION}..."

opkg install "${TMP_DIR}/${SINGBOX_PACKAGE}"

echo
echo "sing-box installed."
echo

# ------------------------------------------------------------
# Enable and restart Forkop
# ------------------------------------------------------------

echo "[6/6] Enabling Forkop..."

if [ -x /etc/init.d/forkop ]; then
    /etc/init.d/forkop enable
    /etc/init.d/forkop restart
else
    echo "ERROR: /etc/init.d/forkop not found."
    exit 1
fi

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------

rm -rf "${TMP_DIR}"

# ------------------------------------------------------------
# Verification
# ------------------------------------------------------------

echo
echo "=========================================="
echo "           Installation complete"
echo "=========================================="
echo

echo "Forkop version:"
forkop show_version

echo
echo "sing-box version:"
sing-box version

echo
echo "Forkop status:"
forkop get_status

echo

if forkop get_status 2>/dev/null | grep -q '"running": 1'; then
    echo "SUCCESS: Forkop is running."
else
    echo "WARNING: Forkop was installed, but its status could not be confirmed as running."
fi

echo
echo "=========================================="
echo "              HC-001 READY"
echo "=========================================="
echo
