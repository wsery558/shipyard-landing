#!/usr/bin/env bash
set -euo pipefail

cd /home/ken/code/shipyard-landing

TS="$(date +%s)"

declare -A SITES=(
  ["Pages"]="https://shipyard-tsaielectro.pages.dev"
  ["Custom"]="https://shipyard.tsaielectro.com"
)

for LABEL in "${!SITES[@]}"; do
  BASE="${SITES[$LABEL]}"
  TARGET="${BASE}/en/?ts=${TS}"
  echo "== Checking ${LABEL} (${TARGET}) =="

  HTML="$(curl -fsS -H 'Cache-Control: no-cache' "${TARGET}")"
  if ! printf '%s' "$HTML" | rg -q "brand-logo"; then
    echo "❌ ${LABEL} missing 'brand-logo' marker"
    exit 1
  fi
  if ! printf '%s' "$HTML" | rg -q "/assets/shipyard-logo\\.png"; then
    echo "❌ ${LABEL} missing '/assets/shipyard-logo.png' reference"
    exit 1
  fi

  echo "✅ ${LABEL} renders the Shipyard logo"
  echo ""
done

echo "✅ Brand logo verified on all production URLs."
