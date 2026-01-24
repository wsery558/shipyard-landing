#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT="shipyard-tsaielectro"
PROD="https://shipyard.tsaielectro.com"

PAGES_LATEST="$(
  pnpm dlx wrangler@latest pages deployment list --project-name "$PROJECT" --environment production \
    | rg -m 1 -o "https://[0-9a-f]{8}\.${PROJECT}\.pages\.dev" || true
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

check_brand() {
  local base="$1"
  local label="$2"
  echo "== CHECK ${label} (${base}/en/) =="

  local html
  if ! html="$(curl -fsS -H 'Cache-Control: no-cache' "${base}/en/?ts=${TS}")"; then
    echo "❌ Failed to fetch ${base}/en/"
    echo ""
    return 1
  fi

  local missing=0
  for marker in brand-logo shipyard-mark brand-dot; do
    if ! printf '%s' "$html" | rg -q "$marker"; then
      echo "❌ Missing marker '$marker' in ${label}"
      missing=1
    fi
  done

  if [[ $missing -ne 0 ]]; then
    printf "%s\n" "$html" | sed -n '1,160p'
    echo ""
    return 1
  fi

  echo "✅ ${label} renders the brand mark"
  echo ""
  return 0
}

pages_ok=0
custom_ok=0
overall_fail=0

if check_brand "$PAGES_LATEST" "Pages production"; then
  pages_ok=1
else
  overall_fail=1
fi

if check_brand "$PROD" "Custom domain"; then
  custom_ok=1
else
  overall_fail=1
fi

if [[ $pages_ok -eq 1 && $custom_ok -eq 0 ]]; then
  echo "⚠️ Custom domain does not show the brand mark, but the production Pages build does."
  echo "   Flush CDN cache or verify HTML for https://shipyard.tsaielectro.com/en/."
fi

if [[ $overall_fail -eq 0 ]]; then
  echo "✅ Brand mark verified on both URLs."
fi

exit $overall_fail
