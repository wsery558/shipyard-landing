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

def replace_first(pattern: str, repl: str, s: str, label: str, flags=re.I|re.S):
    out, n = re.subn(pattern, repl, s, count=1, flags=flags)
    if n == 0:
        raise SystemExit(f"[FAIL] cannot patch: {label}")
    return out

def replace_section_by_id(s: str, section_id: str, new_block: str):
    pat = re.compile(rf'<section\b[^>]*\bid="{re.escape(section_id)}"[^>]*>.*?</section>', re.I|re.S)
    m = pat.search(s)
    if not m:
        raise SystemExit(f"[FAIL] section not found: {section_id}")
    return s[:m.start()] + new_block + s[m.end():]

def patch_en():
    p = Path("en/index.html")
    s = p.read_text(encoding="utf-8")

    # Hero H1 / lead：不管現在寫什麼，改成 SDD 的採購語言（避免 "Not a chat UI"）
    s = replace_first(r'<h1\b[^>]*>.*?</h1>', r'<h1>Shipyard — Spec-driven delivery for AI development</h1>', s, "en h1")
    s = replace_first(r'<p\b[^>]*class="lead"[^>]*>.*?</p>',
                      r'<p class="lead"><b>Spec</b> is the contract → <b>Verify</b> is the acceptance gate → <b>Evidence</b> is the deliverable.</p>',
                      s, "en lead")

    # Compare intro：變成口語、B2B 能懂的版本
    s = replace_section_by_id(s, "compare", re.sub(
        r'<p\b[^>]*>.*?</p>',
        '<p class="muted">Community helps you run. Pro helps you prove.</p>',
        re.search(r'<section\b[^>]*\bid="compare"[^>]*>.*?</section>', s, re.I|re.S).group(0),
        count=1, flags=re.I|re.S
    ))

    # Personas：拿掉「誰先付費」語氣，改成「適合誰」
    def patch_personas(block: str):
        block = re.sub(r'<h2\b[^>]*>.*?</h2>', '<h2>Who this is for</h2>', block, count=1, flags=re.I|re.S)
        return block
    personas_block = re.search(r'<section\b[^>]*\bid="personas"[^>]*>.*?</section>', s, re.I|re.S)
    if personas_block:
        patched = patch_personas(personas_block.group(0))
        s = s[:personas_block.start()] + patched + s[personas_block.end():]
    else:
        print("[WARN] en: personas section not found (skip)")

    # community-proof：整段換成「可驗收」版本（避免硬梗/AI 味）
    en_proof = """<section id="community-proof" class="section">
  <h2>What you can verify today</h2>
  <p class="muted">If it can’t be verified, it doesn’t belong on the page.</p>

  <ul class="list">
    <li><b>Release gate passes</b> — typecheck / lint / unit / smoke / build / <code>rc:check</code></li>
    <li><b>Exportable audit trail</b> — redaction + retention/rotation + NDJSON/JSON export + UI search/export</li>
    <li><b>Spec Vault is reproducible</b> — preview → apply → export + deterministic backup (smoke E2E)</li>
    <li><b>Paid release is protected</b> — multi-layer guards to prevent accidental public release</li>
  </ul>

  <div class="callout">
    <strong>Spec-driven delivery</strong>
    <span class="muted">Spec is the contract → Verify is the acceptance gate → Evidence is the deliverable.</span>
  </div>
</section>"""
    s = replace_section_by_id(s, "community-proof", en_proof)

    # 補齊 placeholder repo
    s = s.replace("YOUR_GITHUB_REPO_URL", REPO)

    p.write_text(s, encoding="utf-8")
    print("[OK] patched en/index.html")

def patch_zh():
    p = Path("zh-Hant/index.html")
    s = p.read_text(encoding="utf-8")

    # Hero H1 / lead：更在地、更口語（但保留 SDD 骨架）
    s = replace_first(r'<h1\b[^>]*>.*?</h1>', r'<h1>Shipyard：規格是契約，驗收是入口，證據包才算交付</h1>', s, "zh h1")
    s = replace_first(r'<p\b[^>]*class="lead"[^>]*>.*?</p>',
                      r'<p class="lead"><b>規格是契約</b> → <b>驗收是入口</b> → <b>證據包才是交付物</b></p>',
                      s, "zh lead")

    # Compare intro：改成不「販售」，而是「差在哪」
    s = replace_section_by_id(s, "compare", re.sub(
        r'<p\b[^>]*>.*?</p>',
        ' <p class="muted">Community 先讓你跑起來；Pro 讓你交付時拿得出證據。</p>',
        re.search(r'<section\b[^>]*\bid="compare"[^>]*>.*?</section>', s, re.I|re.S).group(0),
        count=1, flags=re.I|re.S
    ))

    # Personas：拿掉「最快付費」語氣
    personas_block = re.search(r'<section\b[^>]*\bid="personas"[^>]*>.*?</section>', s, re.I|re.S)
    if personas_block:
        block = personas_block.group(0)
        block = re.sub(r'<h2\b[^>]*>.*?</h2>', '<h2>適合誰</h2>', block, count=1, flags=re.I|re.S)
        s = s[:personas_block.start()] + block + s[personas_block.end():]
    else:
        print("[WARN] zh: personas section not found (skip)")

    # community-proof：整段改更口語、但仍可驗收
    zh_proof = """<section id="community-proof" class="section">
  <h2>目前就能驗收的內容</h2>
  <p class="muted">沒辦法被驗證的，我們不寫在頁面上。</p>

  <ul class="list">
    <li><b>交付閘門全過</b>：typecheck／lint／unit／smoke／build／<code>rc:check</code></li>
    <li><b>稽核紀錄可導出</b>：遮罩（redaction）＋留存/輪替（retention/rotation）＋匯出（NDJSON/JSON）＋介面查詢/下載</li>
    <li><b>Spec Vault 可重現</b>：preview → apply → export＋可重現備份（deterministic backup），且有 smoke E2E</li>
    <li><b>避免付費版意外公開</b>：多層保護，降低誤發風險</li>
  </ul>

  <div class="callout">
    <strong>用 SDD 的話講：</strong>
    <span class="muted">規格是契約 → 驗收是入口 → 證據包才算交付。</span>
  </div>
</section>"""
    s = replace_section_by_id(s, "community-proof", zh_proof)

    # 補齊 placeholder repo
    s = s.replace("YOUR_GITHUB_REPO_URL", REPO)

    p.write_text(s, encoding="utf-8")
    print("[OK] patched zh-Hant/index.html")

patch_en()
patch_zh()
PY

echo
echo "== verify (hero h1 + lead) =="
grep -nE '<h1>|<p class="lead">' en/index.html | head -n 10
grep -nE '<h1>|<p class="lead">' zh-Hant/index.html | head -n 10

echo
echo "== verify (compare intro) =="
grep -n 'Community helps you run' -n en/index.html || true
grep -n 'Community 先讓你跑起來' -n zh-Hant/index.html || true

echo
echo "== verify (placeholder) =="
grep -RIn 'YOUR_GITHUB_REPO_URL' en/index.html zh-Hant/index.html || echo "[OK] no placeholders"

echo
echo "== git diff preview (first 220 lines) =="
git diff -- en/index.html zh-Hant/index.html | sed -n '1,220p'
