# shellcheck shell=bash

# --------------------------------------------------
# Gemeinsame Funktion für die Install-Skripte
# --------------------------------------------------
# Wird per `source` eingebunden. Erwartet MODE=link oder MODE=copy.

is_current() {
  local src="$1" dest="$2"
  if [[ "$MODE" == link ]]; then
    [[ "$(readlink -- "$dest" 2>/dev/null)" == "$src" ]]
  else
    [[ -f "$dest" && ! -L "$dest" ]] && cmp -s -- "$src" "$dest"
  fi
}

# install_file <quelle> <zielordner>
# Symlink bzw. Kopie anlegen; fremde Dateien werden als <name>.bak gesichert
install_file() {
  local src="$1" name dest
  name="$(basename -- "$src")"
  dest="$2/$name"

  if is_current "$src" "$dest"; then
    echo "✔ $name (aktuell)"
    return
  fi

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
