#!/usr/bin/env bash

# --------------------------------------------------
# Programme installieren: OpenLinkHub & ssh-list
# --------------------------------------------------
# Erkennt, welche Installationswege auf dem System verfügbar sind
# (yay/paru, Ubuntu-PPA, Fedora-Copr, offizielles Skript, GitHub-Release, ...)
# und fragt pro Programm, wie es installiert werden soll.
#
# Aufruf:
#   ./install-programs.sh            interaktiv
#   ./install-programs.sh -y         ohne Fragen, jeweils die empfohlene Methode
#   ./install-programs.sh --dry-run  nur anzeigen, was ausgeführt würde

# --------------------------------------------------
# Sicherheit & Umgebung
# --------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ASSUME_YES=false
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    -y|--yes) ASSUME_YES=true ;;
    -n|--dry-run) DRY_RUN=true ;;
    -h|--help) sed -n '3,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unbekannte Option: $arg" >&2; exit 1 ;;
  esac
done

# --------------------------------------------------
# Ausgabe & Hilfsfunktionen
# --------------------------------------------------
if [[ -t 1 ]]; then
  BOLD=$'\033[1m' DIM=$'\033[2m' RED=$'\033[31m' GREEN=$'\033[32m' YELLOW=$'\033[33m' CYAN=$'\033[36m' RESET=$'\033[0m'
else
  BOLD="" DIM="" RED="" GREEN="" YELLOW="" CYAN="" RESET=""
fi

section() { printf "\n${BOLD}${CYAN}==> %s${RESET}\n" "$1"; }
info()    { printf "    %s\n" "$1"; }
ok()      { printf "    ${GREEN}✔${RESET} %s\n" "$1"; }
warn()    { printf "    ${YELLOW}!${RESET} %s\n" "$1"; }
fail()    { printf "    ${RED}✘${RESET} %s\n" "$1" >&2; }

# Befehl ausführen (bzw. bei --dry-run nur anzeigen)
run() {
  if $DRY_RUN; then
    printf "    ${DIM}[dry-run] %s${RESET}\n" "$*"
  else
    "$@"
  fi
}

has() { command -v "$1" &>/dev/null; }

# Ja/Nein-Frage, $2 = Standard (j/n)
ask_yes_no() {
  local question="$1" default="$2" answer
  if $ASSUME_YES; then [[ "$default" == j ]]; return; fi
  local hint="[J/n]"; [[ "$default" == n ]] && hint="[j/N]"
  read -rp "    $question $hint " answer </dev/tty
  answer="${answer:-$default}"
  [[ "${answer,,}" == j* || "${answer,,}" == y* ]]
}

# Auswahlmenü: choose <Variablenname> "Label 1" "Label 2" ...
# Option 1 ist die Empfehlung, "Überspringen" wird automatisch angehängt.
# Schreibt die gewählte Nummer (0 = überspringen) in die Variable.
choose() {
  local -n _result="$1"; shift
  local options=("$@") i answer
  if $ASSUME_YES; then _result=1; info "Gewählt: ${options[0]}"; return; fi
  for i in "${!options[@]}"; do
    local tag=""; [[ $i -eq 0 ]] && tag=" ${GREEN}(empfohlen)${RESET}"
    printf "    ${BOLD}%d)${RESET} %s%s\n" $((i + 1)) "${options[$i]}" "$tag"
  done
  printf "    ${BOLD}0)${RESET} Überspringen\n"
  while true; do
    read -rp "    Auswahl [1]: " answer </dev/tty
    answer="${answer:-1}"
    if [[ "$answer" =~ ^[0-9]+$ ]] && (( answer <= ${#options[@]} )); then
      _result=$answer
      return
    fi
    warn "Bitte eine Zahl zwischen 0 und ${#options[@]} eingeben."
  done
}

# --------------------------------------------------
# System erkennen
# --------------------------------------------------
AUR_HELPER=""
if has yay; then AUR_HELPER=yay; elif has paru; then AUR_HELPER=paru; fi
HAS_PPA=false
if has apt-get && has add-apt-repository; then HAS_PPA=true; fi
HAS_COPR=false
if has dnf; then HAS_COPR=true; fi

case "$(uname -m)" in
  x86_64)  RUST_TARGET=x86_64-unknown-linux-musl ;;
  aarch64) RUST_TARGET=aarch64-unknown-linux-musl ;;
  armv7l)  RUST_TARGET=armv7-unknown-linux-musleabihf ;;
  i686)    RUST_TARGET=i686-unknown-linux-musl ;;
  *)       RUST_TARGET="" ;;
