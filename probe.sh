#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
N="${1:-30}"
case "$N" in ''|*[!0-9]*) echo "Uso: ./probe.sh [numero_de_solicitudes]" >&2; exit 2;; esac
if [ "$N" -lt 3 ] || [ "$N" -gt 30 ]; then
  echo "El numero de solicitudes debe estar entre 3 y 30." >&2
  exit 2
fi
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
ok=0
err=0
for _ in $(seq 1 "$N"); do
  if out=$(./exam-client 2>/dev/null); then
    val=${out#duration_ms=}
    printf '%s\n' "$val" >> "$TMP"
    ok=$((ok+1))
  else
    err=$((err+1))
  fi
done
if [ "$ok" -gt 0 ]; then
  sort -n "$TMP" -o "$TMP"
  p50_idx=$(( (ok + 1) / 2 ))
  p95_idx=$(( (95 * ok + 99) / 100 ))
  p50=$(sed -n "${p50_idx}p" "$TMP")
  p95=$(sed -n "${p95_idx}p" "$TMP")
  avg=$(awk '{s+=$1} END {if(NR) printf "%.1f", s/NR; else print "NA"}' "$TMP")
else
  p50=NA; p95=NA; avg=NA
fi
printf 'requests:    %d\n' "$N"
printf 'successful:  %d\n' "$ok"
printf 'errors:      %d\n' "$err"
printf 'average_ms:  %s\n' "$avg"
printf 'p50_ms:      %s\n' "$p50"
printf 'p95_ms:      %s\n' "$p95"
[ "$err" -eq 0 ]
