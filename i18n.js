// Quotestreak i18n runtime (vanilla, no framework). Loads generated locale JSON,
// swaps [data-i18n] text, exposes t(key, vars) for game.js's dynamic strings.
(function () {
  const SUPPORTED = ["en", "fr", "zh", "pa"];
  const FALLBACK = "en";
  const stored = localStorage.getItem("quotable.lang");
  const detected = (navigator.language || "en").slice(0, 2);
  const lang = SUPPORTED.includes(stored) ? stored : SUPPORTED.includes(detected) ? detected : FALLBACK;

  let dict = {};
  let fallbackDict = {};

  async function loadDict(lng) {
    const r = await fetch(`locales/${lng}.json`, { cache: "no-cache" });
    if (!r.ok) throw new Error(`locale ${lng} ${r.status}`);
    return r.json();
  }

  function t(key, vars) {
    let s = dict[key] ?? fallbackDict[key] ?? key;
    if (vars) for (const [k, v] of Object.entries(vars)) s = s.replace(`{${k}}`, v);
    return s;
  }

  function apply(root = document) {
    root.querySelectorAll("[data-i18n]").forEach((el) => {
      el.textContent = t(el.getAttribute("data-i18n"));
    });
    document.documentElement.lang = lang;
  }

  const ready = (async () => {
    fallbackDict = await loadDict(FALLBACK);
    dict = lang === FALLBACK ? fallbackDict : await loadDict(lang).catch(() => fallbackDict);
    apply();
  })();

  window.I18N = { t, ready, lang };
})();
