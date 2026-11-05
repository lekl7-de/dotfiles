#!/usr/bin/env bash

# --------------------------------------------------
# Oh My Zsh + Plugins (+ optional Powerlevel10k) installieren
# --------------------------------------------------
# Installiert Oh My Zsh (falls noch nicht vorhanden) sowie die Plugins
# zsh-autosuggestions, zsh-syntax-highlighting und zsh-eza.
# Bereits vorhandene Plugins/Themes werden aktualisiert (git pull).
#
# Danach wird ~/.zshrc durch config/zshrc aus dem GitHub-Repo ersetzt,
# die bisherige Datei wird als ~/.zshrc.bak gesichert.
#
# Voraussetzungen: git, zsh, curl
#
# Aufruf:
#   ./install-ohmyzsh+plugins.sh               Oh My Zsh + Plugins + .zshrc
#   ./install-ohmyzsh+plugins.sh --p10k        zusätzlich Powerlevel10k + ~/.p10k.zsh
#   ./install-ohmyzsh+plugins.sh --keep-zshrc  bestehende ~/.zshrc nicht ersetzen

# --------------------------------------------------
# Sicherheit & Umgebung
# --------------------------------------------------
set -euo pipefail

INSTALL_P10K=false
INSTALL_ZSHRC=true
for arg in "$@"; do
  case "$arg" in
    --p10k) INSTALL_P10K=true ;;
    --keep-zshrc) INSTALL_ZSHRC=false ;;
    -h|--help) sed -n '3,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unbekannte Option: $arg" >&2; exit 1 ;;
  esac
done

ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
P10K_CONFIG="$HOME/.p10k.zsh"

# Konfigurationsdateien aus dem dotfiles-Repo
REPO_RAW="https://raw.githubusercontent.com/lekl7-de/dotfiles/main"
ZSHRC_URL="$REPO_RAW/config/zshrc"
P10K_URL="$REPO_RAW/config/p10k.zsh"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# "Name Repository"
PLUGINS=(
  "zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions.git"
  "zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git"
  "zsh-eza https://github.com/z-shell/zsh-eza.git"
)
P10K_REPO="https://github.com/romkatv/powerlevel10k.git"
PLUGIN_NAMES=("${PLUGINS[@]%% *}")

# --------------------------------------------------
# Ausgabe & Hilfsfunktionen
# --------------------------------------------------
if [[ -t 1 ]]; then
  BOLD=$'\033[1m' RED=$'\033[31m' GREEN=$'\033[32m' YELLOW=$'\033[33m' CYAN=$'\033[36m' RESET=$'\033[0m'
else
  BOLD="" RED="" GREEN="" YELLOW="" CYAN="" RESET=""
fi

section() { printf "\n${BOLD}${CYAN}==> %s${RESET}\n" "$1"; }
info()    { printf "    %s\n" "$1"; }
ok()      { printf "    ${GREEN}✔${RESET} %s\n" "$1"; }
warn()    { printf "    ${YELLOW}!${RESET} %s\n" "$1"; }
fail()    { printf "    ${RED}✘${RESET} %s\n" "$1" >&2; }

has() { command -v "$1" &>/dev/null; }

# clone_or_update <name> <url> <zielordner>
clone_or_update() {
  local name="$1" url="$2" dest="$3"
  if [[ -d "$dest/.git" ]]; then
    if git -C "$dest" pull --ff-only --quiet; then
      ok "$name (aktualisiert)"
    else
      warn "$name: Update fehlgeschlagen, behalte vorhandene Version"
    fi
  elif [[ -e "$dest" ]]; then
    warn "$name: $dest existiert, ist aber kein git-Repo - übersprungen"
  else
    git clone --depth=1 --quiet "$url" "$dest"
    ok "$name (installiert)"
  fi
}

