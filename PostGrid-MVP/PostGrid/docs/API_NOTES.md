# API notes (October 2026)

- PostGrid 0.2 stores one media asset per post and a JSON list of independent platform destinations. Each destination owns its own schedule, caption override, YouTube title, status, and error.
- An empty per-platform caption means “use the post default caption” when the real connector is implemented.
- TikTok Direct Post requires the Content Posting API and `video.publish`. Unaudited clients are restricted to private visibility; public posting requires audit/review.
- YouTube `videos.insert` can upload video and `status.publishAt` can schedule a private video to go public later. New/unverified API projects may have public-upload restrictions until audit.
- Instagram and X connectors should be implemented only against the current official developer docs after app credentials are created.

Do not put client secrets in the iOS app. OAuth secrets and refresh tokens belong on the backend.
