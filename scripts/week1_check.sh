#!/usr/bin/env bash
set -euo pipefail

ROOT="/home/ken/code/shipyard-landing"
cd "$ROOT"

FILES=("index.html" "en/index.html" "zh-Hant/index.html" "assets/app.js" "assets/style.css")

hr () { echo; echo "================================================================"; }
sec () { echo; echo "## $1"; }

echo "== shipyard-landing Week1 check =="
date
echo "PWD: $(pwd)"

hr
sec "0) Files exist?"
for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then
    echo "[OK] $f"
  else
    echo "[MISS] $f"
  fi
done

hr
sec "1) Hero CTA buttons (btn primary/secondary) — show top part only"
for fp in en/index.html zh-Hant/index.html; do
  echo
  echo "-- $fp (lines 1-120) --"
  nl -ba "$fp" | sed -n '1,120p' | grep -nE 'btn (primary|secondary)|<h1|Shipyard|Waitlist|候補名單|Quickstart|demo' || true
  echo "-- counts in lines 1-120 --"
  head -n 120 "$fp" | grep -oE 'btn primary' | wc -l | awk '{print "btn primary:",$1}'
  head -n 120 "$fp" | grep -oE 'btn secondary' | wc -l | awk '{print "btn secondary:",$1}'
done

hr
sec "2) Quickstart links (should NOT be Google Form, and ZH should NOT be placeholder)"
for fp in en/index.html zh-Hant/index.html; do
  echo
  echo "-- $fp quickstart occurrences --"
  grep -nEi 'quickstart' "$fp" || true
  echo "-- hrefs that mention quickstart/demo/form/github --"
  grep -nE 'href="[^"]+"' "$fp" | grep -Ei 'quickstart|demo|forms|github|shipyard-community' || true
  echo "-- placeholder check --"
  grep -nE 'YOUR_GITHUB_QUICKSTART_URL|YOUR_' "$fp" || true
done

hr
sec "3) Waitlist iframe + persona prefill (should be docs.google.com ... embedded=true)"
for fp in en/index.html zh-Hant/index.html; do
  echo
  echo "-- $fp waitlist block --"
  grep -nE 'id="waitlist"|id="waitlistFrame"|<iframe' "$fp" || true
  echo "-- iframe src --"
  grep -nE 'id="waitlistFrame".*src="' "$fp" || true
done
echo
echo "-- app.js prefill handler check --"
grep -nE 'waitlistFrame|data-form-src|entry\.1057175306' assets/app.js || true

hr
sec "4) 'Book a call' removed? (should be none)"
grep -RInE 'book a call|calendly|schedule|meeting' index.html en zh-Hant assets 2>/dev/null || echo "[OK] no call/scheduling strings found"

hr
sec "5) Internal/AI-y wording scan (you said needs cleanup)"
PAT='Hard proof|硬證據|not promises|不是承諾|Who pays first|最快付費|不是聊天|chat UI|builds trust|建立信任|Pro sells|販售|上船前|上傳前|治理層|Make AI changes shippable'
grep -RInE "$PAT" en/index.html zh-Hant/index.html 2>/dev/null || echo "[OK] none of the flagged phrases found"

hr
sec "6) Demo asset presence + references"
echo "-- file exists? --"
ls -la assets/demo.gif 2>/dev/null || echo "[MISS] assets/demo.gif not found"
echo "-- HTML references --"
grep -RIn "demo.gif" index.html en/index.html zh-Hant/index.html 2>/dev/null || echo "[WARN] no demo.gif referenced in HTML"

hr
sec "7) Analytics snippet present? (Cloudflare beacon / GA)"
for fp in index.html en/index.html zh-Hant/index.html; do
  echo
  echo "-- $fp analytics markers --"
  grep -nE 'static\.cloudflareinsights\.com/beacon\.min\.js|googletagmanager|gtag\(' "$fp" || echo "[NONE] no analytics snippet found"
done

hr
sec "8) dist hygiene (backup files should NOT be deployed ideally)"
if [ -d dist ]; then
  echo "-- dist size --"
  du -sh dist || true
  echo "-- backup files in dist --"
  find dist -type f -name '*.bak.*' | head -n 50 || true
  CNT="$(find dist -type f -name '*.bak.*' | wc -l | tr -d ' ')"
  echo "backup files count in dist: $CNT"
else
  echo "[INFO] dist/ not found (run build/deploy step first if needed)"
fi

hr
sec "9) Public URLs sanity (pages.dev / custom domain) — headers only"
PAGES_DEV="https://shipyard-tsaielectro.pages.dev/"
MAIN_ALIAS="https://main.shipyard-tsaielectro.pages.dev/"
CUSTOM="https://shipyard.tsaielectro.com/"

echo "-- pages.dev --"
curl -I "$PAGES_DEV" | head -n 10 || true
echo
echo "-- main alias --"
curl -I "$MAIN_ALIAS" | head -n 10 || true
echo
echo "-- custom domain --"
curl -I "$CUSTOM" | head -n 10 || true

hr
sec "10) Community repo reachable? (200=public, 404=missing/private)"
REPO_URL="${REPO_URL:-https://github.com/wsery558/shipyard-community}"
echo "Repo: $REPO_URL"
curl -I "$REPO_URL" | head -n 12 || true

hr
sec "DONE — paste the output back to me"
