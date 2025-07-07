#!/bin/sh
# XDREAMY Core Setup Script - Part of XDREAMY AiO
# Version: Draft by M.Hussein

LOGFILE="/tmp/XDREAMY_AiO.log"

# === Logging Functions ===
log() {
  printf "%s\n" "$*" | tee -a "$LOGFILE"
}

log_action() {
  printf "    • %-55s" "$1" | tee -a "$LOGFILE"
}

log_done() {
  echo "[ ✔ ]" | tee -a "$LOGFILE"
}

log_skip() {
  echo "[ skipped ]" | tee -a "$LOGFILE"
}

log_fail() {
  echo "[ ✖ ]" | tee -a "$LOGFILE"
}

trap 'log "[ERROR] Line $LINENO failed. Continuing..."' ERR

# === Header ===
clear
log "==========================================================="
log "         ★ XDREAMY Core - System Setup in Progress ★"
log "==========================================================="
log "Started at: $(date)"
log ""

# === System Info ===
IMAGE_NAME=$(grep -i 'distro' /etc/image-version 2>/dev/null | cut -d= -f2)
BOX_MODEL=$(cat /etc/hostname)
PYTHON_VERSION=$(python3 --version 2>/dev/null | awk '{print $2}')
NET_IFACE=$(ip -o -4 route show to default | awk '{print $5}')
LANG_CODE=$(curl -s https://ipapi.co/languages/ | cut -d',' -f1 | cut -c1-2)
[ -z "$LANG_CODE" ] && LANG_CODE="en"

log "✔ Image            : $IMAGE_NAME"
log "✔ Box Model        : $BOX_MODEL"
log "✔ Python           : $PYTHON_VERSION"
log "✔ Network Interface: $NET_IFACE"
log "✔ Local Language   : $LANG_CODE"
log ""

# === Network Setup ===
log "==> Setting Network IP and DNS..."

IP_PREFIX=$(ip addr | grep 'inet 192.168' | awk '{print $2}' | cut -d. -f1-3 | head -n1)
[ -z "$IP_PREFIX" ] && IP_PREFIX="192.168.1"
STATIC_IP="${IP_PREFIX}.10"
GATEWAY="${IP_PREFIX}.1"
DNS1="8.8.8.8"
DNS2="9.9.9.9"

cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto $NET_IFACE
iface $NET_IFACE inet static
    address $STATIC_IP
    netmask 255.255.255.0
    gateway $GATEWAY
    dns-nameservers $DNS1 $DNS2
EOF

/etc/init.d/networking restart >/dev/null 2>&1 && log_action "Restarting networking service" && log_done || log_fail
log_action "Static IP set to $STATIC_IP" && log_done
log_action "DNS servers set: $DNS1, $DNS2" && log_done

echo -e "root\nroot" | passwd root >/dev/null 2>&1 && log_action "Set root password to 'root'" && log_done || log_fail
log ""

# === Locale Setup ===
log "==> Language and Locale Configuration..."

SETTINGS_FILE="/etc/enigma2/settings"
[ -f "$SETTINGS_FILE" ] && cp "$SETTINGS_FILE" "$SETTINGS_FILE.bak"
sed -i '/^config.osd.language=/d' "$SETTINGS_FILE"
echo "config.osd.language=en_EN" >> "$SETTINGS_FILE"
log_action "OSD language set to en_EN" && log_done

cd /usr/share/enigma2/po 2>/dev/null || true
for lang in *; do
  [ "$lang" = "en" ] || [ "$lang" = "ar" ] || [ "$lang" = "$LANG_CODE" ] || rm -rf "$lang"
done
cd /usr/share/locale 2>/dev/null || true
for folder in *; do
  case "$folder" in
    en|en_*|ar|ar_*|$LANG_CODE|${LANG_CODE}_*) ;;
    *) rm -rf "$folder" ;;
  esac
done
log_action "Removed unused language files" && log_done
log ""

# === Timezone Setup ===
log "==> Setting Location and Timezone..."

