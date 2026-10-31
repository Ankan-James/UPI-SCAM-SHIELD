# NUMPE public website

This folder contains the framework-free public information website. The pages use plain HTML, CSS, and vanilla JavaScript; they do not need a build step or a running backend. The separate `disha-frontend/` directory is an existing React/Vite app prototype and is not required to serve these static pages.

## What was wrong with the previous site

The root `index.html`, `css/style.css`, `js/main.js`, and the existing informational pages were zero-byte files. A web server could serve them successfully, but the root page had no document content or styles to render. The repository did not include evidence of an earlier server log, so a port conflict or a previous working-directory mistake cannot be confirmed. Python 3.13.12 is available in this development environment.

## Run locally

From the repository root in PowerShell, start the static server:

```powershell
python -u -m http.server 5501 --bind 127.0.0.1 --directory website
```

Keep the terminal open, then visit <http://127.0.0.1:5501/>. Open the following pages directly to check them:

- `/about.html`
- `/awareness.html`
- `/download.html`
- `/privacy.html`
- `/404.html`

The earlier browser failure was caused by a stopped local server (`ERR_EMPTY_RESPONSE`). In this environment port 5500 also accepted connections but returned empty responses, so the verified server is using port 5501. Keep the server terminal running while browsing. If a page looks blank, check the terminal output, confirm `website/index.html` exists, and inspect the browser console and Network panel for missing files.

## Pages and behavior

- `index.html`: project overview and primary links.
- `about.html`: project, app, backend, and Scam Shield limitations.
- `awareness.html`: practical payment-safety guidance.
- `download.html`: Android installation guidance and APK availability.
- `privacy.html`: website and backend data-practice summary based on the current source.
- `404.html`: static not-found page; configure the host to serve it for missing paths.
- `pages/`: compatibility redirects for the original about, download, and privacy URLs; the old login path now explains that the public site has no sign-in.

The mobile navigation is enhanced only when JavaScript initializes; without JavaScript, the links remain visible. The awareness-page disclosures use native `<details>` elements. The landing-page payment simulator checks its inputs locally for common suspicious terms and amounts of INR 10,000 or more. It never submits or saves the entered details and does not send money. Its keyword and amount checks are educational signals, not a fraud verdict.

## APK release configuration

No verified APK is included or published by this repository at the time this page was prepared. The download stays unavailable unless `js/config.js` is updated with a URL that points to a real, published `.apk` file. Configure only a URL that a maintainer has uploaded and tested from the intended public host. HTTPS URLs and same-origin HTTP(S) `.apk` paths are accepted; other protocols and non-APK URLs remain unavailable. Do not put credentials or signed secrets in this public file.

## AWS S3 and CloudFront deployment

Do not create AWS resources or make a bucket public as part of local development. For deployment, use an S3 bucket with public access blocked and a CloudFront origin access control (OAC) that is permitted to read the bucket.

1. Create/configure the private S3 origin and CloudFront distribution through your approved AWS process. Set the CloudFront default root object to `index.html`.
2. Upload the static site files from the repository root. Exclude the unrelated React/Vite prototype and untracked APK binaries:

   ```powershell
   aws s3 sync website/ s3://YOUR_PRIVATE_BUCKET/ --exclude "disha-frontend/*" --exclude "disha-frontend/**" --exclude "downloads/*.apk"
   ```

3. Configure the distribution's custom error response for 404 to use `/404.html` and return HTTP status 404. Confirm the direct `/404.html` page is also available.
4. After changing files, invalidate the updated paths in CloudFront (for example `/*`) or use versioned assets and suitable cache headers.
5. Verify the CloudFront URL over HTTPS: check `/`, every page listed above, CSS/JavaScript requests, a deliberately missing path, and the download's unavailable state. Confirm S3 is not directly publicly readable.

The AWS CLI example is a deployment template only; replace the bucket and distribution configuration with values approved for your environment. No AWS resources were created for this implementation.
