from fastapi import FastAPI

# Keep the application factory / app object here and include routers from submodules.
from app.auth import router as auth_router
from app.routers import (
    audit_logs,
    users,
    tiers,
    folders,
    recordings,
    recording_speakers,
    transcripts,
    transcript_segments,
    summaries,
    ai_usage_logs,
    markers,
    export_jobs,
    recording_tags,
    admin
)


app = FastAPI(title="Meeting Summary API")

# include auth endpoints
app.include_router(auth_router)
app.include_router(audit_logs.router)
app.include_router(users.router)
app.include_router(tiers.router)
app.include_router(folders.router)
app.include_router(recordings.router)
app.include_router(recording_speakers.router)
app.include_router(transcripts.router)
app.include_router(transcript_segments.router)
app.include_router(summaries.router)
app.include_router(ai_usage_logs.router)
app.include_router(markers.router)  # Now uses /recordings/{id}/markers
app.include_router(recording_tags.router)  # Now uses /recordings/{id}/tags
app.include_router(export_jobs.router)  # Now uses /recordings/{id}/export

app.include_router(admin.router)


@app.get("/", summary="Health check")
def read_root():
    return {"status": "ok", "message": "Meeting Summary API"}