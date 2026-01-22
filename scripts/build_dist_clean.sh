#!/usr/bin/env bash
set -euo pipefail
cd /home/ken/code/shipyard-landing

rm -rf dist
mkdir -p dist/assets dist/en dist/zh-Hant dist/community dist/demo dist/waitlist

# ✅ root：英文當預設首頁（要改中文就把 en 改成 zh-Hant）
cp -v en/index.html dist/index.html

# language routes
cp -v en/index.html dist/en/index.html
cp -v zh-Hant/index.html dist/zh-Hant/index.html

# simple routes (static fallback; functions/ 仍可覆蓋)
[ -f community/index.html ] && cp -v community/index.html dist/community/index.html || true
[ -f demo/index.html ] && cp -v demo/index.html dist/demo/index.html || true
[ -f waitlist/index.html ] && cp -v waitlist/index.html dist/waitlist/index.html || true

# robots/sitemap
[ -f robots.txt ] && cp -v robots.txt dist/robots.txt || true
[ -f sitemap.xml ] && cp -v sitemap.xml dist/sitemap.xml || true

# assets：只複製非 .bak.*
find assets -maxdepth 1 -type f ! -name "*.bak.*" -exec cp -v {} dist/assets/ \;

# hygiene：dist 內不該出現 .bak.
if find dist -type f -name "*.bak.*" | grep -q .; then
  echo "[FAIL] dist contains *.bak.*"
  find dist -type f -name "*.bak.*" | sed -n '1,50p'
  exit 1
fi

echo "[OK] dist is clean"
