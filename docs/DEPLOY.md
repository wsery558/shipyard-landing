# Deploy (Cloudflare Pages)

This site is deployed via **Cloudflare Pages Direct Upload**.

- Custom domain: `shipyard.tsaielectro.com`
- Pages project: `shipyard-tsaielectro`
- Production branch: `shipyard-tsaielectro`

## Deploy (production)
```bash
cd ~/code/shipyard-landing
bash scripts/build_dist_clean.sh
npx -y wrangler pages deploy dist --project-name "shipyard-tsaielectro" --branch "shipyard-tsaielectro"

