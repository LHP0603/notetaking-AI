from fastapi import APIRouter, HTTPException, status
from typing import List

from app import schemas
from app.services.recording_speaker_service import RecordingSpeakerService

router = APIRouter(prefix="/recordings", tags=["Recording Speakers"])

@router.get("/{recording_id}/speakers", response_model=List[schemas.RecordingSpeaker])
def get_recording_speakers(recording_id: str):
    return RecordingSpeakerService.get_speakers_by_recording_id(recording_id)

@router.post("/{recording_id}/speakers", response_model=schemas.RecordingSpeaker, status_code=status.HTTP_201_CREATED)
def create_recording_speaker(recording_id: str, speaker: schemas.RecordingSpeakerCreate):
    return RecordingSpeakerService.create_recording_speaker(recording_id, speaker)

@router.put("/speakers/{speaker_id}", response_model=schemas.RecordingSpeaker)
def update_recording_speaker(speaker_id: int, speaker: schemas.RecordingSpeakerUpdate):
    updated_speaker = RecordingSpeakerService.update_recording_speaker(speaker_id, speaker)
    if not updated_speaker:
        raise HTTPException(status_code=404, detail="Speaker not found")
    return updated_speaker

@router.delete("/speakers/{speaker_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_recording_speaker(speaker_id: int):
    RecordingSpeakerService.delete_recording_speaker(speaker_id)
    return None
