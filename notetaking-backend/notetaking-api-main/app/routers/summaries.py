from fastapi import APIRouter, HTTPException, status, Depends
from typing import List

from app import schemas
from app.services.summary_service import SummaryService
from app.services.recording_service import RecordingService
from app.auth import get_current_user

router = APIRouter(prefix="/summaries", tags=["Summaries"])

@router.get("/", response_model=List[schemas.Summary])
def get_all_summaries(current_user: schemas.User = Depends(get_current_user)):
    # This should probably be filtered by user, but for now we require auth.
    return SummaryService.get_all_summaries()

@router.get("/{summary_id}", response_model=schemas.Summary)
def get_summary(summary_id: str, current_user: schemas.User = Depends(get_current_user)):
    summary = SummaryService.get_summary_by_id(summary_id)
    if not summary:
        raise HTTPException(status_code=404, detail="Summary not found")
    
    # Verify ownership of the recording
    recording = RecordingService.get_recording_details(current_user.user_id, summary.recording_id)
    if not recording:
         raise HTTPException(status_code=403, detail="Access denied")
         
    return summary

@router.post("/", response_model=schemas.Summary, status_code=status.HTTP_201_CREATED)
def create_summary(summary: schemas.SummaryCreate, current_user: schemas.User = Depends(get_current_user)):
    # Verify ownership of the recording
    recording = RecordingService.get_recording_details(current_user.user_id, summary.recording_id)
    if not recording:
         raise HTTPException(status_code=403, detail="Access denied")
         
    return SummaryService.create_summary(summary)

@router.patch("/{summary_id}", response_model=schemas.Summary)
def update_summary(summary_id: str, summary: schemas.SummaryUpdate, current_user: schemas.User = Depends(get_current_user)):
    existing_summary = SummaryService.get_summary_by_id(summary_id)
    if not existing_summary:
        raise HTTPException(status_code=404, detail="Summary not found")
        
    # Verify ownership
    recording = RecordingService.get_recording_details(current_user.user_id, existing_summary.recording_id)
    if not recording:
         raise HTTPException(status_code=403, detail="Access denied")
         
    updated_summary = SummaryService.update_summary(summary_id, summary)
    return updated_summary

@router.delete("/{summary_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_summary(summary_id: str, current_user: schemas.User = Depends(get_current_user)):
    existing_summary = SummaryService.get_summary_by_id(summary_id)
    if not existing_summary:
        raise HTTPException(status_code=404, detail="Summary not found")
        
    # Verify ownership
    recording = RecordingService.get_recording_details(current_user.user_id, existing_summary.recording_id)
    if not recording:
         raise HTTPException(status_code=403, detail="Access denied")
         
    SummaryService.delete_summary(summary_id)
    return None
