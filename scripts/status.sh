#!/usr/bin/env bash
set -u

section() {
  printf '\n== %s ==\n' "$1"
}

run_or_note() {
  local label="$1"
  shift

  printf '%s: ' "$label"
  if command -v "$1" >/dev/null 2>&1; then
    "$@"
  else
    printf 'not available\n'
  fi
}

section "CAV-CSF VM status"
printf 'Date: %s\n' "$(date -Is 2>/dev/null || date)"
printf 'User: %s\n' "$(id -un 2>/dev/null || whoami)"
printf 'Hostname: %s\n' "$(hostname 2>/dev/null || printf 'unknown')"

section "Operating system"
if [ -r /etc/os-release ]; then
  . /etc/os-release
  printf 'Name: %s\n' "${PRETTY_NAME:-unknown}"
  printf 'ID: %s\n' "${ID:-unknown}"
  printf 'Version ID: %s\n' "${VERSION_ID:-unknown}"
else
  printf '/etc/os-release not readable\n'
fi

section "Kernel"
uname -a

section "Network addresses"
if command -v ip >/dev/null 2>&1; then
  ip -br addr
elif command -v ifconfig >/dev/null 2>&1; then
  ifconfig
else
  printf 'Neither ip nor ifconfig is available\n'
fi

section "Disk usage"
df -h /

section "Key tools"
for tool in git curl wget python3 pip3 docker systemctl ss ip ifconfig; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf '%-15s %s\n' "$tool" "$(command -v "$tool")"
  else
    printf '%-15s missing\n' "$tool"
  fi
done

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  printf '%-15s %s\n' "docker compose" "$(docker compose version --short 2>/dev/null || docker compose version)"
elif command -v docker-compose >/dev/null 2>&1; then
  printf '%-15s %s\n' "docker-compose" "$(command -v docker-compose)"
else
  printf '%-15s missing\n' "docker compose"
fi

section "Failed systemd units"
if command -v systemctl >/dev/null 2>&1; then
  systemctl --failed --no-pager
else
  printf 'systemctl not available\n'
fi

section "Listening ports"
if command -v ss >/dev/null 2>&1; then
  ss -tuln
else
  printf 'ss not available\n'
fi

section "Repository"
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'Branch: %s\n' "$(git branch --show-current 2>/dev/null || printf 'unknown')"
  printf 'Commit: %s\n' "$(git rev-parse --short HEAD 2>/dev/null || printf 'unknown')"
  git status --short
else
  printf 'Not running inside a Git work tree, or git is unavailable\n'
fi
