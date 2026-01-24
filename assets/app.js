(function(){
  // Root page auto-redirect: browser zh -> zh-Hant, else en
  if (location.pathname === "/" || location.pathname === "/index.html") {
    const lang = (navigator.language || "").toLowerCase();
    const target = lang.includes("zh") ? "/zh-Hant/" : "/en/";
    location.replace(target);
  }
})();


// shipyard:demo:init:v1
(function () {
  function onReady(fn) {
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", fn);
    else fn();
  }

  function isDemoPage() {
    var body = document.body;
    if (body && body.classList.contains("page-demo")) return true;
    var path = (window.location.pathname || "").toLowerCase();
    return path.endsWith("/demo/") || path.endsWith("/demo");
  }

  function getLang() {
    var body = document.body;
    return (body && body.getAttribute("data-lang")) || "";
  }

  function track(event, payload) {
    if (window.shipyardTrack) {
      window.shipyardTrack(event, payload);
    }
  }

  onReady(function () {
    if (!isDemoPage()) return;
    var lang = getLang();
    track("demo_page_view", { lang: lang, path: window.location.pathname, persona: "demo" });

    var tabButtons = Array.from(document.querySelectorAll("[data-demo-tab]"));
    var panels = Array.from(document.querySelectorAll("[data-demo-panel]"));
    if (!tabButtons.length || !panels.length) return;

    var STORAGE_KEY = "shipyard_demo_tab";

    function getButtonTab(btn) {
      return (btn.getAttribute("data-demo-tab") || btn.dataset.tab || "").trim();
    }

    function getPanelTab(panel) {
      return (
        (panel.getAttribute("data-demo-panel") || panel.dataset.demoPanel || panel.id || "")
          .replace(/^demo-/, "")
          .trim()
      );
    }

    var validTabs = tabButtons.map(getButtonTab).filter(Boolean);
    if (!validTabs.length) return;

    function matchesTab(name) {
      return Boolean(name && validTabs.indexOf(name) !== -1);
    }

    function safeSetItem(value) {
      try {
        localStorage.setItem(STORAGE_KEY, value);
      } catch (err) {
        // ignore
      }
    }

    function safeGetItem() {
      try {
        return localStorage.getItem(STORAGE_KEY);
      } catch (err) {
        return null;
      }
    }

    function persistUrl(tabName) {
      try {
        var url = new URL(window.location);
        url.searchParams.set("tab", tabName);
        window.history.replaceState({}, "", url);
      } catch (err) {
        // ignore
      }
    }

    function setActiveTab(tabName, emitTrack) {
      if (!matchesTab(tabName)) tabName = "smoke";
      tabButtons.forEach(function (btn) {
        var name = getButtonTab(btn);
        btn.classList.toggle("active", name === tabName);
      });

      panels.forEach(function (panel) {
        var name = getPanelTab(panel);
        var isActive = name === tabName;
        panel.classList.toggle("active", isActive);
        if (isActive) panel.removeAttribute("hidden");
        else panel.setAttribute("hidden", "");
      });

      safeSetItem(tabName);
      persistUrl(tabName);

      if (emitTrack) {
        track("demo_tab_click", { tab: tabName, lang: lang, persona: "demo" });
      }
    }

    tabButtons.forEach(function (btn) {
      btn.addEventListener("click", function () {
        var tabName = getButtonTab(btn);
        setActiveTab(tabName, true);
      });
    });

    var initialTab = (function () {
      var params = new URLSearchParams(window.location.search);
      var urlTab = params.get("tab");
      if (matchesTab(urlTab)) return urlTab;
      var stored = safeGetItem();
      if (matchesTab(stored)) return stored;
      return "smoke";
    })();

    setActiveTab(initialTab, false);

    var evidenceBtn = document.querySelector('[data-track="demo-evidence-pack"]');
    if (evidenceBtn) {
      evidenceBtn.addEventListener("click", function () {
        track("demo_evidence_pack_click", {
          lang: lang,
          label: evidenceBtn.textContent.trim(),
          persona: "demo"
        });
      });
    }
  });
})();

// shipyard:track:sendbeacon:v1
// Reliable tracking with sendBeacon (preferred) + fetch fallback
window.shipyardTrack = function(event, payload) {
  try {
    const data = {
      event: event,
      path: window.location.pathname,
      track: new Date().toISOString(),
      ua: navigator.userAgent,
      ref: document.referrer,
      ...payload
    };
    const json = JSON.stringify(data);
    const blob = new Blob([json], { type: 'application/json' });
    
    // Primary: sendBeacon (guaranteed delivery, even on page unload)
    if (navigator.sendBeacon) {
      navigator.sendBeacon('/__track', blob);
    } else {
      // Fallback: fetch with keepalive
      fetch('/__track', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: json,
        keepalive: true
      }).catch(() => {});
    }
  } catch (err) {
    // Fail silently
  }
};

// shipyard:config:payment:v1
// Get payment URL from meta tag or default to placeholder
window.SHIPYARD_PAYMENT_URL = (function() {
  var metaTag = document.querySelector('meta[name="shipyard-payment-url"]');
  if (metaTag && metaTag.getAttribute('content')) {
    var url = metaTag.getAttribute('content').trim();
    if (url && !url.includes('REPLACE_ME')) {
      return url;
    }
  }
  return 'https://REPLACE_ME';
})();

