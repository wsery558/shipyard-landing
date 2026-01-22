export async function onRequest(context) {
  const url = new URL(context.request.url);
  const p = url.pathname || "";

  // Block accidental backup artifacts (e.g. *.bak.*)
  if (p.includes(".bak.")) {
    return new Response("Not Found", { status: 404 });
  }

  return context.next();
}