esac

# URL des neuesten Release-Assets, das auf $2 endet
github_asset_url() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
    | grep -oE '"browser_download_url": *"[^"]+"' \
    | cut -d'"' -f4 \
    | grep -E -- "$2\$" \
    | head -n 1
}

# --------------------------------------------------
# OpenLinkHub
# --------------------------------------------------
# Paket-Versionen laufen als Systemdienst unter eigenem Benutzer. Das offizielle
# Skript installiert nach ~/OpenLinkHub und läuft als Benutzerdienst - nur dort
# hat OpenLinkHub Zugriff auf PipeWire (Headset-Mute -> fix-headset-mic.sh).
openlinkhub_installed() {
  if [[ -f "$HOME/.config/systemd/user/OpenLinkHub.service" ]]; then
    echo "offizielles Skript (~/OpenLinkHub, Benutzerdienst)"
  elif has pacman && pacman -Qq | grep -qxE 'openlinkhub(-bin|-git)?'; then
    echo "AUR-Paket ($(pacman -Qq | grep -xE 'openlinkhub(-bin|-git)?' | head -n 1))"
  elif has dpkg && dpkg -s openlinkhub &>/dev/null; then
    echo "apt-Paket"
  elif has rpm && rpm -q OpenLinkHub &>/dev/null; then
    echo "rpm-Paket"
  fi
}

install_openlinkhub() {
  section "OpenLinkHub (Corsair Geräte: Lüfter, RGB, Headset)"

  local existing
  existing="$(openlinkhub_installed)"
  if [[ -n "$existing" ]]; then
    ok "Bereits installiert: $existing"
    ask_yes_no "Trotzdem neu installieren / aktualisieren?" n || return 0
    warn "Laut Anleitung vorher eine andere Installationsart deinstallieren, sonst laufen zwei Instanzen."
  fi

  local labels=() methods=()
  if [[ -n "$AUR_HELPER" ]]; then
    labels+=("AUR mit $AUR_HELPER (openlinkhub-bin) - Updates über $AUR_HELPER, Systemdienst")
    methods+=(aur)
  fi
  if $HAS_PPA; then
    labels+=("Ubuntu-PPA (ppa:jurkovic-nikola/openlinkhub) - Updates über apt, Systemdienst")
    methods+=(ppa)
  fi
  if $HAS_COPR; then
    labels+=("Fedora-Copr (jurkovic-nikola/OpenLinkHub) - Updates über dnf, Systemdienst")
    methods+=(copr)
  fi
  labels+=("Offizielles Install-Skript - nach ~/OpenLinkHub, Benutzerdienst, inkl. Headset-Fix")
  methods+=(script)

  local choice
  choose choice "${labels[@]}"
  (( choice == 0 )) && { info "Übersprungen."; return 0; }

  case "${methods[$((choice - 1))]}" in
    aur)
      run "$AUR_HELPER" -S --needed openlinkhub-bin
      run sudo systemctl enable --now openlinkhub.service
      ;;
    ppa)
      run sudo add-apt-repository -y ppa:jurkovic-nikola/openlinkhub
      run sudo apt-get update
      run sudo apt-get install -y openlinkhub
      run sudo systemctl enable --now OpenLinkHub.service
      ;;
    copr)
      run sudo dnf copr enable -y jurkovic-nikola/OpenLinkHub
      run sudo dnf install -y OpenLinkHub
      run sudo systemctl enable --now OpenLinkHub.service
      ;;
    script)
      local installer="$TMP_DIR/openlinkhub-install.sh"
      run curl -fsSL -o "$installer" https://raw.githubusercontent.com/jurkovic-nikola/OpenLinkHub/main/remote-install.sh
      run bash "$installer"
      run bash "$SCRIPT_DIR/fix-headset-mic.sh"
      ;;
  esac

  ok "OpenLinkHub installiert - WebUI: http://127.0.0.1:27003"
}

