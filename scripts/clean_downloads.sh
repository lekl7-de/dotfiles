#!/usr/bin/env bash

# --------------------------------------------------
# Download-Ordner aufräumen
# --------------------------------------------------
# Sortiert Dateien aus ~/Downloads nach Typ in ~/Downloads/Archive/<kategorie>.
# Bilder & Videos werden vorher zu Immich hochgeladen.
#
# Immich-Zugangsdaten kommen aus ~/.config/clean_downloads.env (nicht im Repo!):
#   IMMICH_URL="http://192.168.1.10:2283"
#   IMMICH_API_KEY="..."
# Fehlt die Datei, bleiben Bilder & Videos im Download-Ordner liegen.

# --------------------------------------------------
# Sicherheit & Umgebung
# --------------------------------------------------
set -u
PATH=/usr/local/bin:/usr/bin:/bin

# --------------------------------------------------
# Verzeichnisse
# --------------------------------------------------
DOWNLOAD_DIR="$HOME/Downloads"
ARCHIVE_DIR="$DOWNLOAD_DIR/Archive"

# --------------------------------------------------
# Immich Konfiguration
# --------------------------------------------------
ENV_FILE="$HOME/.config/clean_downloads.env"
IMMICH_URL=""
IMMICH_API_KEY=""
# shellcheck source=/dev/null
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

MAX_SIZE=$((100 * 1024 * 1024)) # 100 MB
MIN_AGE=60                      # Sekunden - jüngere Dateien werden evtl. noch geschrieben

# --------------------------------------------------
# Kategorien
# --------------------------------------------------
declare -A CATEGORIES=(
  [videos]="mp4 mkv avi mov webm"
  [pictures]="jpg jpeg png gif bmp webp"
  [text]="txt pdf md doc docx odt"
  [piracy]="nzb torrent"
  [archives]="zip tar gz tgz xz zst bz2 rar 7z"
  [iso]="iso"
  [audio]="mp3 wav flac ogg m4a"
)

# Unfertige Downloads (Firefox, Chrome, ...)
INCOMPLETE_EXT="part crdownload tmp download opdownload"

# --------------------------------------------------
# Funktionen
# --------------------------------------------------
upload_to_immich() {
  local file="$1" mtime response

  mtime="$(date -Iseconds -r "$file")"
  response="$(curl -sS --fail --connect-timeout 10 -X POST "$IMMICH_URL/api/assets" \
    -H "x-api-key: $IMMICH_API_KEY" \
    -H "Accept: application/json" \
    -F "assetData=@$file" \
    -F "deviceAssetId=$(uuidgen)" \
    -F "deviceId=bash-script" \
    -F "fileCreatedAt=$mtime" \
    -F "fileModifiedAt=$mtime")" || return 1

  [[ "$response" == *'"duplicate"'* ]] && echo "   (war schon in Immich)"
  return 0
}

# Freier Zielpfad: datei.pdf -> datei (1).pdf -> datei (2).pdf ...
unique_dest() {
  local dir="$1" name="$2" base ext n=1
  if [[ "$name" == *.* && "$name" != .* ]]; then
    base="${name%.*}"
    ext=".${name##*.}"
  else
    base="$name"
    ext=""
  fi
  local dest="$dir/$name"
  while [[ -e "$dest" ]]; do
    dest="$dir/$base ($n)$ext"
    n=$((n + 1))
  done
  echo "$dest"
}

archive() {
  local file="$1" category="$2"
  mv -n -- "$file" "$(unique_dest "$ARCHIVE_DIR/$category" "$(basename -- "$file")")"
}

is_incomplete() {
  local file="$1" ext
  for ext in $INCOMPLETE_EXT; do
    [[ "${file,,}" == *."$ext" ]] && return 0
    # Firefox legt neben "datei.zip.part" schon eine leere "datei.zip" an
    [[ -e "$file.$ext" ]] && return 0
  done
  (( $(date +%s) - $(stat -c %Y "$file") < MIN_AGE ))
}

# --------------------------------------------------
# Vorbereitungen
# --------------------------------------------------
mkdir -p "$ARCHIVE_DIR/other"

for category in "${!CATEGORIES[@]}"; do
  mkdir -p "$ARCHIVE_DIR/$category"
done

immich_ready=false
if [[ -n "$IMMICH_URL" && -n "$IMMICH_API_KEY" ]]; then
  immich_ready=true
else
  echo "⚠ Immich nicht konfiguriert ($ENV_FILE) - Bilder & Videos bleiben liegen"
fi

shopt -s nullglob

# --------------------------------------------------
# Dateien verarbeiten
# --------------------------------------------------
for file in "$DOWNLOAD_DIR"/*; do
  [[ -f "$file" ]] || continue

  filename="$(basename -- "$file")"

  if is_incomplete "$file"; then
    echo "⏳ Noch im Download (bleibt liegen): $filename"
    continue
  fi

  # Dateien ohne Endung landen in "other"
  extension=""
  [[ "$filename" == *.* ]] && extension="${filename##*.}"
  extension="${extension,,}"

  filesize=$(stat -c%s "$file")
  moved=false

  for category in "${!CATEGORIES[@]}"; do
    for ext in ${CATEGORIES[$category]}; do
      if [[ "$extension" == "$ext" ]]; then

        # 📸 Bilder & 🎥 Videos → Immich
        if [[ "$category" == "pictures" || "$category" == "videos" ]]; then
          if ! $immich_ready; then
            :
          elif (( filesize > MAX_SIZE )); then
            echo "⛔ Zu groß (bleibt liegen): $filename"
          else
            echo "⬆ Upload: $filename"

            if upload_to_immich "$file"; then
              archive "$file" "$category"
              echo "✅ Hochgeladen & verschoben"
            else
              echo "❌ Upload fehlgeschlagen: $filename"
            fi
          fi
        else
          archive "$file" "$category"
          echo "📁 Verschoben: $filename → $category"
        fi

        moved=true
        break 2
      fi
    done
  done

  # Sonstige Dateien
  if [[ "$moved" == false ]]; then
    archive "$file" other
    echo "📁 Verschoben: $filename → other"
  fi
done

echo "🧹 Download Cleanup abgeschlossen"
