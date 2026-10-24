#!/usr/bin/env bash

# --------------------------------------------------
# Skripte aus dotfiles/scripts nach ~/Scripts installieren
# --------------------------------------------------
# Standard: Symlinks - nach einem `git pull` sind die Skripte automatisch aktuell.
# Mit --copy werden die Dateien stattdessen kopiert.
# Vorhandene, abweichende Dateien in ~/Scripts werden als <name>.bak gesichert.

# --------------------------------------------------
# Sicherheit & Umgebung
# --------------------------------------------------
set -euo pipefail

# --------------------------------------------------
# Verzeichnisse
# --------------------------------------------------
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"
TARGET_DIR="$HOME/Scripts"

MODE=link
[[ "${1:-}" == "--copy" ]] && MODE=copy

# --------------------------------------------------
# Funktionen
# --------------------------------------------------
is_current() {
  local src="$1" dest="$2"
  if [[ "$MODE" == link ]]; then
    [[ "$(readlink -- "$dest" 2>/dev/null)" == "$src" ]]
  else
    [[ -f "$dest" && ! -L "$dest" ]] && cmp -s -- "$src" "$dest"
  fi
}

# --------------------------------------------------
# Installieren
# --------------------------------------------------
mkdir -p "$TARGET_DIR"

for src in "$SOURCE_DIR"/*; do
  [[ -f "$src" ]] || continue
  name="$(basename -- "$src")"
  dest="$TARGET_DIR/$name"

  if is_current "$src" "$dest"; then
    echo "✔ $name (aktuell)"
    continue
  fi

  # Fremde Datei sichern, alten Symlink einfach ersetzen
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    mv -- "$dest" "$dest.bak"
    echo "💾 $name → $name.bak gesichert"
  fi
  rm -f -- "$dest"

  if [[ "$MODE" == link ]]; then
    ln -s -- "$src" "$dest"
  else
    cp -- "$src" "$dest"
  fi
  chmod +x -- "$dest"
  echo "➕ $name"
done

echo "📂 Skripte installiert in $TARGET_DIR"
