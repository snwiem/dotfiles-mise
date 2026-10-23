#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/snwiem/dotfiles-mise.git}"
SOURCE_DIR="$HOME/Source/dotfiles-mise"
MISE_INSTALL_PATH="${MISE_INSTALL_PATH:-$HOME/.local/bin/mise}"
MISE_INSTALL_SKIP_IF_EXISTS="${MISE_INSTALL_SKIP_IF_EXISTS:-1}"
PROFILE="${PROFILE:-default}"
WORK_CONFIG_NEEDS_SETUP=false

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

install_mise
clone_dotfiles
bootstrap_mise
printf "\n%sBootstrap complete. Restart your shell to finish.%s\n" "$GREEN" "$RESET"
