# PostGrid PWA 0.3 — iPhone version without Xcode

This version works like Sasha English: host the `web/` folder on any HTTPS static host (GitHub Pages / Netlify / Vercel), open the URL in Safari on iPhone, then **Share → Add to Home Screen**.

## What already works in the PWA
- standalone app-like interface on iPhone
- month calendar
- choose one video once
- tick Instagram / TikTok / YouTube / X
- separate date/time for each selected platform
- default caption + per-platform caption
- YouTube title
- local queue stored on the iPhone
- installable PWA + offline shell

## Important
This 0.3 PWA is the UI/planner. It does NOT yet post to social networks. Real unattended scheduled posting requires a hosted backend plus OAuth/API integrations. That backend will publish while the phone is asleep/offline.

## GitHub Pages deployment
1. Create a public GitHub repository, e.g. `postgrid`.
2. Upload the contents of this `web/` folder to the repository root (`index.html`, `app.js`, `styles.css`, `manifest.webmanifest`, `service-worker.js`, `icons/`).
3. GitHub → repository **Settings → Pages**.
4. Source: **Deploy from a branch**.
5. Branch: `main`, folder: `/(root)`.
6. Open the generated Pages URL in Safari on iPhone.
7. Safari Share button → **Add to Home Screen** → Add.

After that PostGrid launches from an icon like a normal app.
