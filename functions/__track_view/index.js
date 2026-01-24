function inferLang(pathname) {
  if (pathname.startsWith("/en")) return "en";
  if (pathname.startsWith("/zh-Hant")) return "zh-Hant";
  return "zh-Hant";
}

function parseNdjson(text) {
  if (!text) return [];
  return text
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => {
      try {
        return JSON.parse(line);
      } catch (err) {
        return null;
      }
    })
    .filter(Boolean);
}

function filterEvents(events, query) {
  return events.filter((e) => {
    if (query.event && e.event !== query.event) return false;
    if (query.persona && e.persona !== query.persona) return false;
    if (query.path && !(e.path || "").includes(query.path)) return false;
    if (query.lang && e.lang !== query.lang) return false;
    return true;
  });
}

function escapeCsv(value) {
  if (!value) return '""';
  const str = String(value);
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return '"' + str.replace(/"/g, '""') + '"';
  }
  return str;
}

function eventsToNdjson(events) {
  return events
    .map((e) => JSON.stringify(e))
    .join('\n');
}

function eventsToCsv(events) {
  const headers = ['ts', 'event', 'track', 'persona', 'path', 'lang', 'ref', 'ua'];
  const headerRow = headers.join(',');
  const rows = events.map((e) =>
    headers.map((h) => escapeCsv(e[h] || '')).join(',')
  );
  return [headerRow, ...rows].join('\n');
}

function renderTable(events) {
  const rows = events
    .slice(-200)
    .reverse()
    .map((e) => {
      return `<tr>
        <td>${e.ts || ""}</td>
        <td>${e.event || ""}</td>
        <td>${e.track || ""}</td>
        <td>${e.persona || ""}</td>
        <td>${e.path || ""}</td>
        <td>${e.lang || ""}</td>
        <td>${e.ref || ""}</td>
        <td>${e.ua || ""}</td>
      </tr>`;
    })
    .join("");

  if (!rows) {
    return "<p style='color:#9ca9b8;'>No events yet.</p>";
  }

  return `<table>
    <thead>
      <tr>
        <th>ts</th><th>event</th><th>track</th><th>persona</th><th>path</th><th>lang</th><th>ref</th><th>ua</th>
      </tr>
    </thead>
    <tbody>${rows}</tbody>
  </table>`;
}

export const onRequest = async ({ request, env }) => {
  const url = new URL(request.url);
  const date = url.searchParams.get("date") || new Date().toISOString().slice(0, 10);
  const qEvent = url.searchParams.get("event") || "";
  const qPersona = url.searchParams.get("persona") || "";
  const qPath = url.searchParams.get("path") || "";
  const qLang = url.searchParams.get("lang") || "";
  const format = url.searchParams.get("format") || "html";

  let events = [];
  let storage = "buffer";

  if (env && env.TRACK_KV && env.TRACK_KV.get) {
    try {
      const raw = await env.TRACK_KV.get(`events:${date}`, "text");
      events = parseNdjson(raw);
      storage = "kv";
    } catch (err) {
      events = [];
      storage = "kv-error";
    }
  } else if (globalThis.__EVENT_BUFFER) {
    events = Array.isArray(globalThis.__EVENT_BUFFER) ? globalThis.__EVENT_BUFFER : [];
    storage = "buffer";
  }

  const filtered = filterEvents(events, {
    event: qEvent,
    persona: qPersona,
    path: qPath,
    lang: qLang,
  });

  // Handle export formats
  if (format === "ndjson") {
    const ndjson = eventsToNdjson(filtered);
    return new Response(ndjson, {
      status: 200,
      headers: {
        "content-type": "application/x-ndjson; charset=utf-8",
        "content-disposition": `attachment; filename="shipyard-events-${date}.ndjson"`,
      },
    });
  }

  if (format === "csv") {
    const csv = eventsToCsv(filtered);
    return new Response(csv, {
      status: 200,
      headers: {
        "content-type": "text/csv; charset=utf-8",
        "content-disposition": `attachment; filename="shipyard-events-${date}.csv"`,
      },
    });
  }

  if (request.method !== "GET") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  const html = `<!doctype html>
  <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width,initial-scale=1" />
      <title>Shipyard Tracking View</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background:#0a0e14; color:#f0f4f8; margin:0; padding:24px; }
        h1 { margin: 0 0 12px; font-size:20px; }
        .muted { color:#9ca9b8; font-size: 12px; margin-bottom:12px; }
        .controls { display:flex; flex-wrap:wrap; gap:8px; margin-bottom:16px; }
        .filter { display:flex; flex-wrap:wrap; gap:8px; margin-bottom:12px; }
        input { padding:8px 10px; border-radius:6px; border:1px solid #1a1f29; background:#0f1419; color:#f0f4f8; }
        button, .export-btn { padding:8px 12px; border-radius:6px; border:1px solid #3b82f6; background:#3b82f6; color:white; cursor:pointer; text-decoration:none; display:inline-block; }
        button:hover, .export-btn:hover { background:#2563eb; }
        .export-btn { font-size:13px; }
        table { width:100%; border-collapse:collapse; font-size:13px; }
        th, td { border:1px solid rgba(148, 163, 184, 0.2); padding:8px; text-align:left; }
        th { background:#0f1419; position:sticky; top:0; }
        tr:nth-child(even) { background:#0f1419; }
        tr:nth-child(odd) { background:#0c1117; }
      </style>
    </head>
    <body>
      <h1>Shipyard Tracking View</h1>
      <div class="muted">Storage: ${storage} · Date: ${date}</div>
      <div class="controls">
        <form method="GET" action="${url.pathname}" class="filter">
          <input type="text" name="date" placeholder="YYYY-MM-DD" value="${date}" />
          <input type="text" name="event" placeholder="event" value="${qEvent}" />
          <input type="text" name="persona" placeholder="persona" value="${qPersona}" />
          <input type="text" name="path" placeholder="path contains" value="${qPath}" />
          <input type="text" name="lang" placeholder="lang" value="${qLang}" />
          <button type="submit">Filter</button>
        </form>
        <div style="display:flex; gap:8px;">
          <a href="${url.pathname}?date=${date}&event=${qEvent}&persona=${qPersona}&path=${qPath}&lang=${qLang}&format=ndjson" class="export-btn">Download NDJSON</a>
          <a href="${url.pathname}?date=${date}&event=${qEvent}&persona=${qPersona}&path=${qPath}&lang=${qLang}&format=csv" class="export-btn">Download CSV</a>
        </div>
      </div>
      ${renderTable(filtered)}
    </body>
  </html>`;

  return new Response(html, { status: 200, headers: { "content-type": "text/html; charset=utf-8" } });
};
