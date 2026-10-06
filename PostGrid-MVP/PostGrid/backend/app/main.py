from __future__ import annotations

import json
import sqlite3
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Literal

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

ROOT = Path(__file__).resolve().parent.parent
DB_PATH = ROOT / "postgrid.sqlite3"
MEDIA_DIR = ROOT / "media"
MEDIA_DIR.mkdir(parents=True, exist_ok=True)

app = FastAPI(title="PostGrid API", version="0.3.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # lock this down to the production PWA origin before launch
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

Status = Literal["draft", "scheduled", "publishing", "published", "failed"]


class Destination(BaseModel):
    platform: str
    enabled: bool = False
    scheduledAt: datetime
    caption: str = ""
    youtubeTitle: str = ""
    status: Status = "scheduled"
    errorMessage: str | None = None


class Post(BaseModel):
    id: int | None = None
    title: str = ""
    mediaPath: str = ""
    defaultCaption: str = ""
    destinations: list[Destination] = Field(default_factory=list)


class MediaUpload(BaseModel):
    path: str
    filename: str


def db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS post_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          media_path TEXT NOT NULL,
          default_caption TEXT NOT NULL,
          destinations TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
        """
    )
    return conn


def encode_destinations(destinations: list[Destination]) -> str:
    return json.dumps([d.model_dump(mode="json") for d in destinations], ensure_ascii=False)


def row_to_post(r: sqlite3.Row) -> Post:
    return Post(
        id=r["id"],
        title=r["title"],
        mediaPath=r["media_path"],
        defaultCaption=r["default_caption"],
        destinations=json.loads(r["destinations"]),
    )


def earliest_schedule(post: Post) -> datetime:
    enabled = [d.scheduledAt for d in post.destinations if d.enabled]
    if not enabled:
        return datetime.max.replace(tzinfo=timezone.utc)
    value = min(enabled)
    return value if value.tzinfo else value.replace(tzinfo=timezone.utc)


@app.get("/health")
def health():
    return {"ok": True, "time": datetime.now(timezone.utc).isoformat()}


@app.get("/posts", response_model=list[Post])
def list_posts():
    with db() as c:
        rows = c.execute("SELECT * FROM post_items ORDER BY created_at DESC").fetchall()
    return sorted((row_to_post(r) for r in rows), key=earliest_schedule)


@app.post("/posts", response_model=Post)
def create_post(post: Post):
    if not any(d.enabled for d in post.destinations):
        raise HTTPException(400, "Select at least one platform")
    with db() as c:
        cur = c.execute(
            "INSERT INTO post_items(title, media_path, default_caption, destinations, created_at) VALUES(?,?,?,?,?)",
            (
                post.title,
                post.mediaPath,
                post.defaultCaption,
                encode_destinations(post.destinations),
                datetime.now(timezone.utc).isoformat(),
            ),
        )
        c.commit()
        row = c.execute("SELECT * FROM post_items WHERE id=?", (cur.lastrowid,)).fetchone()
    return row_to_post(row)


@app.put("/posts/{post_id}", response_model=Post)
def update_post(post_id: int, post: Post):
    if not any(d.enabled for d in post.destinations):
        raise HTTPException(400, "Select at least one platform")
    with db() as c:
        exists = c.execute("SELECT 1 FROM post_items WHERE id=?", (post_id,)).fetchone()
        if not exists:
            raise HTTPException(404, "Post not found")
        c.execute(
            "UPDATE post_items SET title=?, media_path=?, default_caption=?, destinations=? WHERE id=?",
            (post.title, post.mediaPath, post.defaultCaption, encode_destinations(post.destinations), post_id),
        )
        c.commit()
        row = c.execute("SELECT * FROM post_items WHERE id=?", (post_id,)).fetchone()
    return row_to_post(row)


@app.delete("/posts/{post_id}")
def delete_post(post_id: int):
    with db() as c:
        c.execute("DELETE FROM post_items WHERE id=?", (post_id,))
        c.commit()
    return {"ok": True}


@app.post("/media", response_model=MediaUpload)
async def upload_media(file: UploadFile = File(...)):
    original = Path(file.filename or "video.mp4")
    suffix = original.suffix.lower() if original.suffix else ".mp4"
    if len(suffix) > 10:
        suffix = ".mp4"
    filename = f"{uuid.uuid4().hex}{suffix}"
    destination = MEDIA_DIR / filename

    with destination.open("wb") as output:
        while True:
            chunk = await file.read(1024 * 1024)
            if not chunk:
                break
            output.write(chunk)
    await file.close()
    return MediaUpload(path=str(destination), filename=filename)


@app.post("/jobs/run-due")
def run_due_jobs():
    """MVP mock publisher. Each selected platform is scheduled independently."""
    now = datetime.now(timezone.utc)
    published: list[dict[str, object]] = []

    with db() as c:
        rows = c.execute("SELECT * FROM post_items").fetchall()
        for row in rows:
            post = row_to_post(row)
            changed = False
            for destination in post.destinations:
                if not destination.enabled or destination.status != "scheduled":
                    continue
                scheduled = destination.scheduledAt
                if scheduled.tzinfo is None:
                    scheduled = scheduled.replace(tzinfo=timezone.utc)
                if scheduled <= now:
                    destination.status = "published"
                    destination.errorMessage = None
                    published.append({"postId": post.id, "platform": destination.platform})
                    changed = True
            if changed:
                c.execute(
                    "UPDATE post_items SET destinations=? WHERE id=?",
                    (encode_destinations(post.destinations), post.id),
                )
        c.commit()

    return {"ok": True, "published": published}
