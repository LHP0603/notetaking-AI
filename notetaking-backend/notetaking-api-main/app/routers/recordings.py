from fastapi import APIRouter, HTTPException, status, Depends, Response, BackgroundTasks
from typing import List, Optional

from app import schemas
from app.services.recording_service import RecordingService
from app.services.transcript_service import TranscriptService
from app.services.summary_service import SummaryService
from app.services.marker_service import MarkerService
from app.services.recording_tag_service import RecordingTagService
from app.services.export_job_service import ExportJobService
from app.auth import get_current_user

router = APIRouter(prefix="/recordings", tags=["Recordings"])

@router.get("/", response_model=List[schemas.Recording])
def get_recordings(
    response: Response,
    folder_id: Optional[str] = None,
    is_trashed: Optional[bool] = False,
    search: Optional[str] = None,
    tag: Optional[str] = None,
    page: int = 1,
    page_size: int = 10,
    current_user: schemas.User = Depends(get_current_user)
):
    result = RecordingService.get_filtered_recordings(
        user_id=current_user.user_id,
        folder_id=folder_id,
        is_trashed=is_trashed,
        search_query=search,
        tag=tag,
        page=page,
        page_size=page_size
    )
    
    # Add pagination header
    response.headers["X-Total-Count"] = str(result["total"])
    
    return result["data"]

@router.get("/{recording_id}", response_model=schemas.RecordingDetail)
def get_recording(recording_id: str, current_user: schemas.User = Depends(get_current_user)):
    recording = RecordingService.get_recording_details(current_user.user_id, recording_id)
    if not recording:
        raise HTTPException(status_code=404, detail="Recording not found")
    return recording

@router.post("/", response_model=schemas.Recording, status_code=status.HTTP_201_CREATED)
def create_recording(recording: schemas.RecordingInitRequest, current_user: schemas.User = Depends(get_current_user)):
    return RecordingService.create_recording_metadata(current_user.user_id, recording)

@router.post("/{recording_id}/complete-upload", response_model=schemas.Recording)
def complete_upload(recording_id: str, request: schemas.RecordingUploadCompleteRequest, current_user: schemas.User = Depends(get_current_user)):
    return RecordingService.complete_upload_recording(current_user.user_id, recording_id, request)

@router.put("/{recording_id}", response_model=schemas.Recording)
def update_recording(recording_id: str, recording: schemas.RecordingUpdate, current_user: schemas.User = Depends(get_current_user)):
    # Verify ownership
    RecordingService.get_recording_details(current_user.user_id, recording_id)
    updated_recording = RecordingService.update_recording(recording_id, recording)
    if not updated_recording:
        raise HTTPException(status_code=404, detail="Recording not found")
    return updated_recording

@router.patch("/{recording_id}", response_model=schemas.Recording)
def patch_recording(recording_id: str, recording: schemas.RecordingUserUpdate, current_user: schemas.User = Depends(get_current_user)):
    return RecordingService.update_recording_details(current_user.user_id, recording_id, recording)

@router.delete("/{recording_id}", status_code=status.HTTP_204_NO_CONTENT)
def soft_delete_recording(recording_id: str, current_user: schemas.User = Depends(get_current_user)):
    RecordingService.soft_delete_recording(current_user.user_id, recording_id)
    return None

@router.post("/{recording_id}/restore", response_model=schemas.Recording)
def restore_recording(recording_id: str, current_user: schemas.User = Depends(get_current_user)):
    return RecordingService.restore_recording(current_user.user_id, recording_id)

@router.delete("/{recording_id}/hard-delete", status_code=status.HTTP_204_NO_CONTENT)
def hard_delete_recording(recording_id: str, current_user: schemas.User = Depends(get_current_user)):
    RecordingService.hard_delete_recording(current_user.user_id, recording_id)
    return None

@router.post("/{recording_id}/transcribe", status_code=status.HTTP_202_ACCEPTED)
def transcribe_recording(recording_id: str, background_tasks: BackgroundTasks, current_user: schemas.User = Depends(get_current_user)):
    # Verify ownership
    RecordingService.get_recording_details(current_user.user_id, recording_id)
    
    # Add to background tasks
    background_tasks.add_task(RecordingService.transcribe_recording, recording_id)
    
    return {"message": "Transcription started in background"}

