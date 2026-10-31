# Website verification checklist

From the repository root, run `python -u -m http.server 5501 --bind 127.0.0.1 --directory website`, then visit `http://127.0.0.1:5501/`.

## Functional

- [ ] Home, About, Safety guide, App availability, Privacy, and 404 pages render.
- [ ] Main and footer navigation links resolve to existing pages.
- [ ] Mobile navigation opens and closes, updates `aria-expanded`, closes on Escape, and returns focus to its button.
- [ ] Navigation links remain visible if JavaScript is disabled.
- [ ] Legacy `/pages/about.html`, `/pages/download.html`, and `/pages/privacy-policy.html` paths redirect to their canonical pages.
- [ ] `/pages/login.html` explains that public-site sign-in is unavailable.
- [ ] The APK remains unavailable when no URL is configured; no fake file or success message is shown.
- [ ] A configured APK URL is an existing, verified `.apk` release URL before publishing.
- [x] Payment simulator detects cashback, lottery, refund, and KYC in payment notes.
- [x] Payment simulator flags amounts of INR 10,000 or more.
- [x] Safe-looking test values show a green simulation-only status, not a real payment confirmation.
- [x] Risk alerts explain detected signals and state that no payment was sent.
- [x] Risk alert modal closes with Escape and returns focus to the Pay button.
- [x] Simulator entries are not submitted to the backend or stored; no `/api/` requests occurred during browser checks.
- [ ] Missing paths are configured to return `404.html` with HTTP status 404 by the static host.

## Accessibility and responsive layout

- [ ] Keyboard users can skip to content and see focus on interactive elements.
- [ ] Mobile menu has an accessible name and its state is announced.
- [ ] Pages reflow at desktop, tablet, and narrow mobile widths without horizontal overflow.
- [ ] Text, warnings, and links remain readable with reduced motion enabled.
- [ ] Native FAQ disclosures work with a keyboard.

## Actual checks performed

- [x] Python HTTP server started successfully on port 5501 using Python 3.13.12.
- [x] Home, About, Safety guide, Download, Privacy, 404, CSS, JS, and legacy page URLs returned HTTP 200 from localhost.
- [x] Local relative links passed for all 10 static-site HTML files. The separate `disha-frontend/` Vite app was excluded because its root-relative imports require its own dev server/build.
- [x] Browser reported no JavaScript page errors on the tested pages. The mobile menu's open, Escape-close, and focus-return behavior passed with test-only styles exposing the toggle.
- [x] An unsafe configured `javascript:` APK target stays unavailable and displays an explicit configuration warning.
- [x] No `.apk` file is present in the repository; the download remains unavailable by default.
- [x] Interactive payment simulator keyword, amount, and safe-result flows tested in the browser.
- [x] All four configured keywords, INR 10,000 threshold, safe result, Escape dismissal/focus return, and zero backend/storage writes verified in the browser.
- [ ] Desktop/tablet/mobile visual breakpoints could not be fully exercised: the integrated browser reported a 1511px document viewport after a 375px Playwright viewport request. Responsive rules were reviewed in CSS but should be checked on real device widths before release.
- [ ] Host-specific missing-path routing, including HTTP 404 status for `404.html`, was not tested locally or on CloudFront.

Checked 31 October 2026. Local command: `python -u -m http.server 5501 --bind 127.0.0.1 --directory website`; URL: `http://127.0.0.1:5501/`. Port 5500 accepted TCP but returned an empty HTTP response. The integrated browser loaded the site successfully on 5501. The APK release URL remains unconfigured.
