export async function onRequest({ request, next }) {
  const url = new URL(request.url);

  // 只把 pages.dev 導去自訂網域，避免迴圈
  if (url.hostname.endsWith(".pages.dev")) {
    url.hostname = "shipyard.tsaielectro.com";
    return Response.redirect(url.toString(), 301);
  }

  return next();
}
