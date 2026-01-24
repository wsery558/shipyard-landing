#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT="shipyard-tsaielectro"
PROD="https://shipyard.tsaielectro.com"

# Get latest PRODUCTION deployment URL from wrangler
PAGES_LATEST="$(
  pnpm dlx wrangler@latest pages deployment list --project-name "$PROJECT" --environment production \
    | rg -m 1 -o 'https://[0-9a-f]{8}\.'"$PROJECT"'\.pages\.dev' || true
)"

if [[ -z "${PAGES_LATEST:-}" ]]; then
  echo "❌ Could not determine latest production Pages deployment URL for $PROJECT"
  echo "   Try: pnpm dlx wrangler@latest pages deployment list --project-name $PROJECT --environment production"
  exit 1
fi

echo "🔎 Latest production Pages URL: $PAGES_LATEST"
echo "🔎 Custom domain:              $PROD"
echo ""

TS="$(date +%s)"

check_demo() {
  local base="$1"
  echo "== CHECK $base/demo/ =="

  local demo_html
  demo_html="$(curl -fsS -H 'Cache-Control: no-cache' "$base/demo/?ts=$TS")" || {
    echo "❌ Failed to fetch $base/demo/"
    exit 1
  }

  # markers in HTML
  printf "%s" "$demo_html" | rg -n "assets/app\.js" >/dev/null || {
    echo "❌ missing assets/app.js script tag"
    printf "%s\n" "$demo_html" | sed -n '1,140p'
    exit 1
  }
  printf "%s" "$demo_html" | rg -n "page-demo|data-demo-tab|data-demo-panel" >/dev/null || {
    echo "❌ missing new demo DOM markers"
    printf "%s\n" "$demo_html" | sed -n '1,200p'
    exit 1
  }

  # app.js must contain demo initializer strings
  curl -fsS -H 'Cache-Control: no-cache' "$base/assets/app.js?ts=$TS" \
    | rg -n "shipyard_demo_tab|demo_page_view|demo_tab_click|demo_evidence_pack_click" >/dev/null || {
      echo "❌ app.js missing demo initializer strings"
      exit 1
    }

  echo "OK"
  echo ""
}

check_demo "$PAGES_LATEST"
check_demo "$PROD"

echo "✅ demo verified on latest production Pages URL + custom domain"
