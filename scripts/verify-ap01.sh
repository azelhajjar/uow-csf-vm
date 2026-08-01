#!/usr/bin/env bash
set -u

STATE_DIR="/var/lib/cav-csf/ap01"
failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

teaching_ssh() {
  local port="$1"
  shift
  sshpass -p "$TEACHING_PASSWORD" ssh \
    -o PreferredAuthentications=password \
    -o PubkeyAuthentication=no \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=5 \
    -p "$port" "$TEACHING_USERNAME@127.0.0.1" "$@"
}

printf 'CAV-CSF AP-01 verification\n'
printf '==========================\n'

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  printf 'FAIL: run as root with sudo (credential checks require protected state)\n'
  exit 1
fi
if [ ! -r "$STATE_DIR/credentials.env" ]; then
  printf 'FAIL: AP-01 credential state is unavailable\n'
  exit 1
fi
# shellcheck disable=SC1091
. "$STATE_DIR/credentials.env"
ADMIN_PORT="$(cat /etc/cav-csf/admin-ssh-port 2>/dev/null || true)"

check "FTP listens on TCP 21" "ss -H -ltn 'sport = :21' | grep -q ."
check "FTP anonymous root is not writable by the ftp account" "[ \"\$(stat -c %U:%G:%a /srv/ftp)\" = 'root:root:755' ]"
FTP_CHECK="$(mktemp)"
if curl --silent --show-error --fail ftp://127.0.0.1/support-ticket-BL-48217.txt >"$FTP_CHECK"; then
  pass "anonymous FTP clue is readable"
else
  fail "anonymous FTP clue is not readable"
fi
if grep -Fq "profile: $TEACHING_USERNAME" "$FTP_CHECK"; then
  pass "FTP clue contains the current teaching username"
else
  fail "FTP clue does not contain the current teaching username"
fi
rm -f "$FTP_CHECK"

check "teaching SSH listens on TCP 22" "ss -H -ltn 'sport = :22' | grep -q ."
if teaching_ssh 22 'test "$(id -un)" = stockroom' >/dev/null 2>&1; then
  pass "stockroom authenticates to teaching SSH"
else
  fail "stockroom cannot authenticate to teaching SSH"
fi

if [ -n "$ADMIN_PORT" ]; then
  if teaching_ssh "$ADMIN_PORT" true >/dev/null 2>&1; then
    fail "teaching credentials were accepted by administrative SSH"
  else
    pass "teaching credentials are rejected by administrative SSH"
  fi
else
  fail "administrative SSH port record is missing"
fi

groups="$(id -nG "$TEACHING_USERNAME" 2>/dev/null || true)"
if printf '%s\n' "$groups" | tr ' ' '\n' | grep -Eq '^(sudo|adm)$'; then
  fail "stockroom has an administrative group membership"
else
  pass "stockroom has no sudo or adm group membership"
fi
check "AP-01 sudoers file is valid" "visudo -cf /etc/sudoers.d/cav-csf-ap01-stockroom >/dev/null 2>&1"
check "AP-01 sudoers rule is exact" "grep -Fxq 'stockroom ALL=(root) NOPASSWD: /usr/bin/find' /etc/sudoers.d/cav-csf-ap01-stockroom"
check "approved find route executes with effective UID 0" "sudo -u stockroom sudo -n /usr/bin/find /dev/null -maxdepth 0 -exec /usr/bin/id -u \\; 2>/dev/null | grep -Fxq 0"

if [ "$failures" -eq 0 ]; then
  printf '\nRESULT: PASS\n'
  exit 0
fi
printf '\nRESULT: FAIL (%d check(s) failed)\n' "$failures"
exit 1
