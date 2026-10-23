#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/snwiem/dotfiles-mise.git}"
SOURCE_DIR="$HOME/.dotfiles"
MISE_INSTALL_PATH="${MISE_INSTALL_PATH:-$HOME/.local/bin/mise}"
MISE_INSTALL_SKIP_IF_EXISTS="${MISE_INSTALL_SKIP_IF_EXISTS:-1}"
PROFILE="${PROFILE:-default}"
WORK_CONFIG_NEEDS_SETUP=false
OS="UNKNOWN"
VER="UNKNOWN"

BOLD=$'\033[1m'
CYAN=$'\033[36m'
RED=$'\033[31m'
GREEN=$'\033[32m'
RESET=$'\033[0m'

if [[ -n "${NO_COLOR:-}" ]]; then
  BOLD=""
  CYAN=""
  RED=""
  GREEN=""
  RESET=""
fi

log() {
  printf "\n%s%s==>%s %s%s%s\n" "$BOLD" "$CYAN" "$RESET" "$BOLD" "$*" "$RESET"
}

die() {
  printf "%s%serror:%s %s\n" "$BOLD" "$RED" "$RESET" "$*" >&2
  exit 1
}

run_as_root() {
  if (( EUID == 0 )); then
    "$@"
  else
    sudo "$@"
  fi
}

get_osversion() {
    if [ -f /etc/os-release ]; then
        eval $(cat /etc/os-release)
        OS=$ID
        VER=$VERSION_ID
    elif command -v lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        source /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    log "Current Operating System is ${OS}, version ${VER}"
}

install_prerequisites() {
    if (( EUID != 0 )); then
      command -v sudo >/dev/null 2>&1 || die "sudo is required"
    fi
}

install_mise() {
    log "Installing mise"
    curl -fsSL https://mise.run | MISE_INSTALL_PATH="$MISE_INSTALL_PATH" MISE_INSTALL_SKIP_IF_EXISTS="$MISE_INSTALL_SKIP_IF_EXISTS" sh
    export PATH="$(dirname "$MISE_INSTALL_PATH"):$PATH"
}

clone_dotfiles() {
    if [[ ! -e "$SOURCE_DIR" ]]; then
      log "Cloning dotfiles"
      git clone "$DOTFILES_REPO" "$SOURCE_DIR"
    elif [[ ! -d "$SOURCE_DIR/.git" ]]; then
      die "$SOURCE_DIR exists but is not a Git repository"
    fi
}

bootstrap_mise() {
    cd "$SOURCE_DIR"

    log "Trusting the dotfiles configuration"
    "$MISE_INSTALL_PATH" trust --all
    "$MISE_INSTALL_PATH" trust --show

    log "Bootstrapping the machine"
    MISE_AUTO_ENV=1 MISE_ENV="$PROFILE" "$MISE_INSTALL_PATH" bootstrap --force-dotfiles -y
}

run_mise_doctor(){
    log "Mise state (doctor)"
    "$MISE_INSTALL_PATH" doctor
}

get_osversion
install_mise
clone_dotfiles
bootstrap_mise
run_mise_doctor
printf "\n%sBootstrap complete. Restart your shell to finish.%s\n" "$GREEN" "$RESET"
