#!/usr/bin/env bash

# --------------------------------------------------
# Skripte aus dotfiles/scripts nach ~/Scripts installieren
# --------------------------------------------------
# Installiert außerdem die passenden Nemo-Aktionen (Rechtsklick-Menü)
# aus dotfiles/config/nemo/actions nach ~/.local/share/nemo/actions.
#
# Standard: Symlinks - nach einem `git pull` sind die Skripte automatisch aktuell.
# Mit --copy werden die Dateien stattdessen kopiert.
# Vorhandene, abweichende Dateien werden als <name>.bak gesichert.

# --------------------------------------------------
# Sicherheit & Umgebung
# --------------------------------------------------
set -euo pipefail

# --------------------------------------------------
# Verzeichnisse
# --------------------------------------------------
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="$HOME/Scripts"
NEMO_ACTIONS_DIR="$HOME/.local/share/nemo/actions"

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

# install_file <quelle> <zielordner>
install_file() {
  local src="$1" name dest
  name="$(basename -- "$src")"
  dest="$2/$name"

  if is_current "$src" "$dest"; then
    echo "✔ $name (aktuell)"
    return
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
  echo "➕ $name"
}

# --------------------------------------------------
# Skripte
# --------------------------------------------------
mkdir -p "$TARGET_DIR"

for src in "$DOTFILES_DIR"/scripts/*; do
  [[ -f "$src" ]] || continue
  install_file "$src" "$TARGET_DIR"
  chmod +x -- "$TARGET_DIR/$(basename -- "$src")"
done

echo "📂 Skripte installiert in $TARGET_DIR"

# --------------------------------------------------
# Nemo-Aktionen
# --------------------------------------------------
shopt -s nullglob
actions=("$DOTFILES_DIR"/config/nemo/actions/*.nemo_action)

if (( ${#actions[@]} > 0 )); then
  mkdir -p "$NEMO_ACTIONS_DIR"
  for src in "${actions[@]}"; do
    install_file "$src" "$NEMO_ACTIONS_DIR"
  done
  echo "📂 Nemo-Aktionen installiert in $NEMO_ACTIONS_DIR"
fi
