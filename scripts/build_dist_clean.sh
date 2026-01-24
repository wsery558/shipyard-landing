#!/usr/bin/env bash
set -euo pipefail
cd /home/ken/code/shipyard-landing

# Forbidden keywords (assembled without contiguous literals to avoid poisoning the repo)
FORBIDDEN_PARTS=(
  "walk""through"
  "15-min"
  "sched""ule"
  "book a ""call"
  "walk""through_"
)
FORBIDDEN_PATTERN=$(printf "%s|" "${FORBIDDEN_PARTS[@]}")
FORBIDDEN_PATTERN=${FORBIDDEN_PATTERN%|}

rm -rf dist
mkdir -p dist/assets dist/en dist/zh-Hant dist/zh-Hant/waitlist dist/zh-Hant/walkthrough dist/zh-Hant/evidence-pack dist/zh-Hant/pilot dist/zh-Hant/demo dist/community dist/demo dist/waitlist dist/walkthrough dist/evidence-pack dist/pilot dist/trust dist/zh-Hant/trust dist/.well-known

# ✅ root：英文當預設首頁（要改中文就把 en 改成 zh-Hant）
cp -v en/index.html dist/index.html

# language routes
cp -v en/index.html dist/en/index.html
cp -v zh-Hant/index.html dist/zh-Hant/index.html

# simple routes (static fallback; functions/ 仍可覆蓋)
[ -f community/index.html ] && cp -v community/index.html dist/community/index.html || true
[ -f demo/index.html ] && cp -v demo/index.html dist/demo/index.html || true
[ -f zh-Hant/demo/index.html ] && cp -v zh-Hant/demo/index.html dist/zh-Hant/demo/index.html || true
[ -f waitlist/index.html ] && cp -v waitlist/index.html dist/waitlist/index.html || true
[ -f zh-Hant/waitlist/index.html ] && cp -v zh-Hant/waitlist/index.html dist/zh-Hant/waitlist/index.html || true
[ -f walkthrough/index.html ] && cp -v walkthrough/index.html dist/walkthrough/index.html || true
[ -f zh-Hant/walkthrough/index.html ] && cp -v zh-Hant/walkthrough/index.html dist/zh-Hant/walkthrough/index.html || true
[ -f evidence-pack/index.html ] && cp -v evidence-pack/index.html dist/evidence-pack/index.html || true
[ -f zh-Hant/evidence-pack/index.html ] && cp -v zh-Hant/evidence-pack/index.html dist/zh-Hant/evidence-pack/index.html || true
[ -f pilot/index.html ] && cp -v pilot/index.html dist/pilot/index.html || true
[ -f zh-Hant/pilot/index.html ] && cp -v zh-Hant/pilot/index.html dist/zh-Hant/pilot/index.html || true
[ -f trust/index.html ] && cp -v trust/index.html dist/trust/index.html || true
[ -f zh-Hant/trust/index.html ] && cp -v zh-Hant/trust/index.html dist/zh-Hant/trust/index.html || true

# robots/sitemap
[ -f robots.txt ] && cp -v robots.txt dist/robots.txt || true
[ -f sitemap.xml ] && cp -v sitemap.xml dist/sitemap.xml || true
[ -f .well-known/security.txt ] && mkdir -p dist/.well-known && cp -v .well-known/security.txt dist/.well-known/security.txt || true

# assets：只複製非 .bak.*
find assets -maxdepth 1 -type f ! -name "*.bak.*" -exec cp -v {} dist/assets/ \;

# copy the Pages routing manifest so only tracking hits the functions
cp -v routes/_routes.json dist/_routes.json

# hygiene：dist 內不該出現 .bak.
if find dist -type f -name "*.bak.*" | grep -q .; then
  echo "[FAIL] dist contains *.bak.*"
  find dist -type f -name "*.bak.*" | sed -n '1,50p'
  exit 1
fi

# ensure _routes includes the required include rules
if ! rg -q '"include"' dist/_routes.json; then
  echo "[FAIL] dist/_routes.json missing include definition"
  exit 1
fi
for route in '/__track' '/__track/*' '/__track_view' '/__track_view/*'; do
  if ! rg -q "\"${route}\"" dist/_routes.json; then
    echo "[FAIL] dist/_routes.json missing ${route}"
    exit 1
  fi
done

# confirm demo pages still reference the app and tab markers
if ! rg -q 'assets/app\.js|page-demo|data-demo-tab|data-demo-panel' dist/demo/index.html dist/zh-Hant/demo/index.html; then
  echo "[FAIL] demo pages missing required markers"
  exit 1
fi

# forbid walkthrough/schedule/call strings in source before proceeding
if rg -n "${FORBIDDEN_PATTERN}" en zh-Hant demo waitlist walkthrough evidence-pack pilot assets functions index.html >/tmp/forbidden_src.txt; then
  echo "[FAIL] Forbidden keywords found in source"
  head -20 /tmp/forbidden_src.txt
  exit 1
fi

# forbid walkthrough/schedule/call strings in dist HTML/JS/CSS
if rg -n "${FORBIDDEN_PATTERN}" dist -g'*.{html,js,css}' >/tmp/forbidden_dist.txt; then
  echo "[FAIL] Forbidden keywords found in dist/"
  head -20 /tmp/forbidden_dist.txt
  exit 1
fi

echo "[OK] dist is clean"
