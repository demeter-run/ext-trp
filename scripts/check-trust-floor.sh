#!/bin/sh
# Fails when Cargo.lock carries a TLS trust crate below its floor:
# webpki-roots / webpki-root-certs < 1.0.10, rustls-webpki < 0.103.16.
# Usage: scripts/check-trust-floor.sh [path/to/Cargo.lock]
set -eu

lock="${1:-Cargo.lock}"
[ -f "$lock" ] || { echo "trust floor: $lock not found" >&2; exit 2; }

awk '
function lt(v, floor,   a, b, n, i, x, y) {
  sub(/[-+].*/, "", v)
  n = split(v, a, ".")
  split(floor, b, ".")
  for (i = 1; i <= 3; i++) {
    x = (i <= n) ? a[i] + 0 : 0
    y = b[i] + 0
    if (x < y) return 1
    if (x > y) return 0
  }
  return 0
}
/^name = "/ { name = $3; gsub(/"/, "", name); next }
/^version = "/ {
  v = $3; gsub(/"/, "", v)
  floor = ""
  if (name == "webpki-roots" || name == "webpki-root-certs") floor = "1.0.10"
  else if (name == "rustls-webpki") floor = "0.103.16"
  if (floor != "" && lt(v, floor)) {
    printf "trust floor: %s %s is below %s\n", name, v, floor
    bad = 1
  }
  name = ""
}
END { exit bad }
' "$lock" || { echo "trust floor: FAILED for $lock" >&2; exit 1; }

echo "trust floor: ok ($lock)"
