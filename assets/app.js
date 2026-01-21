
(function(){
  // Root page auto-redirect: browser zh -> zh-Hant, else en
  if (location.pathname === "/" || location.pathname === "/index.html") {
    const lang = (navigator.language || "").toLowerCase();
    const target = lang.includes("zh") ? "/zh-Hant/" : "/en/";
    location.replace(target);
  }
})();
