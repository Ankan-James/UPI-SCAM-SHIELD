(() => {
  const downloadLink = document.querySelector("#apk-download-link");
  const unavailableMessage = document.querySelector("#apk-unavailable");
  const releaseMeta = document.querySelector("#apk-release-meta");
  const configuredTarget = window.NUMPE_CONFIG?.apkUrl;

  if (!(downloadLink instanceof HTMLAnchorElement) ||
      !(unavailableMessage instanceof HTMLElement) ||
      !(releaseMeta instanceof HTMLElement)) return;

  if (typeof configuredTarget !== "string" || configuredTarget.trim() === "") return;

  const showConfigurationError = () => {
    unavailableMessage.textContent = "The configured APK link is invalid. The download is unavailable until a valid, verified .apk URL is published.";
  };

  let target;
  try {
    target = new URL(configuredTarget.trim(), window.location.href);
  } catch {
    showConfigurationError();
    return;
  }

  const isAllowedProtocol = target.protocol === "https:" ||
    (target.protocol === "http:" && target.origin === window.location.origin);
  if (!isAllowedProtocol || !/\.apk$/i.test(target.pathname)) {
    showConfigurationError();
    return;
  }

  downloadLink.href = target.href;
  downloadLink.hidden = false;
  unavailableMessage.hidden = true;
})();
