export const onRequest = async ({ request, env }) => {
  if (request.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  let body;
  try {
    body = await request.json();
  } catch (err) {
    return new Response("Invalid JSON", { status: 400 });
  }

  const now = new Date();
  const ts = now.toISOString();
  const url = new URL(request.url);
  const path = (body.path || url.pathname || "/").toString();

  function inferLang(p) {
    if (p.startsWith("/en")) return "en";
    if (p.startsWith("/zh-Hant")) return "zh-Hant";
    return "zh-Hant"; // default
  }

  const record = {
    ts,
    event: body.event || "unknown",
    track: body.track || "",
    persona: body.persona || "",
    path,
    lang: body.lang || inferLang(path),
    ua: request.headers.get("user-agent") || "",
    ref: request.headers.get("referer") || "",
  };

  const line = JSON.stringify(record);
  const dateKey = ts.slice(0, 10); // YYYY-MM-DD
  const kvKey = `events:${dateKey}`;

  let stored = false;
  if (env && env.TRACK_KV && env.TRACK_KV.put) {
    try {
      const existing = (await env.TRACK_KV.get(kvKey, "text")) || "";
      const next = existing ? `${existing}\n${line}` : line;
      await env.TRACK_KV.put(kvKey, next);
      stored = true;
    } catch (err) {
      stored = false;
    }
  }

  if (!stored) {
    if (!globalThis.__EVENT_BUFFER) globalThis.__EVENT_BUFFER = [];
    globalThis.__EVENT_BUFFER.push(record);
    if (globalThis.__EVENT_BUFFER.length > 500) {
      globalThis.__EVENT_BUFFER.shift();
    }
  }

  return new Response(null, { status: 204 });
};
