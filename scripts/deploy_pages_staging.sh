#!/usr/bin/env bash
# Shipyard Landing - Staging Deployment Script
# Target: https://staging.shipyard-landing.pages.dev/
# Verifies: git repo, build, then deploys to staging branch

set -euo pipefail

REPO="${HOME}/code/shipyard-landing"
PROJECT_NAME="shipyard-landing"
BRANCH="staging"
BASE_URL="https://staging.shipyard-landing.pages.dev"
REQUIRED_ANCHORS=("community-proof" "compare" "compliance" "agency" "personas")
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

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 Shipyard Landing - STAGING DEPLOYMENT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

function print_environment_banner() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Project: $PROJECT_NAME"
  echo "Branch: $BRANCH"
  echo "Base URL: $BASE_URL"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

function guard_function_backups() {
  local forbidden
  forbidden=$(find functions -maxdepth 2 -type f \( -name '*demo*' -o -name '*.bak' -o -name '*.bak.*' \) -print)
  if [ -n "$forbidden" ]; then
    echo "❌ Forbidden files in functions/ directory:"
    printf "%s\n" "$forbidden"
    exit 1
  fi
}

function assert_routes_manifest() {
  local routes="dist/_routes.json"
  if [ ! -f "$routes" ]; then
    echo "❌ dist/_routes.json missing"
    exit 1
  fi
  for route in '/__track' '/__track/*' '/__track_view' '/__track_view/*'; do
    if ! rg -q "\"${route}\"" "$routes"; then
      echo "❌ dist/_routes.json missing ${route}"
      exit 1
    fi
  done
}

print_environment_banner
guard_function_backups

# Verify repo
echo "✓ Verifying git repository..."
cd "$REPO" || { echo "❌ Failed to cd to $REPO"; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null || { echo "❌ Not a git repo"; exit 1; }

BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "DETACHED")
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
echo "  Branch: $BRANCH_NAME | Commit: $COMMIT"

# Build
echo ""
echo "✓ Building dist..."
bash scripts/build_dist_clean.sh > /tmp/build.log 2>&1 || { 
  echo "❌ Build failed"; tail -10 /tmp/build.log; exit 1; 
}

assert_routes_manifest

# Additional forbidden keyword gate on source (belt-and-suspenders)
if rg -n "${FORBIDDEN_PATTERN}" en zh-Hant demo waitlist walkthrough evidence-pack pilot assets functions index.html >/tmp/forbidden_src.txt; then
  echo "❌ Forbidden keywords found in source"; head -20 /tmp/forbidden_src.txt; exit 1;
fi

# Additional forbidden keyword gate on dist
if rg -n "${FORBIDDEN_PATTERN}" dist -g'*.{html,js,css}' >/tmp/forbidden_dist.txt; then
  echo "❌ Forbidden keywords found in dist"; head -20 /tmp/forbidden_dist.txt; exit 1;
fi

test -d dist || { echo "❌ dist/ not created"; exit 1; }
FILE_COUNT=$(find dist -type f | wc -l)
test "$FILE_COUNT" -gt 5 || { echo "❌ dist/ has only $FILE_COUNT files"; exit 1; }
echo "  dist/ contains $FILE_COUNT files ✓"

# Verify section anchors
echo ""
echo "✓ Verifying section anchors..."
for anchor in "${REQUIRED_ANCHORS[@]}"; do
  if ! grep -q "id=\"$anchor\"" dist/en/index.html; then
    echo "❌ Missing #$anchor in en/index.html"; exit 1;
  fi
  if ! grep -q "id=\"$anchor\"" dist/zh-Hant/index.html; then
    echo "❌ Missing #$anchor in zh-Hant/index.html"; exit 1;
  fi
  echo "  #$anchor ✓"
done

function run_post_deploy_smoke() {
  local base_url="$1"
  echo ""
  echo "⚗️ Running post-deploy smoke checks against $base_url"
  local demo_url="${base_url}/demo/?ts=$(date +%s)"
  local demo_html
  demo_html=$(curl -fsSL -H 'Cache-Control: no-cache' "$demo_url") || { echo "❌ Failed to fetch $demo_url"; return 1; }
  if ! printf "%s" "$demo_html" | rg -q "assets/app\\.js"; then
    echo "❌ /demo/ missing assets/app.js reference"
    printf "%s\n" "$demo_html" | head -n 120
    return 1
  fi

  if ! printf "%s" "$demo_html" | rg -q "page-demo|data-demo-tab|data-demo-panel"; then
    echo "❌ /demo/ missing new demo DOM markers"
    printf "%s\n" "$demo_html" | head -n 120
    return 1
  fi

  local asset_js
  local asset_url="${base_url}/assets/app.js?ts=$(date +%s)"
  asset_js=$(curl -fsSL -H 'Cache-Control: no-cache' "$asset_url") || { echo "❌ Failed to fetch $asset_url"; return 1; }
  local required_strings=( "shipyard_demo_tab" "demo_page_view" "demo_tab_click" "demo_evidence_pack_click" )
  for str in "${required_strings[@]}"; do
    if ! printf "%s" "$asset_js" | grep -q "$str"; then
      echo "❌ ${asset_url} missing ${str}"
      printf "%s\n" "$asset_js" | head -n 40
      return 1
    fi
  done

  if rg -n "${FORBIDDEN_PATTERN}" dist -g'*.{html,js,css}' >/tmp/forbidden_post.txt; then
    echo "❌ Forbidden keywords detected in dist after deploy"; head -5 /tmp/forbidden_post.txt; return 1;
  fi

  echo "  Post-deploy smoke checks passed ✓"

  return 0
}

# Deploy
echo ""
echo "✓ Deploying to staging ($BRANCH branch)..."
deploy_output=$(pnpm dlx wrangler@latest pages deploy dist \
  --project-name "$PROJECT_NAME" \
  --branch "$BRANCH" \
  --commit-dirty=true 2>&1) || { echo "❌ Deployment failed"; printf '%s\n' "$deploy_output"; exit 1; }
printf '%s\n' "$deploy_output"
DEPLOY_URL=$(printf '%s\n' "$deploy_output" | rg -m 1 -o 'https://[^[:space:]]+\\.pages\\.dev')
if [ -z "$DEPLOY_URL" ]; then
  echo "❌ Unable to parse pages.dev URL from deployment output"
  printf '%s\n' "$deploy_output"
  exit 1
fi
echo "  DEPLOY_URL=$DEPLOY_URL"

if ! run_post_deploy_smoke "$DEPLOY_URL"; then
  echo "❌ Smoke checks failed against $DEPLOY_URL"
  exit 1
fi
if ! run_post_deploy_smoke "$BASE_URL"; then
  echo "❌ Smoke checks failed against $BASE_URL"
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ STAGING DEPLOYMENT COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔗 URL: ${BASE_URL}"
echo ""
