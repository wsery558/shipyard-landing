#!/usr/bin/env bash
set -u -o pipefail

cd "$(dirname -- "${BASH_SOURCE[0]}")/.."

PROJECT="shipyard-landing"
BRANCH="staging"
ALIAS="https://staging.shipyard-landing.pages.dev"

LIST="$(
  pnpm dlx wrangler@latest pages deployment list --project-name "$PROJECT" --environment preview 2>/dev/null || true
)"

PAGES_LATEST="$(
  printf "%s" "$LIST" \
    | rg -m 1 "\\b${BRANCH}\\b" \
    | rg -m 1 -o "https://[0-9a-f]{8}\\.${PROJECT}\\.pages\\.dev" \
    || true
)"

if [[ -z "${PAGES_LATEST:-}" ]]; then
  echo "❌ Could not find latest preview deployment for branch '$BRANCH' in project '$PROJECT'."
  echo "---- deployment list (preview) ----"
  printf "%s\n" "$LIST" | sed -n '1,120p'
  exit 1
fi

echo "🔎 Latest staging Pages URL: $PAGES_LATEST"
echo "🔎 Staging alias URL:       $ALIAS"
echo ""

TS="$(date +%s)"

check_demo() {
  local base="$1"
  echo "== CHECK $base/demo/ =="

  local demo_html
  demo_html="$(curl -fsS -H 'Cache-Control: no-cache' "$base/demo/?ts=$TS")" || {
    echo "❌ Failed to fetch $base/demo/"
    return 1
  }

  printf "%s" "$demo_html" | rg -n "assets/app\.js" >/dev/null || {
    echo "❌ missing assets/app.js script tag"
    printf "%s\n" "$demo_html" | sed -n '1,160p'
    return 1
  }

  printf "%s" "$demo_html" | rg -n "page-demo|data-demo-tab|data-demo-panel" >/dev/null || {
    echo "❌ missing new demo DOM markers"
    printf "%s\n" "$demo_html" | sed -n '1,220p'
    return 1
  }

  curl -fsS -H 'Cache-Control: no-cache' "$base/assets/app.js?ts=$TS" \
    | rg -n "shipyard_demo_tab|demo_page_view|demo_tab_click|demo_evidence_pack_click" >/dev/null || {
      echo "❌ app.js missing demo initializer strings"
      return 1
    }

  echo "OK"
  echo ""
  return 0
}

ok_hash=0
ok_alias=0

check_demo "$PAGES_LATEST" && ok_hash=1 || true
check_demo "$ALIAS" && ok_alias=1 || true

if [[ $ok_hash -eq 1 && $ok_alias -eq 1 ]]; then
  echo "✅ staging demo verified on latest Pages hash + alias"
  exit 0
fi

echo "❌ staging demo check failed."
if [[ $ok_hash -eq 1 && $ok_alias -eq 0 ]]; then
  echo "ℹ️  Hint: Pages hash URL is OK but alias failed → branch alias/domain mapping or caching mismatch."
fi
exit 1
