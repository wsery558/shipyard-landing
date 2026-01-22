(function(){
  // Root page auto-redirect: browser zh -> zh-Hant, else en
  if (location.pathname === "/" || location.pathname === "/index.html") {
    const lang = (navigator.language || "").toLowerCase();
    const target = lang.includes("zh") ? "/zh-Hant/" : "/en/";
    location.replace(target);
  }
})();


// shipyard:waitlist-prefill:v1
(function () {
  function onReady(fn) {
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", fn);
    else fn();
  }
  onReady(function () {
    var frame = document.getElementById("waitlistFrame");
    if (!frame) return;

    var chips = document.querySelectorAll("[data-form-src]");
    chips.forEach(function (el) {
      el.addEventListener("click", function (e) {
        // If JS works: keep user on page, swap iframe to prefilled URL
        e.preventDefault();
        var src = el.getAttribute("data-form-src");
        if (!src) return;
        frame.setAttribute("src", src);
        // ensure it's visible
        frame.scrollIntoView({ behavior: "smooth", block: "start" });
      });
    });
  });
})();
