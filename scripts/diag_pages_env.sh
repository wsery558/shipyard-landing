#!/usr/bin/env bash
set -euo pipefail

echo "🧭 Listing Pages projects"
pnpm dlx wrangler@latest pages project list

echo ""
echo "⚙️ Deployments for shipyard-tsaielectro (prod)"
pnpm dlx wrangler@latest pages deployment list \
  --project-name shipyard-tsaielectro \
  --limit 10

echo ""
echo "⚙️ Deployments for shipyard-landing (staging/preview)"
pnpm dlx wrangler@latest pages deployment list \
  --project-name shipyard-landing \
  --limit 10

echo ""
echo "請把最新 deployment 的 URL 跟你實際打到的 domain 對起來，確認 domain 綁的是 production 還是某個 preview branch。"
