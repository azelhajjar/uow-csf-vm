#!/usr/bin/env bash
set -u

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

unavailable() {
  printf 'DEPENDENCY UNAVAILABLE: %s\n' "$1"
  failures=$((failures + 1))
}

check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    pass "$1 is installed"
  else
    unavailable "$1 is not installed"
  fi
}

printf 'CAV-CSF base VM verification\n'
printf '============================\n'

if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  if [ "${ID:-}" = "ubuntu" ] && [ "${VERSION_ID:-}" = "26.04" ]; then
    pass "supported operating system detected (${PRETTY_NAME:-Ubuntu 26.04})"
  else
    fail "unsupported operating system (${PRETTY_NAME:-unknown}); expected Ubuntu 26.04"
  fi
else
  fail "/etc/os-release is not readable"
fi

for tool in git curl wget python3 pip3 docker systemctl ss ip; do
  check_command "$tool"
done

if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    pass "Docker daemon is reachable"
  else
    fail "Docker is installed but the daemon is not reachable"
  fi

  if docker compose version >/dev/null 2>&1; then
    pass "Docker Compose plugin is available"
  elif command -v docker-compose >/dev/null 2>&1; then
    pass "legacy docker-compose command is available"
  else
    unavailable "Docker Compose is not available"
  fi
fi

if command -v systemctl >/dev/null 2>&1; then
  if systemctl is-enabled --quiet docker 2>/dev/null; then
    pass "Docker service is enabled"
  else
    fail "Docker service is not enabled"
  fi

  if systemctl is-active --quiet docker 2>/dev/null; then
    pass "Docker service is active"
  else
    fail "Docker service is not active"
  fi

  failed_units="$(systemctl --failed --no-legend --plain 2>/dev/null | sed '/^[[:space:]]*$/d' || true)"
  if [ -z "$failed_units" ]; then
    pass "no failed systemd units"
  else
    fail "failed systemd units detected"
    printf '%s\n' "$failed_units"
  fi
fi

if [ "$failures" -eq 0 ]; then
  printf '\nRESULT: PASS\n'
  exit 0
fi

printf '\nRESULT: FAIL (%d check(s) failed)\n' "$failures"
exit 1
