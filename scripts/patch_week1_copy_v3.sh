#!/usr/bin/env bash
set -euo pipefail
cd /home/ken/code/shipyard-landing

TS="$(date +%Y%m%d_%H%M%S)"
for f in en/index.html zh-Hant/index.html; do
  test -f "$f" || { echo "[FAIL] missing $f"; exit 1; }
  cp -v "$f" "$f.bak.$TS.copyv3"
done

python3 - <<'PY'
from pathlib import Path
import re

def replace_section(text: str, section_id: str, new_block: str) -> str:
    pat = re.compile(rf'<section\b[^>]*\bid="{re.escape(section_id)}"[^>]*>.*?</section>', re.S | re.I)
    m = pat.search(text)
    if not m:
        raise SystemExit(f"[FAIL] section not found: #{section_id}")
    return text[:m.start()] + new_block + text[m.end():]

def replace_first_h1(text: str, new_h1: str) -> str:
    pat = re.compile(r"<h1>.*?</h1>", re.S | re.I)
    m = pat.search(text)
    if not m:
        print("[WARN] no <h1> found; skip")
        return text
    return text[:m.start()] + new_h1 + text[m.end():]

def replace_first_lead(text: str, new_lead: str) -> str:
    # Replace first <p class="lead">...</p>
    pat = re.compile(r'<p\b[^>]*class="lead"[^>]*>.*?</p>', re.S | re.I)
    m = pat.search(text)
    if not m:
        print("[WARN] no <p class=\"lead\"> found; skip")
        return text
    return text[:m.start()] + new_lead + text[m.end():]

EN_H1 = '<h1>Shipyard: delivery governance for AI changes</h1>'
EN_LEAD = '<p class="lead">Spec is the contract → Verification is the gate → Evidence is the deliverable.</p>'

ZH_H1 = '<h1>Shipyard：規格是契約，驗收是入口，證據包才算交付</h1>'
ZH_LEAD = '<p class="lead"><b>規格先講清楚</b> → <b>驗收過得了</b> → <b>證據包交得出去</b></p>'

EN_COMMUNITY_PROOF = r"""
<section id="community-proof" class="section">
  <h2>Proof you can show</h2>
  <p class="muted">If it can’t be demonstrated or exported, we don’t claim it.</p>

  <ul class="list">
    <li><b>Delivery gate: all green</b> — typecheck / lint / unit / smoke / build / <code>rc:check</code></li>
    <li><b>Audit evidence, end to end</b> — redaction + retention/rotation + export (NDJSON/JSON) + UI search/export</li>
    <li><b>Spec Vault is reproducible</b> — preview → apply → export + deterministic backup, with smoke E2E</li>
    <li><b>Commercial release is protected</b> — validators & fences to prevent accidental public release</li>
  </ul>

  <div class="callout">
    <strong>Why Pro?</strong>
    <span class="muted">Because B2B buyers ask for deliverables: evidence outputs, enforceable policy gates, and transparent usage.</span>
  </div>
</section>
""".strip()

ZH_COMMUNITY_PROOF = r"""
<section id="community-proof" class="section">
  <h2>可以拿出來的證據</h2>
  <p class="muted">能展示、能匯出、能留存的，我們才寫在頁面上。</p>

  <ul class="list">
    <li><b>交付閘門全過</b>：型別檢查／lint／單元測試／smoke／build／<code>rc:check</code></li>
    <li><b>稽核證據做成閉環</b>：遮罩 + 留存/輪替 + 匯出（NDJSON/JSON）+ 介面可查可導出</li>
    <li><b>Spec Vault 可重現</b>：預覽 → 套用 → 匯出 + 可重建備份，並有 smoke E2E</li>
    <li><b>商用版發佈有防線</b>：多層檢查與柵欄，避免付費版誤發成公開版本</li>
  </ul>

  <div class="callout">
    <strong>為什麼要 Pro？</strong>
    <span class="muted">因為 B2B 採購看的是交付物：證據輸出、政策閘門、成本明細。</span>
  </div>
</section>
""".strip()

EN_COMPARE = r"""
<section id="compare" class="section">
  <h2>Community vs Pro</h2>
  <p>Community gets you running. Pro helps you deliver with proof.</p>

  <table class="compare">
    <tr><th>What you can verify</th><th>Community</th><th>Pro</th></tr>
    <tr><td>Quickstart + build/start + smoke</td><td>✅</td><td>✅</td></tr>
    <tr><td>Reproducible demo script</td><td>✅</td><td>✅</td></tr>
    <tr><td><strong>Evidence outputs</strong> (audit export + evidence bundle + retention)</td><td>—</td><td>🟡 Gate: v6.0.0</td></tr>
    <tr><td><strong>Policy enforcement</strong> (Policy-as-Code / packs)</td><td>—</td><td>🟡 Gate: v6.0.0</td></tr>
    <tr><td><strong>Transparent usage</strong> (task-level cost ledger, budgets, pause)</td><td>—</td><td>🟡 Gate: v6.0.0</td></tr>
  </table>

  <div class="cards">
    <div class="card">
      <h3>Evidence outputs</h3>
      <p>Export a defensible record: who did what, what changed, what passed, and what it cost.</p>
    </div>
    <div class="card">
      <h3>Policy gates</h3>
      <p>Stop risky actions before release. If it doesn’t comply, it doesn’t run.</p>
    </div>
    <div class="card">
      <h3>Cost transparency</h3>
      <p>Usage you can explain and bill: task-level attribution, budgets, and predictable guardrails.</p>
    </div>
  </div>

  <div class="callout">
    <strong>Procurement language</strong>
    <span class="muted">Works with SOC 2 / ISO 27001 / NIST narratives. For regulated domains (21 CFR Part 11 / HIPAA), evidence packages often become a requirement.</span>
  </div>
</section>
""".strip()

