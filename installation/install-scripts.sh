#!/usr/bin/env bash

# --------------------------------------------------
# Skripte aus dotfiles/scripts nach ~/Scripts installieren
# --------------------------------------------------
# Standard: Symlinks - nach einem `git pull` sind die Skripte automatisch aktuell.
# Mit --copy werden die Dateien stattdessen kopiert.
# Vorhandene, abweichende Dateien werden als <name>.bak gesichert.

# --------------------------------------------------
# Sicherheit & Umgebung
# --------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/install-file.sh"

# --------------------------------------------------
# Verzeichnisse
# --------------------------------------------------
SOURCE_DIR="$(cd "$SCRIPT_DIR/../scripts" && pwd)"
TARGET_DIR="$HOME/Scripts"

MODE=link
[[ "${1:-}" == "--copy" ]] && MODE=copy

# --------------------------------------------------
# Installieren
# --------------------------------------------------
mkdir -p "$TARGET_DIR"

for src in "$SOURCE_DIR"/*; do
  [[ -f "$src" ]] || continue
  install_file "$src" "$TARGET_DIR"
  chmod +x -- "$TARGET_DIR/$(basename -- "$src")"
done

echo "📂 Skripte installiert in $TARGET_DIR"
