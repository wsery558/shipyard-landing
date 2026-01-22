#!/usr/bin/env bash
set -euo pipefail
cd /home/ken/code/shipyard-landing

TS="$(date +%Y%m%d_%H%M%S)"
for f in en/index.html zh-Hant/index.html; do
  test -f "$f" || { echo "[FAIL] missing $f"; exit 1; }
  cp -v "$f" "$f.bak.$TS"
done

python3 - <<'PY'
from pathlib import Path
import re

REPO = "https://github.com/wsery558/shipyard-community"

def replace_section(text: str, section_id: str, new_block: str) -> str:
    pat = re.compile(rf'<section[^>]*\bid="{re.escape(section_id)}"[^>]*>.*?</section>', re.S)
    m = pat.search(text)
    if not m:
        raise SystemExit(f"[FAIL] section not found: {section_id}")
    return text[:m.start()] + new_block + text[m.end():]

def must_replace(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f"[FAIL] pattern not found for {label}")
    return text.replace(old, new)

def patch_en(fp: Path):
    s = fp.read_text(encoding="utf-8")

    # Hero headline + lead (remove "Not a chat UI")
    s = must_replace(
        s,
        "<h1>Shipyard = Delivery Governance for AI development</h1>",
        "<h1>Shipyard — Delivery Governance for AI development</h1>",
        "en h1",
    )
    s = must_replace(
        s,
        '<p class="lead">Not a chat UI. Make AI changes shippable: verifiable, replayable, auditable.</p>',
        '<p class="lead"><b>Spec</b> is the contract → <b>Verify</b> is the acceptance gate → <b>Evidence</b> is the deliverable.</p>',
        "en lead",
    )

    # Compare intro line
    s = must_replace(
        s,
        "<p class=\"muted\">Community builds trust. Pro sells \"delivery safety\".</p>",
        "<p class=\"muted\">Community helps you run. Pro helps you prove.</p>",
        "en compare intro",
    )

    # Personas header
    s = must_replace(
        s,
        "<h2>Who pays first?</h2>",
        "<h2>Who this is for</h2>",
        "en personas h2",
    )

    # Community proof section
    new_proof = """<section id="community-proof" class="section">
  <h2>What you can verify today</h2>
  <p class="muted">If it can’t be verified, it doesn’t belong on the page.</p>

  <ul class="list">
    <li><b>Delivery Gate passes</b> — typecheck, lint, unit, smoke, build, <code>rc:check</code></li>
    <li><b>Exportable audit trail</b> — redaction + retention/rotation + NDJSON/JSON export + UI search/export</li>
    <li><b>Spec Vault is reproducible</b> — preview → apply → export + deterministic backup (smoke E2E)</li>
    <li><b>Paid release is protected</b> — multi-layer guards to prevent accidental public release</li>
  </ul>

  <div class="callout">
    <strong>Spec-driven delivery</strong>
    <span class="muted">Spec is the contract → Verify is the acceptance gate → Evidence is the deliverable.</span>
  </div>
</section>"""
    s = replace_section(s, "community-proof", new_proof)

    # Placeholder repo URL
    s = s.replace("YOUR_GITHUB_REPO_URL", REPO)

    fp.write_text(s, encoding="utf-8")
    print(f"[OK] patched {fp}")

def patch_zh(fp: Path):
    s = fp.read_text(encoding="utf-8")

    # Hero headline + lead (make zh localized)
    s = must_replace(
        s,
        "<h1>Shipyard = Delivery Governance for AI development</h1>",
        "<h1>Shipyard：把 AI 改動做成「能驗收、能回放、能稽核」的交付</h1>",
        "zh h1",
    )
    s = must_replace(
        s,
        "<p class=\"lead\">不是聊天 UI。把 AI 變更做成可交付：可驗收、可回放、可稽核。</p>",
        "<p class=\"lead\"><b>規格是契約</b> → <b>驗收是入口</b> → <b>證據包才是交付物</b></p>",
        "zh lead",
    )

    # Compare intro line
    s = must_replace(
        s,
        "<p class=\"muted\">Community 建立信任；Pro 販售「交付安全」。</p>",
        "<p class=\"muted\">Community 先讓你跑起來；Pro 讓你交付時拿得出證據。</p>",
        "zh compare intro",
    )

    # Personas header
    s = must_replace(
        s,
        "<h2>最快付費的三類人</h2>",
        "<h2>適合誰</h2>",
        "zh personas h2",
    )

    # Community proof section
    new_proof = """<section id="community-proof" class="section">
  <h2>目前就能驗收的東西</h2>
  <p class="muted">沒辦法驗證的，我們不寫在頁面上。</p>

  <ul class="list">
    <li><b>交付閘門全過</b>：typecheck／lint／unit／smoke／build／<code>rc:check</code></li>
    <li><b>稽核紀錄可導出</b>：遮罩（redaction）＋留存/輪替（retention/rotation）＋匯出（NDJSON/JSON）＋介面查詢/下載</li>
    <li><b>Spec Vault 可重現</b>：preview → apply → export＋可重現備份（deterministic backup），且有 smoke E2E</li>
    <li><b>避免付費版意外公開</b>：多層保護避免誤發</li>
  </ul>

  <div class="callout">
    <strong>用 SDD 的話講：</strong>
    <span class="muted">規格是契約 → 驗收是入口 → 證據包才是交付。</span>
  </div>
</section>"""
    s = replace_section(s, "community-proof", new_proof)

    # Placeholder repo URL
    s = s.replace("YOUR_GITHUB_REPO_URL", REPO)

    fp.write_text(s, encoding="utf-8")
    print(f"[OK] patched {fp}")

patch_en(Path("en/index.html"))
patch_zh(Path("zh-Hant/index.html"))
PY

echo
echo "== git diff (preview) =="
git diff -- en/index.html zh-Hant/index.html | sed -n '1,220p'
echo
echo "[DONE] If diff looks good: git add -A && git commit -m 'docs(landing): tighten SDD message + B2B copy v2' && git push"
