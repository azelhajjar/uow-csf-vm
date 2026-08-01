#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="/var/lib/cav-csf/ap01"
CONFIG_DIR="/etc/cav-csf/ap01"
FTP_ROOT="/srv/ftp"
HOME_TEMPLATE="/usr/share/cav-csf/ap01/home"
USERNAME="stockroom"

log() { printf '[INFO] %s\n' "$*"; }
die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

require_root() { [ "${EUID:-$(id -u)}" -eq 0 ] || die "run as root with sudo"; }

require_admin_gate() {
  [ -f /var/lib/cav-csf/admin-ssh/port-22-released ] || die "administrative SSH migration is not finalized; do not claim TCP 22"
  [ -r /etc/cav-csf/admin-ssh-port ] || die "administrative SSH port record is missing"
  local port
  port="$(cat /etc/cav-csf/admin-ssh-port)"
  ss -H -ltn "sport = :$port" | grep -q . || die "administrative SSH is not listening on recorded TCP $port"
  ! ss -H -ltn "sport = :22" | grep -q . || die "TCP 22 is still occupied"
}

install_packages() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y openssh-server openssl sshpass sudo vsftpd
}

create_account_and_secret() {
  mkdir -p "$STATE_DIR" "$CONFIG_DIR"
  chmod 0700 "$STATE_DIR" "$CONFIG_DIR"
  if ! id "$USERNAME" >/dev/null 2>&1; then
    useradd --create-home --shell /bin/bash "$USERNAME"
  fi
  usermod -s /bin/bash "$USERNAME"
  gpasswd -d "$USERNAME" sudo >/dev/null 2>&1 || true
  gpasswd -d "$USERNAME" adm >/dev/null 2>&1 || true

  local password
  password="$(openssl rand -base64 18 | tr -d '\n')"
  printf '%s:%s\n' "$USERNAME" "$password" | chpasswd
  {
    printf 'TEACHING_USERNAME=%q\n' "$USERNAME"
    printf 'TEACHING_PASSWORD=%q\n' "$password"
  } >"$STATE_DIR/credentials.env"
  chmod 0600 "$STATE_DIR/credentials.env"
}

install_templates() {
  rm -rf "$HOME_TEMPLATE"
  install -d -o root -g root -m 0755 "$HOME_TEMPLATE"
  cp -a "$ROOT_DIR/assets/ap01/home/." "$HOME_TEMPLATE/"
  chown -R root:root "$HOME_TEMPLATE"

  # vsftpd refuses anonymous login when the chroot root is writable by the
  # anonymous account. Keep the published tree root-owned and read-only.
  install -d -o root -g root -m 0755 "$FTP_ROOT"
  # shellcheck disable=SC1091
  . "$STATE_DIR/credentials.env"
  sed -e "s/@TEACHING_USERNAME@/$TEACHING_USERNAME/g" \
      -e "s/@TEACHING_PASSWORD@/$TEACHING_PASSWORD/g" \
      "$ROOT_DIR/assets/ap01/ftp/support-ticket-BL-48217.txt.in" >"$FTP_ROOT/support-ticket-BL-48217.txt"
  chown root:root "$FTP_ROOT/support-ticket-BL-48217.txt"
  chmod 0644 "$FTP_ROOT/support-ticket-BL-48217.txt"

  cp -a "$HOME_TEMPLATE/." "/home/$USERNAME/"
  chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"
}

configure_ftp() {
  cat >"$CONFIG_DIR/vsftpd.conf" <<'EOF'
listen=YES
listen_ipv6=NO
anonymous_enable=YES
local_enable=NO
write_enable=NO
anon_root=/srv/ftp
no_anon_password=YES
hide_ids=YES
pasv_min_port=30000
pasv_max_port=30009
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
EOF
  install -o root -g root -m 0644 "$CONFIG_DIR/vsftpd.conf" /etc/vsftpd.conf
  systemctl enable --now vsftpd.service
  systemctl restart vsftpd.service
}

configure_teaching_ssh() {
  install -d -o root -g root -m 0700 /etc/ssh/cav-csf-teaching
  if [ ! -f /etc/ssh/cav-csf-teaching/ssh_host_ed25519_key ]; then
    ssh-keygen -q -t ed25519 -N '' -f /etc/ssh/cav-csf-teaching/ssh_host_ed25519_key
  fi
  cat >"$CONFIG_DIR/sshd_config" <<'EOF'
Port 22
ListenAddress 0.0.0.0
Protocol 2
HostKey /etc/ssh/cav-csf-teaching/ssh_host_ed25519_key
PidFile /run/cav-csf-teaching-sshd.pid
PermitRootLogin no
PubkeyAuthentication no
PasswordAuthentication yes
KbdInteractiveAuthentication no
UsePAM yes
AllowUsers stockroom
X11Forwarding no
AllowTcpForwarding no
PermitTunnel no
GatewayPorts no
PermitUserEnvironment no
Subsystem sftp internal-sftp
EOF
  /usr/sbin/sshd -t -f "$CONFIG_DIR/sshd_config"

  cat >/etc/systemd/system/cav-csf-teaching-ssh.service <<EOF
[Unit]
Description=CAV-CSF teaching SSH service
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/sshd -D -e -f $CONFIG_DIR/sshd_config
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable --now cav-csf-teaching-ssh.service
}

configure_sudo() {
  local temp
  temp="$(mktemp)"
  printf '%s ALL=(root) NOPASSWD: /usr/bin/find\n' "$USERNAME" >"$temp"
  chmod 0440 "$temp"
  visudo -cf "$temp" >/dev/null
  install -o root -g root -m 0440 "$temp" /etc/sudoers.d/cav-csf-ap01-stockroom
  rm -f "$temp"
  visudo -cf /etc/sudoers.d/cav-csf-ap01-stockroom >/dev/null
}

main() {
  require_root
  require_admin_gate
  install_packages
  create_account_and_secret
  install_templates
  configure_ftp
  configure_teaching_ssh
  configure_sudo
  log "AP-01 installed; running verification"
  "$ROOT_DIR/scripts/verify-ap01.sh"
}

main "$@"
