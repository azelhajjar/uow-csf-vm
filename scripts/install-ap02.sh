#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AP02_ROOT="/opt/cav-csf/ap02"
PREFIX="$AP02_ROOT/proftpd"
CONFIG_DIR="/etc/cav-csf/ap02"
SOURCE_DIR="/usr/local/src/cav-csf/ap02"
ARCHIVE="$SOURCE_DIR/proftpd-1.3.5.tar.gz"
SOURCE_URL="https://ftp.ntu.edu.tw/proftpd/distrib/source/proftpd-1.3.5.tar.gz"
SOURCE_SHA256="c10316fb003bd25eccbc08c77dd9057e053693e6527ffa2ea2cc4e08ccb87715"
WEB_ROOT="/var/www/brightleaf-ap02"
UNIT="cav-csf-ap02-proftpd.service"

log() { printf '[INFO] %s\n' "$*"; }
die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }
require_root() { [ "${EUID:-$(id -u)}" -eq 0 ] || die "run as root with sudo"; }

check_os() {
  # shellcheck disable=SC1091
  . /etc/os-release
  [ "${ID:-}" = ubuntu ] && [ "${VERSION_ID:-}" = 26.04 ] || die "AP-02 supports only Ubuntu 26.04"
}

check_port() {
  local port="$1" expected="$2"
  if ss -H -ltn "sport = :$port" | grep -q .; then
    systemctl is-active --quiet "$expected" 2>/dev/null || die "TCP $port is occupied by an unrelated service"
  fi
}

install_packages() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y apache2 build-essential ca-certificates curl libapache2-mod-php php
}

obtain_source() {
  install -d -o root -g root -m 0755 "$SOURCE_DIR"
  if [ -n "${PROFTPD_SOURCE_ARCHIVE:-}" ]; then
    [ -f "$PROFTPD_SOURCE_ARCHIVE" ] || die "PROFTPD_SOURCE_ARCHIVE does not exist"
    install -o root -g root -m 0644 "$PROFTPD_SOURCE_ARCHIVE" "$ARCHIVE"
  elif [ ! -f "$ARCHIVE" ]; then
    log "Downloading pinned ProFTPD source"
    curl --fail --location --proto '=https' --tlsv1.2 "$SOURCE_URL" --output "$ARCHIVE"
  fi
  printf '%s  %s\n' "$SOURCE_SHA256" "$ARCHIVE" | sha256sum --check --status || die "ProFTPD source checksum mismatch"
}

build_proftpd() {
  local build_dir
  build_dir="$(mktemp -d)"
  tar -xzf "$ARCHIVE" -C "$build_dir"
  pushd "$build_dir/proftpd-1.3.5" >/dev/null
  CFLAGS='-O2 -std=gnu17' ./configure --prefix="$PREFIX" --with-modules=mod_copy --disable-auth-pam
  make -j"$(nproc)"
  make install
  popd >/dev/null
  rm -rf "$build_dir"
  "$PREFIX/sbin/proftpd" -v | grep -Fq '1.3.5' || die "built ProFTPD version is not 1.3.5"
  "$PREFIX/sbin/proftpd" -l | grep -Fq 'mod_copy.c' || die "mod_copy was not compiled into ProFTPD"
}

configure_web() {
  install -d -o www-data -g www-data -m 0750 "$WEB_ROOT"
  install -o www-data -g www-data -m 0644 "$ROOT_DIR/assets/ap02/web/index.php" "$WEB_ROOT/index.php"
  cat >/etc/apache2/sites-available/cav-csf-ap02.conf <<EOF
<VirtualHost *:80>
    ServerName warehouse.brightleaf.test
    DocumentRoot $WEB_ROOT
    <Directory $WEB_ROOT>
        Options -Indexes
        AllowOverride None
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/cav-csf-ap02-error.log
    CustomLog \${APACHE_LOG_DIR}/cav-csf-ap02-access.log combined
</VirtualHost>
EOF
  a2dissite 000-default >/dev/null 2>&1 || true
  a2ensite cav-csf-ap02 >/dev/null
  apache2ctl configtest
  systemctl enable --now apache2.service
  systemctl restart apache2.service
}

configure_proftpd() {
  install -d -o root -g root -m 0755 "$AP02_ROOT" "$CONFIG_DIR"
  install -d -o www-data -g www-data -m 0750 "$AP02_ROOT/run" "$AP02_ROOT/log"
  cat >"$CONFIG_DIR/proftpd.conf" <<EOF
ServerName                      "Brightleaf Document Transfer"
ServerType                      standalone
DefaultServer                   on
Port                            2121
UseIPv6                         off
User                            www-data
Group                           www-data
Umask                           027
RequireValidShell               off
PidFile                         $AP02_ROOT/run/proftpd.pid
ScoreboardFile                  $AP02_ROOT/run/proftpd.scoreboard
SystemLog                       $AP02_ROOT/log/proftpd.log
TransferLog                     $AP02_ROOT/log/xferlog
TimeoutIdle                     600
TimeoutNoTransfer               300
TimeoutStalled                  300
<Directory $WEB_ROOT>
  <Limit ALL>
    AllowAll
  </Limit>
</Directory>
EOF
  "$PREFIX/sbin/proftpd" -t -c "$CONFIG_DIR/proftpd.conf"
  cat >/etc/systemd/system/$UNIT <<EOF
[Unit]
Description=CAV-CSF AP-02 vulnerable ProFTPD 1.3.5 service
After=network.target apache2.service

[Service]
Type=forking
PIDFile=$AP02_ROOT/run/proftpd.pid
ExecStart=$PREFIX/sbin/proftpd -c $CONFIG_DIR/proftpd.conf
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable --now "$UNIT"
  systemctl restart "$UNIT"
}

main() {
  require_root
  check_os
  check_port 2121 "$UNIT"
  check_port 80 apache2.service
  install_packages
  obtain_source
  build_proftpd
  configure_web
  configure_proftpd
  "$ROOT_DIR/scripts/verify-ap02.sh"
}

main "$@"
