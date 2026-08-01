#!/usr/bin/env bash
set -u

PREFIX="/opt/cav-csf/ap02/proftpd"
CONFIG="/etc/cav-csf/ap02/proftpd.conf"
WEB_ROOT="/var/www/brightleaf-ap02"
UNIT="cav-csf-ap02-proftpd.service"
failures=0

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

printf 'CAV-CSF AP-02 provisioning verification (non-exploit)\n'
printf '=====================================================\n'

[ "${EUID:-$(id -u)}" -eq 0 ] || { fail "run as root with sudo"; printf '\nRESULT: FAIL\n'; exit 1; }
check "ProFTPD binary is installed in the AP-02 prefix" "[ -x '$PREFIX/sbin/proftpd' ]"
check "ProFTPD reports pinned version 1.3.5" "'$PREFIX/sbin/proftpd' -v 2>/dev/null | grep -Fq '1.3.5'"
check "mod_copy is compiled into ProFTPD" "'$PREFIX/sbin/proftpd' -l 2>/dev/null | grep -Fq 'mod_copy.c'"
check "AP-02 ProFTPD configuration parses" "'$PREFIX/sbin/proftpd' -t -c '$CONFIG' >/dev/null 2>&1"
check "AP-02 ProFTPD service is enabled" "systemctl is-enabled --quiet '$UNIT'"
check "AP-02 ProFTPD service is active" "systemctl is-active --quiet '$UNIT'"
check "ProFTPD listens on TCP 2121" "ss -H -ltn 'sport = :2121' | grep -q ."
check "Apache service is active" "systemctl is-active --quiet apache2.service"
check "Apache listens on TCP 80" "ss -H -ltn 'sport = :80' | grep -q ."
check "Brightleaf AP-02 page responds" "curl --silent --show-error --fail -H 'Host: warehouse.brightleaf.test' http://127.0.0.1/ | grep -Fq 'Brightleaf Warehouse Document Service'"
check "AP-02 web root has bounded service ownership" "[ \"\$(stat -c %U:%G:%a '$WEB_ROOT')\" = 'www-data:www-data:750' ]"

if ss -H -ltn 'sport = :21' | grep -q .; then pass "AP-01 FTP remains reachable on TCP 21"; else fail "AP-01 FTP is not listening on TCP 21"; fi
if ss -H -ltn 'sport = :22' | grep -q .; then pass "teaching SSH remains reachable on TCP 22"; else fail "teaching SSH is not listening on TCP 22"; fi
if ss -H -ltn 'sport = :22222' | grep -q .; then pass "administrative SSH remains reachable on TCP 22222"; else fail "administrative SSH is not listening on TCP 22222"; fi

printf '\nNOTE: exploit commands and command execution were not tested.\n'
if [ "$failures" -eq 0 ]; then printf 'RESULT: PASS\n'; exit 0; fi
printf 'RESULT: FAIL (%d check(s) failed)\n' "$failures"
exit 1
