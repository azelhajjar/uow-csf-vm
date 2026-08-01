#!/usr/bin/env bash
set -euo pipefail

REQUIRED_ID="ubuntu"
REQUIRED_VERSION_ID="26.04"

log() {
  printf '[INFO] %s\n' "$*"
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

require_root() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    die "run as root with sudo"
  fi
}

check_os() {
  if [ ! -r /etc/os-release ]; then
    die "/etc/os-release is not readable"
  fi

  # shellcheck disable=SC1091
  . /etc/os-release

  if [ "${ID:-}" != "$REQUIRED_ID" ] || [ "${VERSION_ID:-}" != "$REQUIRED_VERSION_ID" ]; then
    die "unsupported OS: ${PRETTY_NAME:-unknown}. Expected Ubuntu 26.04"
  fi

  log "OS check passed: ${PRETTY_NAME:-Ubuntu 26.04}"
}

apt_install_base() {
  export DEBIAN_FRONTEND=noninteractive

  log "Updating package index"
  apt-get update

  log "Installing base packages"
  apt-get install -y \
    ca-certificates \
    curl \
    docker-compose-v2 \
    docker.io \
    git \
    python3 \
    python3-pip \
    unzip \
    wget
}

configure_docker() {
  log "Enabling Docker service"
  systemctl enable --now docker

  if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    log "Adding $SUDO_USER to docker group"
    usermod -aG docker "$SUDO_USER"
    log "$SUDO_USER must log out and back in before docker group membership applies"
  fi
}

show_summary() {
  log "Base install summary"
  command -v python3
  command -v pip3
  command -v docker

  if docker compose version >/dev/null 2>&1; then
    docker compose version
  elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose version
  else
    log "Docker Compose command not found"
  fi
}

main() {
  require_root
  check_os
  apt_install_base
  configure_docker
  show_summary
  log "Base tooling installation complete"
}

main "$@"
