#!/bin/sh

#★ XDREAMY Core Setup Engine ★

#Version: Draft v1.0 by M.Hussein

LOGFILE="/tmp/XDREAMY_Core.log"

=== Logging Functions ===

log() { printf "%s\n" "$*" | tee -a "$LOGFILE"; } log_action() { printf "    • %-55s" "$1" | tee -a "$LOGFILE"; } log_done() { echo "[ ✔ ]" | tee -a "$LOGFILE"; } log_skip() { echo "[ skipped ]" | tee -a "$LOGFILE"; } log_fail() { echo "[ ✖ ]" | tee -a "$LOGFILE"; } trap 'log "[ERROR] Line $LINENO failed. Continuing..."' ERR

=== Header ===

clear log "=================================================================" log "       ★ XDREAMY Core - Enigma2 Setup Engine ★" log "=================================================================" log "Started at: $(date)" log "Execution Mode: ${1:-unknown}" log "Log File: $LOGFILE" log "================================================================="

=== System Info ===

log "\n==> Detecting System Info..." IMAGE_NAME=$(grep -i 'distro' /etc/image-version 2>/dev/null | cut -d= -f2) BOX_MODEL=$(cat /etc/hostname) PYTHON_VERSION=$(python3 --version 2>/dev/null | awk '{print $2}') NET_IFACE=$(ip -o -4 route show to default | awk '{print $5}') LANG_CODE=$(curl -s https://ipapi.co/languages/ | cut -d',' -f1 | cut -c1-2) [ -z "$LANG_CODE" ] && LANG_CODE="en" log "✔ Image            : $IMAGE_NAME" log "✔ Box Model        : $BOX_MODEL" log "✔ Python Version   : $PYTHON_VERSION" log "✔ Interface        : $NET_IFACE" log "✔ Geolocated Lang  : $LANG_CODE"

=== Network Configuration ===

log "\n==> Configuring Network and Password..." IP_PREFIX=$(ip addr | grep 'inet 192.168' | awk '{print $2}' | cut -d. -f1-3 | head -n1) [ -z "$IP_PREFIX" ] && IP_PREFIX="192.168.1" STATIC_IP="$IP_PREFIX.10" GATEWAY="$IP_PREFIX.1" DNS1="8.8.8.8" DNS2="9.9.9.9"

cat > /etc/network/interfaces <<EOF auto lo iface lo inet loopback

auto $NET_IFACE iface $NET_IFACE inet static address $STATIC_IP netmask 255.255.255.0 gateway $GATEWAY dns-nameservers $DNS1 $DNS2 EOF /etc/init.d/networking restart >/dev/null 2>&1 && log_action "Restarting network with IP $STATIC_IP" && log_done || log_fail log_action "DNS: $DNS1 + $DNS2" && log_done echo -e "root\nroot" | passwd root >/dev/null 2>&1 && log_action "Setting root password to 'root'" && log_done || log_fail

=== Locale and Language ===

log "\n==> Locale and Language Setup..." SETTINGS_FILE="/etc/enigma2/settings" [ -f "$SETTINGS_FILE" ] && cp "$SETTINGS_FILE" "$SETTINGS_FILE.bak" sed -i '/^config.osd.language=/d' "$SETTINGS_FILE" echo "config.osd.language=en_EN" >> "$SETTINGS_FILE" log_action "Set language to en_EN" && log_done cd /usr/share/enigma2/po 2>/dev/null || true for lang in ; do [ "$lang" = "en" ] || [ "$lang" = "ar" ] || [ "$lang" = "$LANG_CODE" ] || rm -rf "$lang"; done cd /usr/share/locale 2>/dev/null || true for folder in ; do case "$folder" in en|en_|ar|ar_|$LANG_CODE|${LANG_CODE}_*) ;; *) rm -rf "$folder" ;; esac; done log_action "Cleaned unused locale languages" && log_done

=== Timezone Setup ===

