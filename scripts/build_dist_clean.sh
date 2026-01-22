#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

rm -rf dist
mkdir -p dist/assets dist/en dist/zh-Hant

# only copy the real entrypoints
[ -f index.html ] && cp -v index.html dist/ || true
cp -v en/index.html dist/en/index.html
cp -v zh-Hant/index.html dist/zh-Hant/index.html

# copy assets but exclude backups
if [ -d assets ]; then
  find assets -maxdepth 1 -type f ! -name '*.bak.*' -print -exec cp -v {} dist/assets/ \;
fi

# sanity: ensure no bak files in dist
if find dist -name '*.bak.*' | grep -q .; then
  echo "[FAIL] dist contains *.bak.* files"
  find dist -name '*.bak.*' -print
  exit 1
fi

echo "[OK] dist is clean"
