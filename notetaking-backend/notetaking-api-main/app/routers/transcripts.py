from fastapi import APIRouter, HTTPException, status, Depends
from typing import List

from app import schemas
from app.services.transcript_service import TranscriptService
from app.services.recording_service import RecordingService
from app.auth import get_current_user

router = APIRouter(prefix="/transcripts", tags=["Transcripts"])

@router.get("/", response_model=List[schemas.Transcript])
def get_all_transcripts(current_user: schemas.User = Depends(get_current_user)):
    # This should be filtered by user, but for now require auth.
    return TranscriptService.get_all_transcripts()

@router.get("/{transcript_id}", response_model=schemas.TranscriptDetail)
def get_transcript(transcript_id: str, current_user: schemas.User = Depends(get_current_user)):
    transcript = TranscriptService.get_transcript_by_id(transcript_id)
    if not transcript:
        raise HTTPException(status_code=404, detail="Transcript not found")
        
    # Verify ownership
    recording = RecordingService.get_recording_details(current_user.user_id, transcript.recording_id)
    if not recording:
         raise HTTPException(status_code=403, detail="Access denied")
         
    return transcript

@router.post("/", response_model=schemas.Transcript, status_code=status.HTTP_201_CREATED)
def create_transcript(transcript: schemas.TranscriptCreate, current_user: schemas.User = Depends(get_current_user)):
    # Verify ownership
    recording = RecordingService.get_recording_details(current_user.user_id, transcript.recording_id)
    if not recording:
         raise HTTPException(status_code=403, detail="Access denied")
         
    return TranscriptService.create_transcript(transcript)

@router.patch("/{transcript_id}", response_model=schemas.Transcript)
def update_transcript(transcript_id: str, transcript: schemas.TranscriptUpdate, current_user: schemas.User = Depends(get_current_user)):
    existing_transcript = TranscriptService.get_transcript_by_id(transcript_id)
    if not existing_transcript:
        raise HTTPException(status_code=404, detail="Transcript not found")
        
    # Verify ownership
    recording = RecordingService.get_recording_details(current_user.user_id, existing_transcript.recording_id)
    if not recording:
         raise HTTPException(status_code=403, detail="Access denied")
         
    updated_transcript = TranscriptService.update_transcript(current_user.user_id, transcript_id, transcript)
    return updated_transcript

@router.delete("/{transcript_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_transcript(transcript_id: str, current_user: schemas.User = Depends(get_current_user)):
    existing_transcript = TranscriptService.get_transcript_by_id(transcript_id)
    if not existing_transcript:
        raise HTTPException(status_code=404, detail="Transcript not found")
        
    # Verify ownership
    recording = RecordingService.get_recording_details(current_user.user_id, existing_transcript.recording_id)
    if not recording:
         raise HTTPException(status_code=403, detail="Access denied")
         
    TranscriptService.delete_transcript(transcript_id)
    return None