# install_config <url> <ziel>
# Lädt eine Datei herunter und ersetzt das Ziel; das bisherige Ziel wird als
# <ziel>.bak gesichert (gibt es das schon, mit Zeitstempel dahinter).
install_config() {
  local url="$1" dest="$2" name tmp backup
  name="$(basename -- "$dest")"
  tmp="$TMP_DIR/$name"

  if ! curl -fsSL "$url" -o "$tmp" || [[ ! -s "$tmp" ]]; then
    fail "$name: Download fehlgeschlagen ($url) - bestehende Datei bleibt"
    return 1
  fi

  if [[ -f "$dest" ]] && cmp -s -- "$tmp" "$dest"; then
    ok "$name (bereits aktuell)"
    return
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    backup="$dest.bak"
    [[ -e "$backup" || -L "$backup" ]] && backup="$dest.bak.$(date +%Y%m%d-%H%M%S)"
    mv -- "$dest" "$backup"
    info "💾 $name → $(basename -- "$backup") gesichert"
  fi
  mv -- "$tmp" "$dest"
  ok "$name (aus GitHub installiert)"
}

# --------------------------------------------------
# Voraussetzungen prüfen
# --------------------------------------------------
section "Voraussetzungen"
missing=()
for cmd in git zsh curl; do
  if has "$cmd"; then ok "$cmd"; else fail "$cmd fehlt"; missing+=("$cmd"); fi
done
if (( ${#missing[@]} )); then
  fail "Bitte zuerst installieren: ${missing[*]}"
  exit 1
fi

# --------------------------------------------------
# Oh My Zsh
# --------------------------------------------------
section "Oh My Zsh"
if [[ -d "$ZSH" ]]; then
  ok "bereits installiert ($ZSH)"
else
  # RUNZSH=no:     nicht direkt in eine neue zsh wechseln (Skript läuft weiter)
  # CHSH=no:       Login-Shell wird unten separat geprüft
  # KEEP_ZSHRC=yes: bestehende ~/.zshrc nicht überschreiben
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes ZSH="$ZSH" \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  ok "installiert ($ZSH)"
fi

# --------------------------------------------------
# Plugins & Themes
# --------------------------------------------------
section "Plugins"
mkdir -p "$ZSH_CUSTOM/plugins"
for entry in "${PLUGINS[@]}"; do
  read -r name url <<<"$entry"
  clone_or_update "$name" "$url" "$ZSH_CUSTOM/plugins/$name"
done
has eza || warn "zsh-eza braucht das Programm 'eza' - bitte über den Paketmanager installieren"

if $INSTALL_P10K; then
  section "Powerlevel10k"
  mkdir -p "$ZSH_CUSTOM/themes"
  clone_or_update powerlevel10k "$P10K_REPO" "$ZSH_CUSTOM/themes/powerlevel10k"
  install_config "$P10K_URL" "$P10K_CONFIG" || true
fi

# --------------------------------------------------
# .zshrc aus dem Repo installieren
# --------------------------------------------------
section "Konfiguration"
if $INSTALL_ZSHRC; then
  install_config "$ZSHRC_URL" "$ZSHRC" || true
else
  info "~/.zshrc bleibt unverändert (--keep-zshrc)"
fi

# --------------------------------------------------
# .zshrc & Login-Shell prüfen
# --------------------------------------------------
if [[ -f "$ZSHRC" ]]; then
  # plugins=( ... ) kann über mehrere Zeilen gehen
  plugins_block="$(sed -n '/^[[:space:]]*plugins=(/,/)/p' "$ZSHRC")"
  not_enabled=()
  for name in "${PLUGIN_NAMES[@]}"; do
    [[ "$plugins_block" =~ [[:space:]\(]"$name"[[:space:]\)] ]] || not_enabled+=("$name")
  done
  if (( ${#not_enabled[@]} )); then
    warn "In $ZSHRC noch nicht aktiviert: ${not_enabled[*]}"
    info "plugins=(git ${PLUGIN_NAMES[*]})"
  else
    ok "Alle Plugins in $ZSHRC aktiviert"
  fi
else
  warn "$ZSHRC nicht gefunden - Vorlage: config/zshrc"
fi

if [[ "$(basename -- "${SHELL:-}")" == zsh ]]; then
  ok "zsh ist Login-Shell"
else
  warn "Login-Shell ist ${SHELL:-unbekannt} - ändern mit: chsh -s \"$(command -v zsh)\""
fi

section "Fertig"
info "Neues Terminal öffnen oder 'exec zsh' ausführen, damit die Änderungen greifen."