ZH_COMPARE = r"""
<section id="compare" class="section">
  <h2>Community / Pro 對比</h2>
  <p>Community 先讓你跑起來；Pro 讓你交付時拿得出證據。</p>

  <table class="compare">
    <tr><th>能被驗證的項目</th><th>Community</th><th>Pro</th></tr>
    <tr><td>Quickstart（可跑）＋ build/start ＋ smoke</td><td>✅</td><td>✅</td></tr>
    <tr><td>可重現的 demo script</td><td>✅</td><td>✅</td></tr>
    <tr><td><strong>證據輸出</strong>（稽核匯出／證據包／留存策略）</td><td>—</td><td>🟡 Gate：v6.0.0</td></tr>
    <tr><td><strong>政策閘門</strong>（Policy-as-Code / packs）</td><td>—</td><td>🟡 Gate：v6.0.0</td></tr>
    <tr><td><strong>成本透明</strong>（任務級用量歸因／預算上限／自動暫停）</td><td>—</td><td>🟡 Gate：v6.0.0</td></tr>
  </table>

  <div class="cards">
    <div class="card">
      <h3>證據輸出</h3>
      <p>每次交付都有「收據」：誰做了什麼、改了什麼、怎麼驗過、花了多少。</p>
    </div>
    <div class="card">
      <h3>政策閘門</h3>
      <p>把風險擋在上線前：不符合規範，就不能跑、不能發。</p>
    </div>
    <div class="card">
      <h3>成本透明</h3>
      <p>看得懂、算得清：用量可歸因、預算可控，交付品質更可預期。</p>
    </div>
  </div>

  <div class="callout">
    <strong>採購語言</strong>
    <span class="muted">可以對齊 SOC 2／ISO 27001／NIST 的治理敘事；在 21 CFR Part 11／HIPAA 這類場景，「證據包」常常會直接變成採購條件。</span>
  </div>
</section>
""".strip()

EN_PERSONAS = r"""
<section id="personas" class="section">
  <h2>Who it’s for</h2>
  <div class="cards">
    <div class="card">
      <h3>Consulting / Agency delivery teams</h3>
      <p>Need non-stop delivery, billable cost clarity, and a “receipt” they can hand to clients.</p>
    </div>
    <div class="card">
      <h3>Compliance / Security / GRC</h3>
      <p>Need audit-ready exports, retention, and a clear responsibility boundary.</p>
    </div>
    <div class="card">
      <h3>Staff / Architects</h3>
      <p>Need policy gates to prevent drift and keep systems shippable over time.</p>
    </div>
  </div>
</section>
""".strip()

ZH_PERSONAS = r"""
<section id="personas" class="section">
  <h2>適合哪些團隊</h2>
  <div class="cards">
    <div class="card">
      <h3>顧問／接案／Agency 交付團隊</h3>
      <p>需要不中斷的交付節奏、能對客戶交差的證據包，成本也要算得清。</p>
    </div>
    <div class="card">
      <h3>合規／資安／稽核</h3>
      <p>需要可匯出、可留存、可遮罩的稽核資料，責任邊界也要講得清。</p>
    </div>
    <div class="card">
      <h3>資深工程／架構／交付負責人</h3>
      <p>需要政策閘門防漂移，讓系統長期維持「可交付」狀態。</p>
    </div>
  </div>
</section>
""".strip()

# ---- apply EN ----
en = Path("en/index.html").read_text(encoding="utf-8")
en2 = en
en2 = replace_first_h1(en2, EN_H1)
en2 = replace_first_lead(en2, EN_LEAD)
en2 = replace_section(en2, "community-proof", EN_COMMUNITY_PROOF)
en2 = replace_section(en2, "compare", EN_COMPARE)
en2 = replace_section(en2, "personas", EN_PERSONAS)
Path("en/index.html").write_text(en2, encoding="utf-8")
print("[OK] patched en/index.html")

# ---- apply ZH ----
zh = Path("zh-Hant/index.html").read_text(encoding="utf-8")
zh2 = zh
zh2 = replace_first_h1(zh2, ZH_H1)
zh2 = replace_first_lead(zh2, ZH_LEAD)
zh2 = replace_section(zh2, "community-proof", ZH_COMMUNITY_PROOF)
zh2 = replace_section(zh2, "compare", ZH_COMPARE)
zh2 = replace_section(zh2, "personas", ZH_PERSONAS)
Path("zh-Hant/index.html").write_text(zh2, encoding="utf-8")
print("[OK] patched zh-Hant/index.html")

PY

echo "== sanity grep =="
grep -RIn "Not a chat UI|Who pays first|最快付費|硬證據|建立信任；Pro|上船前" en/index.html zh-Hant/index.html || echo "[OK] removed the known bad phrases"

echo "== show updated headings =="
grep -RIn "<h1>|id=\"community-proof\"|id=\"compare\"|id=\"personas\"" en/index.html zh-Hant/index.html | head -n 80
