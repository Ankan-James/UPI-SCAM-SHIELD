(() => {
  const config = window.NUMPE_CONFIG;
  const apiOrigin = typeof config?.apiBaseUrl === "string"
    ? config.apiBaseUrl.replace(/\/+$/, "")
    : "";
  const apiBase = `${apiOrigin}/api/auth`;
  const TOKEN_KEY = "numpe.auth.token";
  const USER_KEY = "numpe.auth.user";
  const form = document.querySelector("#auth-form");
  const feedback = document.querySelector("#auth-feedback");
  const nameField = document.querySelector("[data-name-field]");
  const nameInput = document.querySelector("#auth-name");
  const passwordInput = document.querySelector("#auth-password");
  const passwordHint = document.querySelector("[data-password-hint]");
  const submitButton = form?.querySelector('[type="submit"]');
  const tabs = [...document.querySelectorAll("[data-auth-mode]")];
  let mode = "login";

  const setFeedback = (message, kind = "error") => {
    if (!(feedback instanceof HTMLElement)) return;
    feedback.textContent = message;
    feedback.dataset.kind = kind;
    feedback.hidden = !message;
  };

  const showError = (error) => {
    if (error instanceof TypeError) {
      setFeedback("Could not reach the NUMPE API. Start the backend and check the API URL and CORS settings.");
    } else {
      setFeedback(error instanceof Error ? error.message : "The request failed. Please try again.");
    }
  };

  const request = async (endpoint, payload) => {
    if (!apiOrigin) throw new Error("The NUMPE API URL is not configured.");

    const response = await fetch(`${apiBase}/${endpoint}`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json" },
      body: JSON.stringify(payload),
    });

    let data;
    try {
      data = await response.json();
    } catch {
      throw new Error("The server returned an unreadable response. Please try again.");
    }

    if (!response.ok) {
      const detail = typeof data.detail === "string"
        ? data.detail
        : Array.isArray(data.detail)
          ? data.detail.map((item) => item.msg).filter(Boolean).join(" ")
          : "";
      throw new Error(detail || `Request failed (${response.status}). Please try again.`);
    }

    return data;
  };

  const saveSession = (data) => {
    if (typeof data.token !== "string" || !data.token || !data.user || typeof data.user !== "object") {
      throw new Error("The server response did not include a valid user session.");
    }
    sessionStorage.setItem(TOKEN_KEY, data.token);
    sessionStorage.setItem(USER_KEY, JSON.stringify({
      id: data.user.id ?? data.user.user_id,
      name: data.user.name,
      email: data.user.email,
    }));
  };

  const setMode = (nextMode) => {
    mode = nextMode;
    const registering = mode === "register";
    if (nameField instanceof HTMLElement) nameField.hidden = !registering;
    if (nameInput instanceof HTMLInputElement) {
      nameInput.disabled = !registering;
      nameInput.required = registering;
    }
    if (passwordInput instanceof HTMLInputElement) {
      passwordInput.autocomplete = registering ? "new-password" : "current-password";
      passwordInput.minLength = registering ? 8 : 1;
    }
    if (passwordHint instanceof HTMLElement) passwordHint.hidden = !registering;
    if (form instanceof HTMLFormElement) form.dataset.mode = mode;
    if (submitButton instanceof HTMLButtonElement) submitButton.textContent = registering ? "Create account" : "Log In";
    const title = document.querySelector("#auth-title");
    if (title) title.textContent = registering ? "Create your account." : "Welcome back.";
    tabs.forEach((tab) => {
      const selected = tab.getAttribute("data-auth-mode") === mode;
      tab.setAttribute("aria-selected", String(selected));
      tab.tabIndex = selected ? 0 : -1;
    });
    setFeedback("");
  };

  tabs.forEach((tab, index) => {
    tab.addEventListener("click", () => setMode(tab.getAttribute("data-auth-mode")));
    tab.addEventListener("keydown", (event) => {
      if (event.key !== "ArrowLeft" && event.key !== "ArrowRight") return;
      event.preventDefault();
      const direction = event.key === "ArrowRight" ? 1 : -1;
      const nextTab = tabs[(index + direction + tabs.length) % tabs.length];
      nextTab.focus();
      setMode(nextTab.getAttribute("data-auth-mode"));
    });
  });

  if (form instanceof HTMLFormElement &&
      feedback instanceof HTMLElement &&
      nameInput instanceof HTMLInputElement &&
      passwordInput instanceof HTMLInputElement &&
      submitButton instanceof HTMLButtonElement) {
    setMode("login");
    form.addEventListener("input", () => setFeedback(""));
    form.addEventListener("submit", async (event) => {
      event.preventDefault();
      setFeedback("");
      if (!form.reportValidity()) return;

      const email = String(new FormData(form).get("email") || "").trim();
      const password = passwordInput.value;
      if (mode === "register" && new TextEncoder().encode(password).length > 72) {
        setFeedback("Password must be no more than 72 UTF-8 bytes.");
        return;
      }

      submitButton.disabled = true;
      submitButton.textContent = mode === "register" ? "Creating account…" : "Signing in…";

      try {
        if (mode === "register") {
          await request("register", {
            name: nameInput.value.trim(),
            email,
            password,
          });
        }
        const session = await request("login", { email, password });
        saveSession(session);
        window.location.assign("../index.html?auth=success");
      } catch (error) {
        showError(error);
      } finally {
        submitButton.disabled = false;
        submitButton.textContent = mode === "register" ? "Create account" : "Log In";
      }
    });
  }

  const loginLink = document.querySelector("[data-login-link]");
  const greeting = document.querySelector("[data-auth-greeting]");
  const logoutButton = document.querySelector("[data-auth-logout]");
  const navStatus = document.querySelector("[data-auth-nav-status]");

  if (greeting instanceof HTMLElement && loginLink instanceof HTMLAnchorElement) {
    try {
      const user = JSON.parse(sessionStorage.getItem(USER_KEY) || "null");
      if (user && typeof user.name === "string" && sessionStorage.getItem(TOKEN_KEY)) {
        greeting.textContent = `Signed in as ${user.name}`;
        greeting.hidden = false;
        loginLink.hidden = true;
        if (logoutButton instanceof HTMLButtonElement) logoutButton.hidden = false;
      }
    } catch {
      sessionStorage.removeItem(USER_KEY);
    }
  }

  if (logoutButton instanceof HTMLButtonElement && navStatus instanceof HTMLElement) {
    logoutButton.addEventListener("click", async () => {
      const token = sessionStorage.getItem(TOKEN_KEY);
      logoutButton.disabled = true;
      try {
        if (token) {
          const response = await fetch(`${apiBase}/logout`, {
            method: "POST",
            headers: { Authorization: `Bearer ${token}`, Accept: "application/json" },
          });
          if (!response.ok) throw new Error(`The server could not revoke the session (${response.status}).`);
        }
        navStatus.textContent = "You are signed out.";
      } catch {
        navStatus.textContent = "Signed out on this device, but the server session could not be revoked and may remain valid until it expires.";
      } finally {
        sessionStorage.removeItem(TOKEN_KEY);
        sessionStorage.removeItem(USER_KEY);
        navStatus.hidden = false;
        if (greeting instanceof HTMLElement) greeting.hidden = true;
        if (loginLink instanceof HTMLAnchorElement) loginLink.hidden = false;
        logoutButton.hidden = true;
        logoutButton.disabled = false;
      }
    });
  }
})();