CITY=$(curl -s https://ipapi.co/city/)
TZ=$(curl -s https://ipapi.co/timezone/)
log "✔ City Detected     : $CITY"
log "✔ Timezone Detected : $TZ"

echo "$TZ" > /etc/timezone 2>/dev/null && log_action "Timezone written to /etc/timezone" && log_done
/etc/init.d/ntpd stop >/dev/null 2>&1 && log_action "NTPD stopped" && log_done || log_skip
ntpd -q -p pool.ntp.org >/dev/null 2>&1 && log_action "Time synced via NTP" && log_done || log_skip
/etc/init.d/ntpd start >/dev/null 2>&1 && log_action "NTPD restarted" && log_done || log_skip
log ""

# === Bloatware Removal ===
log "==> Removing Bloatware..."
BLOAT_PACKAGES="
enigma2-plugin-extensions-dvdplayer
enigma2-plugin-extensions-mediaplayer
enigma2-plugin-extensions-pictureplayer
enigma2-plugin-extensions-mediascanner
enigma2-plugin-systemplugins-cablescan
enigma2-plugin-systemplugins-hotplug
enigma2-plugin-systemplugins-networkwizard
enigma2-plugin-systemplugins-videotune
"
for pkg in $BLOAT_PACKAGES; do
  log_action "$pkg"
  opkg remove --force-depends "$pkg" >/dev/null 2>&1 && log_done || log_skip
done
log ""

# === Feed Update ===
log "==> Updating Feed..."
opkg update >/dev/null 2>&1 && log_action "Feed update" && log_done
opkg upgrade >/dev/null 2>&1 && log_action "Feed upgrade" && log_done
log ""

# === Define Plugin Sets ===
DEPENDENCIES_FEED="
xz curl wget ntpd
python3-beautifulsoup4 python3-requests
python3-pillow python3-six python3-setuptools
"

ESSENTIAL_PLUGINS="
transmission transmission-client
python3-transmission-rpc
enigma2-plugin-extensions-tmdb
enigma2-plugin-extensions-cacheflush
enigma2-plugin-extensions-epgtranslator
enigma2-plugin-systemplugins-serviceapp
"

THIRD_PARTY_PLUGINS="
https://raw.githubusercontent.com/Insprion80/Skins/main/xDreamy/installer.sh
https://raw.githubusercontent.com/AMAJamry/AJPanel/main/installer.sh
https://github.com/popking159/ssupport/raw/main/subssupport-install.sh
https://raw.githubusercontent.com/levi-45/Manager/main/installer.sh
https://raw.githubusercontent.com/biko-73/Ncam_EMU/main/installer.sh
https://raw.githubusercontent.com/eliesat/eliesatpanel/main/installer.sh
"

# === Install Plugin Sets ===
install_plugins() {
  for pkg in $1; do
    log_action "$pkg"
    opkg install "$pkg" >/dev/null 2>&1 && log_done || log_skip
  done
}

install_third_party() {
  for url in $1; do
    name=$(basename "$url")
    wget -q "$url" -O - | /bin/sh >/dev/null 2>&1 && log_action "$name" && log_done || log_skip
  done
}

# === Detect Install Mode ===
MODE="$1"
if [ "$MODE" = "--custom" ]; then
  log "==> Custom Install Mode"
  echo "• Installing: Dependencies Only..."
  install_plugins "$DEPENDENCIES_FEED"
  echo "• Installing: Essential Plugins..."
  install_plugins "$ESSENTIAL_PLUGINS"
  echo "• Installing: 3rd Party Plugins..."
  install_third_party "$THIRD_PARTY_PLUGINS"
else
  log "==> Express Install Mode (All Sets)"
  install_plugins "$DEPENDENCIES_FEED"
  install_plugins "$ESSENTIAL_PLUGINS"
  install_third_party "$THIRD_PARTY_PLUGINS"
fi

# === Apply Skin ===
log ""
log "==> Setting xDreamy as default skin"
[ -f "$SETTINGS_FILE" ] && sed -i '/^config.skin.primary_skin=/d' "$SETTINGS_FILE"
echo "config.skin.primary_skin=xDreamy/skin.xml" >> "$SETTINGS_FILE"
init 4 && sleep 4 && log_action "Stopping Enigma2" && log_done
init 3 && log_action "Starting Enigma2" && log_done

# === Done ===
log ""
log "✔ All setup tasks complete."
log "✔ Log saved to $LOGFILE"
log "🎉 Enjoy xDreamy on your device!"

exit 0