# --------------------------------------------------
# ssh-list
# --------------------------------------------------
install_ssh_list() {
  section "ssh-list (SSH-Verbindungsmanager im Terminal)"

  if has ssh-list; then
    ok "Bereits installiert: $(command -v ssh-list)"
    ask_yes_no "Trotzdem neu installieren / aktualisieren?" n || return 0
  fi

  local labels=() methods=()
  if [[ -n "$AUR_HELPER" ]]; then
    labels+=("AUR mit $AUR_HELPER (ssh-list) - Updates über $AUR_HELPER")
    methods+=(aur)
  fi
  if $HAS_PPA; then
    labels+=("Ubuntu-PPA (ppa:akinoiro/ssh-list) - Updates über apt")
    methods+=(ppa)
  fi
  if [[ -n "$RUST_TARGET" ]]; then
    labels+=("GitHub-Release - fertiges Binary nach ~/.local/bin, Updates manuell")
    methods+=(release)
  fi
  if has cargo; then
    labels+=("cargo install - kompiliert aus crates.io")
    methods+=(cargo)
  fi
  if has brew; then
    labels+=("Homebrew (akinoiro/tap)")
    methods+=(brew)
  fi
  if (( ${#methods[@]} == 0 )); then
    fail "Kein Installationsweg für diese Architektur ($(uname -m)) gefunden."
    return 1
  fi

  local choice
  choose choice "${labels[@]}"
  (( choice == 0 )) && { info "Übersprungen."; return 0; }

  has ssh || warn "Kein OpenSSH-Client gefunden - ssh-list braucht 'ssh'."

  case "${methods[$((choice - 1))]}" in
    aur)
      run "$AUR_HELPER" -S --needed ssh-list
      ;;
    ppa)
      run sudo add-apt-repository -y ppa:akinoiro/ssh-list
      run sudo apt-get update
      run sudo apt-get install -y ssh-list
      ;;
    release)
      local url
      url="$(github_asset_url akinoiro/ssh-list "$RUST_TARGET.tar.gz")"
      [[ -n "$url" ]] || { fail "Kein Release für $RUST_TARGET gefunden."; return 1; }
      info "$url"
      run curl -fsSL -o "$TMP_DIR/ssh-list.tar.gz" "$url"
      run tar -xzf "$TMP_DIR/ssh-list.tar.gz" -C "$TMP_DIR"
      run install -Dm755 "$TMP_DIR/ssh-list" "$HOME/.local/bin/ssh-list"
      [[ ":$PATH:" == *":$HOME/.local/bin:"* ]] || warn "~/.local/bin ist nicht im PATH."
      ;;
    cargo)
      run cargo install ssh-list
      ;;
    brew)
      run brew tap akinoiro/tap
      run brew install ssh-list
      ;;
  esac

  ok "ssh-list installiert"
}

# --------------------------------------------------
# Start
# --------------------------------------------------
$DRY_RUN && warn "Dry-Run: es wird nichts installiert."
info "Erkannt: AUR-Helper=${AUR_HELPER:-keiner}, PPA=$HAS_PPA, Copr=$HAS_COPR, Arch=$(uname -m)"

install_openlinkhub
install_ssh_list

section "Fertig"
