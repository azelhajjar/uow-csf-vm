#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="/etc/ssh/sshd_config.d/10-cav-csf-admin.conf"
STATE_DIR="/var/lib/cav-csf/admin-ssh"
PORT_FILE="/etc/cav-csf/admin-ssh-port"

log() { printf '[INFO] %s\n' "$*"; }
die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

require_root() {
  [ "${EUID:-$(id -u)}" -eq 0 ] || die "run as root with sudo"
}

valid_port() {
  [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 1024 ] && [ "$1" -le 65535 ] && [ "$1" -ne 22 ]
}

admin_user() {
  local user="${SUDO_USER:-}"
  [ -n "$user" ] && [ "$user" != "root" ] || die "run through sudo from the administrative account"
  id "$user" >/dev/null 2>&1 || die "administrative account $user does not exist"
  printf '%s\n' "$user"
}

write_config() {
  local port="$1" user="$2" keep_port_22="$3"
  local temp
  temp="$(mktemp)"
  {
    printf '# Managed by CAV-CSF. Use scripts/configure-admin-ssh.sh to change.\n'
    if [ "$keep_port_22" = "yes" ]; then
      printf 'Port 22\n'
    fi
    printf 'Port %s\n' "$port"
    printf 'PermitRootLogin no\n'
    printf 'PasswordAuthentication no\n'
    printf 'KbdInteractiveAuthentication no\n'
    printf 'PubkeyAuthentication yes\n'
    printf 'AllowUsers %s\n' "$user"
  } >"$temp"
  install -o root -g root -m 0644 "$temp" "$CONFIG_FILE"
  rm -f "$temp"
  sshd -t
}

restart_admin_ssh() {
  # Ubuntu enables socket activation by default. Its generated socket unit can
  # bind only the first configured port, preventing sshd from opening both the
  # temporary migration port and TCP 22. Use the standalone service instead.
  if systemctl list-unit-files ssh.socket >/dev/null 2>&1; then
    systemctl disable --now ssh.socket
  fi
  systemctl enable ssh.service
  systemctl restart ssh.service
}

prepare() {
  local port="$1" user="$2"
  local home
  home="$(getent passwd "$user" | cut -d: -f6)"
  [ -s "$home/.ssh/authorized_keys" ] || die "$user has no non-empty authorized_keys file; key-only migration would lock you out"
  ! ss -H -ltn "sport = :$port" | grep -q . || die "TCP $port is already listening"

  mkdir -p "$STATE_DIR" /etc/cav-csf
  chmod 0700 "$STATE_DIR" /etc/cav-csf
  if [ -f "$CONFIG_FILE" ] && [ ! -f "$STATE_DIR/10-cav-csf-admin.conf.before" ]; then
    cp -a "$CONFIG_FILE" "$STATE_DIR/10-cav-csf-admin.conf.before"
  fi

  write_config "$port" "$user" yes
  restart_admin_ssh
  printf '%s\n' "$port" >"$PORT_FILE"
  chmod 0600 "$PORT_FILE"
  rm -f "$STATE_DIR/port-22-released"

  log "administrative SSH now listens on TCP 22 and TCP $port"
  log "keep this session open and test a new key-authenticated session:"
  printf '  ssh -p %s %s@<vm-address>\n' "$port" "$user"
  log "after that succeeds, run: sudo $0 finalize $port"
}

finalize() {
  local port="$1" user="$2"
  [ -r "$PORT_FILE" ] || die "prepare has not recorded a management port"
  [ "$(cat "$PORT_FILE")" = "$port" ] || die "port does not match the prepared management port"
  printf 'Type TESTED to confirm a second administrative SSH session works on TCP %s: ' "$port"
  read -r confirmation
  [ "$confirmation" = "TESTED" ] || die "confirmation not received; TCP 22 remains administrative"

  write_config "$port" "$user" no
  restart_admin_ssh
  touch "$STATE_DIR/port-22-released"
  chmod 0600 "$STATE_DIR/port-22-released"
  log "administrative SSH is restricted to TCP $port; TCP 22 is released"
  log "keep the tested management session open while installing AP-01"
}

main() {
  require_root
  command -v sshd >/dev/null 2>&1 || die "openssh-server is not installed"
  command -v ss >/dev/null 2>&1 || die "ss is not installed"
  [ "$#" -eq 2 ] || die "usage: sudo $0 prepare|finalize MANAGEMENT_PORT"
  valid_port "$2" || die "management port must be an unused number from 1024 to 65535, excluding 22"
  local user
  user="$(admin_user)"
  case "$1" in
    prepare) prepare "$2" "$user" ;;
    finalize) finalize "$2" "$user" ;;
    *) die "usage: sudo $0 prepare|finalize MANAGEMENT_PORT" ;;
  esac
}

main "$@"
