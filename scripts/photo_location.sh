#!/usr/bin/env bash

# --------------------------------------------------
# Aufnahmeort eines Fotos anzeigen
# --------------------------------------------------
# Liest die GPS-Koordinaten aus den EXIF-Daten und gibt einen Google-Maps-Link aus.
# Benötigt exiftool (Arch: perl-image-exiftool, Ubuntu: libimage-exiftool-perl).
#
# Aufruf: photo_location.sh <bild>

# --------------------------------------------------
# Sicherheit & Umgebung
# --------------------------------------------------
set -u

# --------------------------------------------------
# Prüfungen
# --------------------------------------------------
if [[ $# -ne 1 ]]; then
  echo "Aufruf: $(basename -- "$0") <bild>" >&2
  exit 2
fi

IMAGE="$1"

if ! command -v exiftool &>/dev/null; then
  echo "exiftool fehlt (Arch: sudo pacman -S perl-image-exiftool)" >&2
  exit 1
fi

if [[ ! -f "$IMAGE" ]]; then
  echo "Datei nicht gefunden: $IMAGE" >&2
  exit 1
fi

# --------------------------------------------------
# Koordinaten auslesen
# --------------------------------------------------
# -n liefert Dezimalgrad mit Vorzeichen (Süd/West negativ)
read -r LAT LONG < <(exiftool -n -p '$GPSLatitude $GPSLongitude' -- "$IMAGE" 2>/dev/null)

if [[ -z "${LAT:-}" || -z "${LONG:-}" ]]; then
  echo "Keine GPS-Daten gefunden: $IMAGE" >&2
  exit 1
fi

echo "Koordinaten: $LAT, $LONG"
echo "Google-Maps: https://www.google.com/maps?q=${LAT},${LONG}"
