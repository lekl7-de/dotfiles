#!/usr/bin/env bash

# --------------------------------------------------
# Fix: Corsair VOID ELITE Lautstärkerad schaltet Mikro stumm
# --------------------------------------------------
# OpenLinkHub ruft bei jedem Dreh am Lautstärkerad (Mikrofonarm hochgeklappt)
# `pactl set-source-mute @DEFAULT_SOURCE@ toggle` auf und schaltet damit die
# Standard-Eingabe stumm - also z.B. ein separates USB-Mikrofon.
#
# Dieses Skript legt einen pactl-Wrapper an, der nur von OpenLinkHub benutzt
# wird und dessen Mute-Befehle auf das Headset-eigene Mikro umleitet.
# Alle anderen pactl-Befehle werden unverändert durchgereicht.
#
# Rückgängig machen:
#   rm -r ~/.config/systemd/user/OpenLinkHub.service.d/pactl-shim.conf ~/.local/lib/openlinkhub-shim
#   systemctl --user daemon-reload && systemctl --user restart OpenLinkHub

# --------------------------------------------------
# Sicherheit & Umgebung
# --------------------------------------------------
set -euo pipefail

# --------------------------------------------------
# Verzeichnisse
# --------------------------------------------------
SHIM_DIR="$HOME/.local/lib/openlinkhub-shim"
DROPIN_DIR="$HOME/.config/systemd/user/OpenLinkHub.service.d"

# --------------------------------------------------
# pactl-Wrapper
# --------------------------------------------------
mkdir -p "$SHIM_DIR"
cat > "$SHIM_DIR/pactl" <<'EOF'
#!/bin/sh
# Von fix-headset-mic.sh angelegt: leitet OpenLinkHubs Mute-Befehle für
# @DEFAULT_SOURCE@ auf das Mikro des Corsair VOID ELITE Headsets um.
case "$1" in
  set-source-mute|get-source-mute)
    if [ "$2" = "@DEFAULT_SOURCE@" ]; then
      headset=$(/usr/bin/pactl list short sources | awk '/CORSAIR_VOID_ELITE/ && !/\.monitor/ {print $2; exit}')
      # Headset nicht gefunden -> lieber nichts tun als das falsche Mikro stummschalten
      [ -n "$headset" ] || exit 1
      cmd=$1
      shift 2
      exec /usr/bin/pactl "$cmd" "$headset" "$@"
    fi
    ;;
esac
exec /usr/bin/pactl "$@"
EOF
chmod +x "$SHIM_DIR/pactl"

# --------------------------------------------------
# systemd Drop-in für OpenLinkHub
# --------------------------------------------------
mkdir -p "$DROPIN_DIR"
cat > "$DROPIN_DIR/pactl-shim.conf" <<'EOF'
[Service]
Environment=PATH=%h/.local/lib/openlinkhub-shim:/usr/local/bin:/usr/bin
EOF

# --------------------------------------------------
# OpenLinkHub neu starten (falls schon installiert)
# --------------------------------------------------
systemctl --user daemon-reload
if systemctl --user cat OpenLinkHub.service &>/dev/null; then
  systemctl --user try-restart OpenLinkHub.service
  echo "Headset-Fix installiert, OpenLinkHub neu gestartet."
else
  echo "Headset-Fix installiert. OpenLinkHub ist noch nicht installiert - greift automatisch, sobald der Dienst existiert."
fi
