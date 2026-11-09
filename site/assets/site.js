// Keystead — landing page behaviour: theme switch, tabbed decks, the quick search line, intro film, reveal on scroll.
(() => {
  const root = document.documentElement;
  const calm = matchMedia("(prefers-reduced-motion: reduce)").matches;

  // Theme: auto follows the system; day or night is remembered for this visitor.
  const themeButtons = document.querySelectorAll("[data-theme-set]");
  // <picture> sources follow the system by themselves; a picked theme points them the same way.
  const darkSources = document.querySelectorAll("source[data-dark]");
  const showTheme = (mode) => {
    themeButtons.forEach((b) => b.setAttribute("aria-pressed", String(b.dataset.themeSet === mode)));
    darkSources.forEach((s) => { s.media = mode === "dark" ? "all" : mode === "light" ? "not all" : "(prefers-color-scheme: dark)"; });
  };
  let saved = "auto";
  try { saved = localStorage.getItem("theme") || "auto"; } catch {}
  showTheme(saved);
  themeButtons.forEach((b) => b.addEventListener("click", () => {
    const mode = b.dataset.themeSet;
    if (mode === "auto") root.removeAttribute("data-theme"); else root.dataset.theme = mode;
    try { mode === "auto" ? localStorage.removeItem("theme") : localStorage.setItem("theme", mode); } catch {}
    showTheme(mode);
  }));

  // Tabs: [data-tabs] holds role=tab buttons and their panels; a deck adds prev/next and a counter.
  document.querySelectorAll("[data-tabs]").forEach((box) => {
    const tabs = [...box.querySelectorAll('[role="tab"]')];
    const panels = tabs.map((t) => document.getElementById(t.getAttribute("aria-controls")));
    const count = box.querySelector("[data-count]");
    let at = 0;
    const pad = (n) => String(n).padStart(2, "0");
    const select = (i, focus) => {
      at = (i + tabs.length) % tabs.length;
      tabs.forEach((t, j) => {
        const on = j === at;
        t.setAttribute("aria-selected", String(on));
        t.tabIndex = on ? 0 : -1;
        panels[j].hidden = !on;
        panels[j].classList.toggle("on", on);
      });
      if (count) count.textContent = `${pad(at + 1)} / ${pad(tabs.length)}`;
      if (focus) tabs[at].focus();
    };
    tabs.forEach((t, i) => {
      t.addEventListener("click", () => select(i));
      t.addEventListener("keydown", (e) => {
        const step = { ArrowRight: 1, ArrowLeft: -1 }[e.key];
        if (step) { e.preventDefault(); select(at + step, true); }
        if (e.key === "Home") { e.preventDefault(); select(0, true); }
        if (e.key === "End") { e.preventDefault(); select(tabs.length - 1, true); }
      });
    });
    box.querySelector("[data-prev]")?.addEventListener("click", () => select(at - 1));
    box.querySelector("[data-next]")?.addEventListener("click", () => select(at + 1));
    select(0);
  });

  // The hero's quick search line types a few letters, then shows what ↵ would copy.
  const line = document.querySelector("[data-line]");
  if (line) {
    const examples = JSON.parse(line.dataset.line);
    const typed = line.querySelector(".typed");
    const chip = line.querySelector(".chip");
    if (calm) {
      typed.textContent = examples[0][0];
      chip.textContent = examples[0][1];
    } else {
      const wait = (ms) => new Promise((r) => setTimeout(r, ms));
      (async () => {
        for (let i = 0; ; i = (i + 1) % examples.length) {
          const [text, result] = examples[i];
          chip.classList.add("off");
          typed.textContent = "";
          await wait(350);
          for (const ch of text) { typed.textContent += ch; await wait(130); }
          await wait(260);
          chip.textContent = result;
          chip.classList.remove("off");
          await wait(2400);
        }
      })();
    }
  }

  // The intro film loops silently; it waits for a click when the visitor asked for less motion.
  // If the film file isn't there, its section steps aside instead of showing an empty frame.
  const film = document.querySelector("[data-film]");
  const filmToggle = document.querySelector("[data-film-toggle]");
  if (film && filmToggle) {
    const section = film.closest("section");
    const gone = () => { if (section) section.hidden = true; };
    if (film.error || film.networkState === 3) gone();
    film.addEventListener("error", gone);
    const showFilm = () => {
      const paused = film.paused;
      filmToggle.classList.toggle("paused", paused);
      filmToggle.setAttribute("aria-label", paused ? filmToggle.dataset.labelPlay : filmToggle.dataset.labelPause);
    };
    if (calm) { film.removeAttribute("autoplay"); film.pause(); }
    film.addEventListener("play", showFilm);
    film.addEventListener("pause", showFilm);
    filmToggle.addEventListener("click", () => (film.paused ? film.play().catch(() => {}) : film.pause()));
    showFilm();
  }

  // Keep the last two short words of a paragraph together, so no line ends with one word alone.
  document.querySelectorAll("main p, main li, main figcaption, main td").forEach((el) => {
    const nodes = [], w = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
    let n, tail = 0;
    while ((n = w.nextNode())) nodes.push(n);
    for (let i = nodes.length - 1; i >= 0; i--) {
      if (nodes[i].parentElement.closest("code, kbd, pre")) return;
      const t = nodes[i].textContent, k = t.replace(/\s+$/, "").lastIndexOf(" ");
      if (k < 0) { tail += t.trim().length; if (tail > 8) return; continue; }
      if (tail + t.length - k - 1 <= 8) nodes[i].textContent = t.slice(0, k) + " " + t.slice(k + 1);
      return;
    }
  });

  // Sections fade in once as they scroll into view.
  const items = document.querySelectorAll(".reveal");
  if (calm || !("IntersectionObserver" in window)) {
    items.forEach((el) => el.classList.add("in"));
  } else {
    const io = new IntersectionObserver((entries) => entries.forEach((e) => {
      if (e.isIntersecting) { e.target.classList.add("in"); io.unobserve(e.target); }
    }), { rootMargin: "0px 0px -8% 0px" });
    items.forEach((el) => io.observe(el));
  }
})();
