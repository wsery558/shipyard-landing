#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

PROJECT="shipyard-tsaielectro"
PROD="https://shipyard.tsaielectro.com"

PAGES_LATEST="$(
  pnpm dlx wrangler@latest pages deployment list --project-name "$PROJECT" --environment production \
    | rg -m 1 -o "https://[0-9a-f]{8}\\.${PROJECT}\\.pages\\.dev" || true
)"

if [[ -z "${PAGES_LATEST:-}" ]]; then
  echo "❌ Could not determine latest production Pages deployment URL for $PROJECT"
  exit 1
fi

echo "🔎 Latest production Pages URL: $PAGES_LATEST"
echo "🔎 Custom domain:              $PROD"
echo ""

TS="$(date +%s)"
ok=1

check_one () {
  local base="$1"
  echo "== CHECK $base/en/ =="
  local html
  html="$(curl -fsS -H 'Cache-Control: no-cache' "$base/en/?ts=$TS")" || { echo "❌ fetch failed"; return 1; }

  echo "$html" | rg -n 'class="brand-mark"' >/dev/null || { echo "❌ missing marker: brand-mark"; return 1; }
  echo "$html" | rg -n 'class="brand-logo"' >/dev/null || { echo "❌ missing marker: brand-logo"; return 1; }
  echo "$html" | rg -n '/assets/shipyard-logo\.png' >/dev/null || { echo "❌ missing asset path: shipyard-logo.png"; return 1; }
  echo "$html" | rg -n 'class="brand-dot"' >/dev/null || { echo "❌ missing marker: brand-dot"; return 1; }

  echo "OK"
}

check_one "$PAGES_LATEST" || ok=0
echo ""
check_one "$PROD" || ok=0

echo ""
if [[ $ok -eq 1 ]]; then
  echo "✅ brand mark verified on Pages hash + custom domain"
  exit 0
else
  echo "❌ brand mark check failed"
  exit 1
fi
