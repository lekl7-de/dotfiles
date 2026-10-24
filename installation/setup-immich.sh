#!/usr/bin/env bash

# --------------------------------------------------
# Immich-Zugangsdaten für clean_downloads.sh einrichten
# --------------------------------------------------
# Fragt URL und API-Key ab, prüft die Verbindung und schreibt
# ~/.config/clean_downloads.env (nur für dich lesbar, chmod 600).
#
# API-Key erstellen: Immich → Kontoeinstellungen → API-Schlüssel
# Benötigte Berechtigung für den Upload: asset.upload

# --------------------------------------------------
# Sicherheit & Umgebung
# --------------------------------------------------
set -euo pipefail

ENV_FILE="$HOME/.config/clean_downloads.env"

ask_yes_no() {
  local answer
  read -rp "$1 [j/N] " answer </dev/tty
  [[ "${answer,,}" == j* || "${answer,,}" == y* ]]
}

# --------------------------------------------------
# Vorhandene Datei
# --------------------------------------------------
if [[ -f "$ENV_FILE" ]]; then
  echo "⚠ $ENV_FILE existiert bereits."
  ask_yes_no "Überschreiben?" || { echo "Abgebrochen."; exit 0; }
fi

# --------------------------------------------------
# Abfrage
# --------------------------------------------------
while true; do
  read -rp "Immich-URL (z.B. http://192.168.1.10:2283): " IMMICH_URL </dev/tty
  IMMICH_URL="${IMMICH_URL%/}"
  IMMICH_URL="${IMMICH_URL%/api}"
  [[ "$IMMICH_URL" =~ ^https?://[^[:space:]]+$ ]] && break
  echo "❌ Bitte mit http:// oder https:// angeben."
done

while true; do
  read -rsp "API-Key (Eingabe wird nicht angezeigt): " IMMICH_API_KEY </dev/tty
  echo
  [[ -n "$IMMICH_API_KEY" ]] && break
  echo "❌ API-Key darf nicht leer sein."
done

# --------------------------------------------------
# Verbindung prüfen
# --------------------------------------------------
save=true

if ! curl -fsS --connect-timeout 5 "$IMMICH_URL/api/server/ping" &>/dev/null; then
  echo "❌ Immich unter $IMMICH_URL nicht erreichbar."
  ask_yes_no "Trotzdem speichern?" || save=false
else
  echo "✅ Server erreichbar"
  status="$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 \
    -H "x-api-key: $IMMICH_API_KEY" "$IMMICH_URL/api/users/me")"
  case "$status" in
    200) echo "✅ API-Key gültig" ;;
    403) echo "✅ API-Key gültig (eingeschränkte Rechte - für den Upload wird asset.upload gebraucht)" ;;
    401) echo "❌ API-Key ungültig"
         ask_yes_no "Trotzdem speichern?" || save=false ;;
    *)   echo "⚠ Unerwartete Antwort beim Prüfen des API-Keys (HTTP $status)"
         ask_yes_no "Trotzdem speichern?" || save=false ;;
  esac
fi

$save || { echo "Nichts gespeichert."; exit 1; }

# --------------------------------------------------
# Speichern
# --------------------------------------------------
mkdir -p "$(dirname -- "$ENV_FILE")"
(
  umask 077
  printf 'IMMICH_URL=%q\nIMMICH_API_KEY=%q\n' "$IMMICH_URL" "$IMMICH_API_KEY" > "$ENV_FILE"
)
chmod 600 "$ENV_FILE"

echo "💾 Gespeichert in $ENV_FILE"
