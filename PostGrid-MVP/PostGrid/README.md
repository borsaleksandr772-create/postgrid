# PostGrid MVP 0.2

Native SwiftUI iPhone scheduler + FastAPI backend for planning one short-form video across TikTok, Instagram Reels, YouTube Shorts, and X.

## The flow implemented now
1. Pick **one video** from the iPhone photo library.
2. Write an optional internal post name and one **default description**.
3. Tick any combination of Instagram / TikTok / YouTube / X.
4. For **each selected platform**, choose its own date + time and optional platform-specific description.
5. For YouTube, add a separate title.
6. Tap **Schedule** once.
7. The month calendar shows every platform publication at its actual scheduled time; Queue groups all destinations under the single source video.

There is also a **Quick schedule** control to copy one date/time to every selected platform.

## What works in this MVP
- Month calendar grid
- One source video -> multiple platform destinations
- Native iOS video picker
- Video uploaded once to the backend media folder
- Independent date/time per platform
- Default caption + per-platform override
- YouTube-specific title
- Queue with independent per-platform status
- Backend persistence in SQLite
- Mock due-job runner that publishes each destination independently (safe UI test)
- Accounts screen prepared for official OAuth connectors

## What is intentionally not live yet
Real social publishing is still disabled. Instagram, TikTok, YouTube, and X each require their own developer app/OAuth credentials, and some require review/audit before public automated posting.

## Run backend
```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

Uploaded test videos are stored in `backend/media/`.

## Run iOS app
This repo includes `project.yml` for XcodeGen.

```bash
brew install xcodegen
cd ios
xcodegen generate
open PostGrid.xcodeproj
```

Run on an iPhone simulator. The default API URL is `http://127.0.0.1:8000`.

For a physical iPhone, change `APIClient.baseURL` to your Mac's LAN IP, e.g. `http://192.168.1.20:8000`, and allow local-network access.

## Next integration order
1. YouTube OAuth + upload/scheduled publish
2. Instagram OAuth + Reels publishing
3. X OAuth + media/post publishing
4. TikTok OAuth + Direct Post API + review/audit for public posting

## PWA / iPhone without Xcode (v0.3)
A new `web/` version is included. It works like the earlier Sasha English app: host `web/` on GitHub Pages/Netlify/Vercel, open it in Safari, then **Share → Add to Home Screen**. No Xcode is required for this version.

See `web/README-PWA.md`.