@router.get("/{recording_id}/transcripts", response_model=List[schemas.Transcript])
def get_recording_transcripts(recording_id: str, latest: bool = False, current_user: schemas.User = Depends(get_current_user)):
    # Verify ownership
    RecordingService.get_recording_details(current_user.user_id, recording_id)
    return TranscriptService.get_transcripts_by_recording_id(recording_id, latest)

@router.post("/{recording_id}/summarize", status_code=status.HTTP_202_ACCEPTED)
def generate_summary(recording_id: str, request: schemas.SummaryRequest, background_tasks: BackgroundTasks, current_user: schemas.User = Depends(get_current_user)):
    # Verify ownership
    RecordingService.get_recording_details(current_user.user_id, recording_id)
    
    # Add to background tasks
    background_tasks.add_task(SummaryService.generate_summary, recording_id, request.summary_style)
    
    return {"message": "Summary generation started in background"}

@router.get("/{recording_id}/summaries", response_model=List[schemas.Summary])
def get_recording_summaries(recording_id: str, latest: bool = False, current_user: schemas.User = Depends(get_current_user)):
    # Verify ownership
    RecordingService.get_recording_details(current_user.user_id, recording_id)
    return SummaryService.get_summaries_by_recording_id(recording_id, latest)

@router.get("/{recording_id}/speakers", response_model=List[schemas.RecordingSpeaker])
def get_recording_speakers(recording_id: str, current_user: schemas.User = Depends(get_current_user)):
    return RecordingService.get_speakers(current_user.user_id, recording_id)

@router.patch("/{recording_id}/speakers/{speaker_label}", response_model=schemas.RecordingSpeaker)
def update_recording_speaker(
    recording_id: str, 
    speaker_label: str, 
    speaker_update: schemas.RecordingSpeakerUpdate,
    current_user: schemas.User = Depends(get_current_user)
):
    return RecordingService.update_speaker(current_user.user_id, recording_id, speaker_label, speaker_update)

@router.get("/{recording_id}/markers", response_model=List[schemas.Marker])
def get_recording_markers(recording_id: str, current_user: schemas.User = Depends(get_current_user)):
    # Verify access
    RecordingService.get_recording_details(current_user.user_id, recording_id) 
    return MarkerService.get_markers_by_recording_id(recording_id)

@router.post("/{recording_id}/markers", response_model=schemas.Marker, status_code=status.HTTP_201_CREATED)
def create_recording_marker(
    recording_id: str, 
    marker: schemas.MarkerCreate, 
    current_user: schemas.User = Depends(get_current_user)
):
    RecordingService.get_recording_details(current_user.user_id, recording_id)
    try:
        return MarkerService.create_marker(recording_id, marker)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/{recording_id}/tags", response_model=List[schemas.RecordingTag], status_code=status.HTTP_201_CREATED)
def add_recording_tags(
    recording_id: str, 
    tags: List[str], 
    current_user: schemas.User = Depends(get_current_user)
):
    RecordingService.get_recording_details(current_user.user_id, recording_id)
    return RecordingTagService.add_tags(recording_id, tags)

@router.delete("/{recording_id}/tags/{tag}", status_code=status.HTTP_204_NO_CONTENT)
def delete_recording_tag(
    recording_id: str, 
    tag: str, 
    current_user: schemas.User = Depends(get_current_user)
):
    RecordingService.get_recording_details(current_user.user_id, recording_id)
    RecordingTagService.delete_tag(recording_id, tag)
    return None

class ExportRequest(schemas.BaseModel):
    export_type: str

@router.post("/{recording_id}/export", response_model=schemas.ExportJob, status_code=status.HTTP_201_CREATED)
def create_export_job(
    recording_id: str, 
    request: ExportRequest, 
    current_user: schemas.User = Depends(get_current_user)
):
    RecordingService.get_recording_details(current_user.user_id, recording_id)
    try:
        return ExportJobService.create_export_job(current_user.user_id, recording_id, request.export_type)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))