log "\n==> Setting Timezone..." CITY=$(curl -s https://ipapi.co/city/) TZ=$(curl -s https://ipapi.co/timezone/) echo "$TZ" > /etc/timezone && log "✔ Location: $CITY | Timezone: $TZ" /etc/init.d/ntpd stop >/dev/null 2>&1 && log_action "Stopping NTP service" && log_done || log_skip ntpd -q -p pool.ntp.org >/dev/null 2>&1 && log_action "Time sync via NTP" && log_done || log_skip /etc/init.d/ntpd start >/dev/null 2>&1 && log_action "Restarting NTP service" && log_done || log_skip

=== Remove Bloatware ===

log "\n==> Removing Unwanted Plugins (Bloatware)..." BLOAT_PACKAGES=" enigma2-plugin-extensions-atilehd enigma2-plugin-extensions-dvdplayer enigma2-plugin-extensions-mediaplayer enigma2-plugin-extensions-pictureplayer enigma2-plugin-extensions-mediascanner enigma2-plugin-systemplugins-cablescan enigma2-plugin-systemplugins-hotplug enigma2-plugin-systemplugins-moviecut enigma2-plugin-systemplugins-cutlisteditor enigma2-plugin-systemplugins-audiosync enigma2-plugin-systemplugins-multitranscodingsetup enigma2-plugin-systemplugins-satfinder enigma2-plugin-systemplugins-crashlogautosubmit enigma2-plugin-systemplugins-frontprocessorupgrade enigma2-plugin-systemplugins-networkwizard enigma2-plugin-systemplugins-videomode enigma2-plugin-systemplugins-videotune enigma2-plugin-systemplugins-mphelp enigma2-plugin-systemplugins-videoenhancement" for pkg in $BLOAT_PACKAGES; do log_action "$pkg" opkg remove --force-depends "$pkg" >/dev/null 2>&1 && log_done || log_skip done

=== Feed Dependencies ===

log "\n==> Installing Feed Dependencies..." opkg update >/dev/null 2>&1 && log_action "Feed update" && log_done opkg upgrade >/dev/null 2>&1 && log_action "Feed upgrade" && log_done

DEPENDENCIES=" xz curl wget ntpd transmission transmission-client python3-transmission-rpc python3-beautifulsoup4 python3-pillow python3-urllib3 python3-six python3-requests python3-setuptools " for dep in $DEPENDENCIES; do log_action "$dep" opkg install "$dep" >/dev/null 2>&1 && log_done || log_skip done

=== Core Plugins (Feed) ===

log "\n==> Installing Core Feed Plugins..." CORE_PLUGINS=" enigma2-plugin-extensions-tmdb enigma2-plugin-extensions-cacheflush enigma2-plugin-extensions-epgtranslator enigma2-plugin-systemplugins-serviceapp" for plugin in $CORE_PLUGINS; do log_action "$plugin" opkg install "$plugin" >/dev/null 2>&1 && log_done || log_skip done

=== 3rd Party Plugins ===

log "\n==> Installing 3rd-Party Plugins..." wget -q https://raw.githubusercontent.com/Insprion80/Skins/main/xDreamy/installer.sh -O - | /bin/sh >/dev/null 2>&1 && log_action "XDREAMY Skin" && log_done wget -q http://dreambox4u.com/dreamarabia/Transmission_e2/Transmission_e2.sh -O - | /bin/sh >/dev/null 2>&1 && log_action "Transmission" && log_done wget -q https://raw.githubusercontent.com/AMAJamry/AJPanel/main/installer.sh -O - | /bin/sh >/dev/null 2>&1 && log_action "AJPanel" && log_done wget -q https://github.com/popking159/ssupport/raw/main/subssupport-install.sh -O - | /bin/sh >/dev/null 2>&1 && log_action "SubSSupport" && log_done wget -q https://raw.githubusercontent.com/levi-45/Manager/main/installer.sh -O - | /bin/sh >/dev/null 2>&1 && log_action "Levi Multicam Manager" && log_done wget -q https://raw.githubusercontent.com/biko-73/Ncam_EMU/main/installer.sh -O - | /bin/sh >/dev/null 2>&1 && log_action "NCAM Emulator" && log_done wget -q https://raw.githubusercontent.com/eliesat/eliesatpanel/main/installer.sh -O - | /bin/sh >/dev/null 2>&1 && log_action "EliSat Panel" && log_done

=== Apply XDREAMY Skin ===

log "\n==> Applying xDreamy Skin..." init 4 && sleep 3 && log_action "Stopping Enigma2" && log_done sed -i '/^config.skin.primary_skin=/d' "$SETTINGS_FILE" echo "config.skin.primary_skin=xDreamy/skin.xml" >> "$SETTINGS_FILE" log_action "Skin set to xDreamy/skin.xml" && log_done init 3 && log_action "Restarting Enigma2 GUI" && log_done

=== Finish ===

log "\n✔ All tasks completed." log "✔ Full log: $LOGFILE" log "🎉 XDREAMY Core completed successfully!" exit 0

