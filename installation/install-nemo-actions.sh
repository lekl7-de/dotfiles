#!/usr/bin/env bash

# --------------------------------------------------
# Nemo-Aktionen (Rechtsklick-Menü) installieren
# --------------------------------------------------
# Installiert alle *.nemo_action aus dotfiles/config/nemo/actions
# nach ~/.local/share/nemo/actions.
#
# Aktionen, die Skripte aus ~/Scripts aufrufen, brauchen vorher install-scripts.sh.
# Standard: Symlinks, mit --copy werden die Dateien kopiert.

# --------------------------------------------------
# Sicherheit & Umgebung
# --------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/install-file.sh"

# --------------------------------------------------
# Verzeichnisse
# --------------------------------------------------
SOURCE_DIR="$(cd "$SCRIPT_DIR/../config/nemo/actions" && pwd)"
TARGET_DIR="$HOME/.local/share/nemo/actions"

MODE=link
[[ "${1:-}" == "--copy" ]] && MODE=copy

# --------------------------------------------------
# Installieren
# --------------------------------------------------
mkdir -p "$TARGET_DIR"
shopt -s nullglob

for src in "$SOURCE_DIR"/*.nemo_action; do
  install_file "$src" "$TARGET_DIR"

  # Warnen, wenn ein benötigtes Skript in ~/Scripts fehlt
  while read -r script; do
    [[ -x "$HOME/Scripts/$script" ]] || echo "   ⚠ benötigt ~/Scripts/$script - erst install-scripts.sh ausführen"
  done < <(grep -oE '\$HOME/Scripts/[^"'"'"' ]+' "$src" | sed 's|\$HOME/Scripts/||' | sort -u)
done

if ! command -v nemo &>/dev/null; then
  echo "⚠ Nemo ist nicht installiert - die Aktionen greifen erst, wenn Nemo da ist."
fi

echo "📂 Nemo-Aktionen installiert in $TARGET_DIR"