// shipyard:tracking:v1
(function () {
  function onReady(fn) {
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", fn);
    else fn();
  }

  function trackEvent(eventName, eventData) {
    var payload = {
      event: eventName,
      timestamp: new Date().toISOString(),
      url: window.location.href,
      ...eventData
    };
    
    // Log to console
    console.log('📊 Shipyard Event:', payload);
    
    // Optional: Send beacon if tracking endpoint available
    try {
      if (navigator.sendBeacon) {
        navigator.sendBeacon('/__track', JSON.stringify(payload));
      }
    } catch (err) {
      // Silent fail - beacon is optional
    }
  }

  onReady(function () {
    // Track CTA clicks
    var ctaButtons = document.querySelectorAll('[data-track="cta"]');
    ctaButtons.forEach(function (btn) {
      btn.addEventListener('click', function () {
        trackEvent('cta_click', {
          label: btn.textContent.trim(),
          href: btn.getAttribute('href')
        });
      });
    });

    // Track evidence tab switches
    var evidenceTabs = document.querySelectorAll('[data-track="tab"]');
    evidenceTabs.forEach(function (tab) {
      tab.addEventListener('click', function () {
        trackEvent('evidence_tab_switch', {
          tab_name: tab.textContent.trim()
        });
      });
    });

    // Track offer button clicks
    var offerButtons = document.querySelectorAll('[data-track="offer"]');
    offerButtons.forEach(function (btn) {
      btn.addEventListener('click', function () {
        trackEvent('offer_interaction', {
          offer_type: btn.getAttribute('data-track-type'),
          label: btn.textContent.trim()
        });
      });
    });
  });
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


// shipyard:evidence-tabs:v1
(function () {
  function onReady(fn) {
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", fn);
    else fn();
  }

  onReady(function () {
    var tabs = document.querySelectorAll('.evidence-tab-btn');
    var panels = document.querySelectorAll('.evidence-panel');
    var copyBtns = document.querySelectorAll('.panel-copy-btn');

    // Tab switching
    tabs.forEach(function (tab, index) {
      tab.addEventListener('click', function () {
        // Deactivate all tabs and panels
        tabs.forEach(function (t) { t.classList.remove('active'); });
        panels.forEach(function (p) { p.classList.remove('active'); });
        
        // Activate clicked tab and corresponding panel
        tab.classList.add('active');
        if (panels[index]) {
          panels[index].classList.add('active');
        }
      });
    });

    // Panel copy buttons
    copyBtns.forEach(function (btn) {
      btn.addEventListener('click', function (e) {
        e.preventDefault();
        var panel = btn.closest('.evidence-panel');
        if (!panel) return;

        var content = panel.querySelector('.panel-content');
        if (!content) return;

        var textToCopy = content.textContent;

        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(textToCopy).then(function () {
            var originalText = btn.textContent;
            btn.textContent = 'Copied!';
            btn.classList.add('copied');
            setTimeout(function () {
              btn.textContent = originalText;
              btn.classList.remove('copied');
            }, 1500);
          });
        } else {
          var textarea = document.createElement('textarea');
          textarea.value = textToCopy;
          textarea.style.position = 'fixed';
          textarea.style.opacity = '0';
          document.body.appendChild(textarea);
          textarea.select();
          try {
            document.execCommand('copy');
            var originalText = btn.textContent;
            btn.textContent = 'Copied!';
            btn.classList.add('copied');
            setTimeout(function () {
              btn.textContent = originalText;
              btn.classList.remove('copied');
            }, 1500);
          } catch (err) {
            console.error('Copy failed:', err);
          }
          document.body.removeChild(textarea);
        }
      });
    });

    // Auto-activate first tab
    if (tabs.length > 0 && panels.length > 0) {
      tabs[0].classList.add('active');
      panels[0].classList.add('active');
    }
  });
})();


// shipyard:counter-animation:v1
(function () {
  function onReady(fn) {
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", fn);
    else fn();
  }

  onReady(function () {
    var prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    
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

    // Observe all counter cards
    document.querySelectorAll('.counter-card').forEach(function (card) {
      if (prefersReducedMotion) {
        card.classList.add('revealed');
      } else {
        observer.observe(card);
      }
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

// shipyard:scroll-linked-motion:v1
(function () {
  var prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  
  if (prefersReducedMotion) return; // Disable scroll-linked motion if reduce motion is set
  
  var ticking = false;
  var root = document.documentElement;
  
  function updateScrollVars() {
    var scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    var docHeight = document.documentElement.scrollHeight - window.innerHeight;
    var pageProgress = docHeight > 0 ? scrollTop / docHeight : 0;
    
    // Update CSS variables
    root.style.setProperty('--scrollY', scrollTop + 'px');
    root.style.setProperty('--page01', pageProgress);
    
    // Calculate hero section progress
    var hero = document.querySelector('.hero');
    if (hero) {
      var heroRect = hero.getBoundingClientRect();
      var heroHeight = hero.offsetHeight;
      var heroProgress = Math.max(0, Math.min(1, 1 - (heroRect.bottom / (window.innerHeight + heroHeight))));
      root.style.setProperty('--hero01', heroProgress);
    }
    
    ticking = false;
  }
  
  function onScroll() {
    if (!ticking) {
      requestAnimationFrame(updateScrollVars);
      ticking = true;
    }
  }
  
  window.addEventListener('scroll', onScroll, { passive: true });
  
  // Initial update
  updateScrollVars();
})();
