#!#!/bin/sh
# ★ XDREAMY AiO - Enigma2 Setup Wizard Launcher ★
# Version: Draft by M.Hussein

# Entry point for Express or Custom setup

LOGFILE="/tmp/XDREAMY_AiO.log"
CHOICE=""

clear
printf "\n\n"
echo "############################################################"
echo "      ★ XDREAMY AiO - Enigma2 Universal Setup Wizard ★"
echo "                Version: Draft by M.Hussein"
echo "############################################################"
echo ""
echo "Choose your installation mode:"
echo ""
echo "  1) Express Install (Recommended)"
echo "     - Full setup with all core features and plugins"
echo ""
echo "  2) Custom Install (Advanced)"
echo "     - You select which sets to install"
echo ""
echo -n "Enter your choice [1-2]: "
read CHOICE

case "$CHOICE" in
    1)
        MODE="express"
        ;;
    2)
        MODE="custom"
        ;;
    *)
        echo "❌ Invalid input. Exiting."
        exit 1
        ;;
esac

# Launch Core Script
wget --no-check-certificate https://raw.githubusercontent.com/Insprion80/Script/main/XDREAMY_Core.sh -O /tmp/XDREAMY_Core.sh && \
chmod +x /tmp/XDREAMY_Core.sh && \
/tmp/XDREAMY_Core.sh "$MODE"

exit 0
