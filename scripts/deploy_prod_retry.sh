#!/usr/bin/env bash
set -euo pipefail
set +H

cd "$(dirname "$0")/.."

PROJECT="shipyard-tsaielectro"
PROD_BRANCH="shipyard-tsaielectro"
BASE_CUSTOM="https://shipyard.tsaielectro.com"

echo "== build dist =="
bash scripts/build_dist_clean.sh >/dev/null

echo "== deploy (retry on 502) =="
max=5
for i in $(seq 1 "$max"); do
  echo "-- attempt $i/$max --"

  set +e
  out="$(npx -y wrangler pages deploy dist --project-name "$PROJECT" --branch "$PROD_BRANCH" 2>&1)"
  code=$?
  set -e

  echo "$out" | tail -n 30

  if [ $code -eq 0 ]; then
    echo "OK: deployed"
    break
  fi

  if echo "$out" | rg -q "502 Bad Gateway|malformed response from the API"; then
    sleep_sec=$((i*6))
    echo "WARN: Cloudflare API 502, retrying in ${sleep_sec}s..."
    sleep "$sleep_sec"
    continue
  fi

  echo "FAIL: deploy failed (non-502)."
  exit $code
done

echo "== remote sanity: waitlist iframe count should be 1 =="
cnt="$(curl -fsSL -H 'Cache-Control: no-cache' "$BASE_CUSTOM/zh-Hant/waitlist/?v=$(date +%s)" \
  | rg -o "<iframe" | wc -l | tr -d ' ')"
echo "iframe_count=$cnt"
test "$cnt" = "1" && echo "OK" || { echo "FAIL"; exit 1; }
