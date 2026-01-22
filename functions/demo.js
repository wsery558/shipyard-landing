export async function onRequest() {
  const html = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Shipyard Demo — Reproducible Quickstart</title>
  <link rel="stylesheet" href="/assets/style.css" />
</head>
<body>
  <main class="container" style="max-width: 980px; margin: 0 auto; padding: 28px 18px;">
    <a href="/en/" class="muted" style="text-decoration:none;">← Back to landing</a>
    <h1 style="margin-top:14px;">Reproducible demo (local)</h1>
    <p class="lead">Copy, paste, run. If it doesn’t pass smoke, it’s not shipped.</p>

    <div style="margin:18px 0;">
      <img src="/assets/demo.gif" alt="Shipyard demo" style="width:100%; display:block; border-radius:12px;" />
    </div>

    <h2>Quickstart</h2>
    <p class="muted">This pulls the open-source Community repo.</p>

    <div style="display:flex; gap:10px; align-items:center; margin:10px 0;">
      <a class="btn secondary" target="_blank" rel="noreferrer" href="https://github.com/wsery558/shipyard-community">Open GitHub</a>
      <button id="copyBtn" class="btn primary" type="button">Copy commands</button>
    </div>

    <pre style="padding:14px; border-radius:12px; overflow:auto;"><code id="cmd">git clone https://github.com/wsery558/shipyard-community
cd shipyard-community
pnpm install
pnpm dev
</code></pre>

    <p style="margin-top:18px;">
      After you’ve tried it: <a href="/waitlist/" class="muted">Join the waitlist</a>
    </p>
  </main>

  <script>
    (function() {
      var btn = document.getElementById("copyBtn");
      var code = document.getElementById("cmd");
      if (!btn || !code) return;
      btn.addEventListener("click", async function() {
        try {
          await navigator.clipboard.writeText(code.textContent || "");
          btn.textContent = "Copied ✅";
          setTimeout(function(){ btn.textContent = "Copy commands"; }, 1200);
        } catch (e) {
          btn.textContent = "Copy failed";
          setTimeout(function(){ btn.textContent = "Copy commands"; }, 1200);
        }
      });
    })();
  </script>
</body>
</html>`;
  return new Response(html, { headers: { "content-type": "text/html; charset=utf-8" } });
}
