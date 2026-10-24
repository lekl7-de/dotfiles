#!/usr/bin/env bash

# --------------------------------------------------
# Aufnahmeort eines Fotos anzeigen
# --------------------------------------------------
# Liest die GPS-Koordinaten aus den EXIF-Daten und gibt einen Google-Maps-Link aus.
# Benötigt exiftool (Arch: perl-image-exiftool, Ubuntu: libimage-exiftool-perl).
#
# Aufruf: photo_location.sh [--open] <bild>
#   --open  Link im Browser öffnen, Fehler als Benachrichtigung (für die Nemo-Aktion)

# --------------------------------------------------
# Sicherheit & Umgebung
# --------------------------------------------------
set -u

OPEN=false
if [[ "${1:-}" == "--open" ]]; then
  OPEN=true
  shift
fi

# Fehler ausgeben (mit --open zusätzlich als Benachrichtigung) und beenden
fail() {
  echo "$1" >&2
  if $OPEN && command -v notify-send &>/dev/null; then
    notify-send -i dialog-error "Aufnahmeort" "$1"
  fi
  exit "${2:-1}"
}

# --------------------------------------------------
# Prüfungen
# --------------------------------------------------
[[ $# -eq 1 ]] || fail "Aufruf: $(basename -- "$0") [--open] <bild>" 2

IMAGE="$1"

command -v exiftool &>/dev/null || fail "exiftool fehlt (Arch: sudo pacman -S perl-image-exiftool)"
[[ -f "$IMAGE" ]] || fail "Datei nicht gefunden: $IMAGE"

# --------------------------------------------------
# Koordinaten auslesen
# --------------------------------------------------
# -n liefert Dezimalgrad mit Vorzeichen (Süd/West negativ)
read -r LAT LONG < <(exiftool -n -p '$GPSLatitude $GPSLongitude' -- "$IMAGE" 2>/dev/null)

[[ -n "${LAT:-}" && -n "${LONG:-}" ]] || fail "Keine GPS-Daten gefunden: $(basename -- "$IMAGE")"

URL="https://www.google.com/maps?q=${LAT},${LONG}"

echo "Koordinaten: $LAT, $LONG"
echo "Google-Maps: $URL"

if $OPEN; then
  xdg-open "$URL" &>/dev/null &
fi
