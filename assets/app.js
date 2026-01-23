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


// shipyard:copy-to-clipboard:v1
(function () {
  function onReady(fn) {
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", fn);
    else fn();
  }

  function showToast(message) {
    // Remove any existing toast
    var existingToast = document.querySelector(".toast");
    if (existingToast) {
      existingToast.remove();
    }

    // Create new toast
    var toast = document.createElement("div");
    toast.className = "toast";
    toast.textContent = message;
    document.body.appendChild(toast);

    // Auto-remove after 2 seconds
    setTimeout(function () {
      toast.classList.add("toast-exit");
      setTimeout(function () {
        toast.remove();
      }, 200);
    }, 2000);
  }

  onReady(function () {
    var copyBtn = document.getElementById("copyBtn");
    var codeBlock = document.getElementById("quickstartCode");

    if (!copyBtn || !codeBlock) return;

    copyBtn.addEventListener("click", function (e) {
      e.preventDefault();
      
      // Extract text from code lines
      var lines = codeBlock.querySelectorAll(".code-line");
      var textToCopy = Array.from(lines).map(function (line) {
        var cmd = line.querySelector(".command");
        return cmd ? cmd.textContent.trim() : "";
      }).filter(Boolean).join("\n");

      // Try to copy to clipboard
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(textToCopy).then(function () {
          showToast("Copied to clipboard!");
        }).catch(function (err) {
          console.error("Failed to copy:", err);
          showToast("Failed to copy");
        });
      } else {
        // Fallback for older browsers
        var textarea = document.createElement("textarea");
        textarea.value = textToCopy;
        textarea.style.position = "fixed";
        textarea.style.opacity = "0";
        document.body.appendChild(textarea);
        textarea.select();
        try {
          document.execCommand("copy");
          showToast("Copied to clipboard!");
        } catch (err) {
          console.error("Failed to copy:", err);
          showToast("Failed to copy");
        }
        document.body.removeChild(textarea);
      }
    });
  });
})();


// shipyard:smooth-scroll:v1
(function () {
  function onReady(fn) {
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", fn);
    else fn();
  }

  onReady(function () {
    // Add smooth scroll behavior to all internal anchor links
    var links = document.querySelectorAll('a[href^="#"]');
    links.forEach(function (link) {
      link.addEventListener("click", function (e) {
        var href = this.getAttribute("href");
        if (href === "#") return;

        var targetId = href.substring(1);
        var target = document.getElementById(targetId);
        
        if (target) {
          e.preventDefault();
          target.scrollIntoView({ behavior: "smooth", block: "start" });
          
          // Update URL without triggering scroll
          if (history.pushState) {
            history.pushState(null, null, href);
          }
        }
      });
    });
  });
})();


// shipyard:scroll-reveal:v1
(function () {
  function onReady(fn) {
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", fn);
    else fn();
  }

  onReady(function () {
    // Check if user prefers reduced motion
    var prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    
    if (prefersReducedMotion) {
      // Immediately reveal all elements
      document.querySelectorAll('.reveal, .reveal-stagger').forEach(function (el) {
        el.classList.add('revealed');
      });
      return;
    }

    // Create intersection observer for scroll reveal
    var observerOptions = {
      root: null,
      rootMargin: '0px 0px -100px 0px',
      threshold: 0.1
    };

    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('revealed');
          observer.unobserve(entry.target);
        }
      });
    }, observerOptions);

    // Observe all reveal elements
    document.querySelectorAll('.reveal, .reveal-stagger').forEach(function (el) {
      observer.observe(el);
    });
  });
})();


// shipyard:typing-effect:v1
(function () {
  function onReady(fn) {
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", fn);
    else fn();
  }

  onReady(function () {
    var prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (prefersReducedMotion) return;

    var quickstartCode = document.getElementById('quickstartCode');
    if (!quickstartCode) return;

    // Add cursor to first command line
    var firstCommand = quickstartCode.querySelector('.code-line .command');
    if (!firstCommand) return;

    var cursor = document.createElement('span');
    cursor.className = 'typing-cursor';
    firstCommand.appendChild(cursor);

    // Optional: Remove cursor after a few seconds
    setTimeout(function () {
      cursor.style.opacity = '0';
      cursor.style.transition = 'opacity 0.5s';
    }, 5000);
  });
})();
