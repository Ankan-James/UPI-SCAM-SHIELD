(() => {
  const toggle = document.querySelector("[data-menu-toggle]");
  const navigation = document.querySelector("[data-navigation]");

  if (toggle instanceof HTMLButtonElement && navigation instanceof HTMLElement) {
    document.body.classList.add("menu-enhanced");

    const closeMenu = (restoreFocus = false) => {
      navigation.removeAttribute("data-open");
      toggle.setAttribute("aria-expanded", "false");
      toggle.querySelector(".sr-only").textContent = "Open navigation menu";
      if (restoreFocus) toggle.focus();
    };

    toggle.addEventListener("click", () => {
      const isOpen = toggle.getAttribute("aria-expanded") === "true";
      if (isOpen) {
        closeMenu();
      } else {
        navigation.setAttribute("data-open", "");
        toggle.setAttribute("aria-expanded", "true");
        toggle.querySelector(".sr-only").textContent = "Close navigation menu";
      }
    });

    navigation.addEventListener("click", (event) => {
      if (event.target instanceof Element && event.target.closest("a")) closeMenu();
    });

    document.addEventListener("keydown", (event) => {
      if (event.key === "Escape" && toggle.getAttribute("aria-expanded") === "true") closeMenu(true);
    });
  }

  const currentPath = window.location.pathname.replace(/\/+$/, "") || "/";
  document.querySelectorAll("[data-nav-link]").forEach((link) => {
    if (!(link instanceof HTMLAnchorElement)) return;
    const linkPath = new URL(link.href, window.location.href).pathname.replace(/\/+$/, "") || "/";
    if (linkPath === currentPath) link.setAttribute("aria-current", "page");
  });

  document.querySelectorAll("[data-current-year]").forEach((element) => {
    element.textContent = String(new Date().getFullYear());
  });
})();