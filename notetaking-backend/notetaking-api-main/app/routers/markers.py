from fastapi import APIRouter, HTTPException, status, Query, Depends
from typing import List, Optional

from app import schemas
from app.services.marker_service import MarkerService
from app.services.recording_service import RecordingService
from app.auth import get_current_user, RoleChecker

router = APIRouter(prefix="/recordings", tags=["Markers"])


@router.get("/{recording_id}/markers", response_model=List[schemas.Marker])
def get_recording_markers(recording_id: str, current_user: schemas.User = Depends(get_current_user)):
    """Get all markers for a specific recording"""
    # Verify ownership
    recording = RecordingService.get_recording_details(current_user.user_id, recording_id)
    if not recording:
        raise HTTPException(status_code=404, detail="Recording not found")

    return MarkerService.get_markers_by_recording_id(recording_id)


@router.post("/{recording_id}/markers", response_model=schemas.Marker, status_code=status.HTTP_201_CREATED)
def create_recording_marker(recording_id: str, marker: schemas.MarkerCreate, current_user: schemas.User = Depends(get_current_user)):
    """Create a new marker for a recording"""
    # Verify ownership
    recording = RecordingService.get_recording_details(current_user.user_id, recording_id)
    if not recording:
        raise HTTPException(status_code=404, detail="Recording not found")

    # Validate time_seconds
    if marker.time_seconds < 0:
        raise HTTPException(status_code=400, detail="time_seconds must be non-negative")

    if marker.time_seconds > recording.duration_seconds:
        raise HTTPException(
            status_code=400,
            detail=f"time_seconds ({marker.time_seconds}) exceeds recording duration ({recording.duration_seconds})"
        )

    # Set recording_id from path
    marker.recording_id = recording_id
    return MarkerService.create_marker(marker)


@router.patch("/markers/{marker_id}", response_model=schemas.Marker)
def update_marker(marker_id: str, marker: schemas.MarkerUpdate, current_user: schemas.User = Depends(get_current_user)):
    """Update an existing marker"""
    # Get existing marker to validate
    existing_marker = MarkerService.get_marker_by_id(marker_id)
    if not existing_marker:
        raise HTTPException(status_code=404, detail="Marker not found")
    
    # Verify ownership of the recording
    recording = RecordingService.get_recording_details(current_user.user_id, existing_marker.recording_id)
    if not recording:
        raise HTTPException(status_code=404, detail="Recording not found")

    # If updating time_seconds, validate against recording duration
    if marker.time_seconds is not None:
        if marker.time_seconds < 0:
            raise HTTPException(status_code=400, detail="time_seconds must be non-negative")
        if marker.time_seconds > recording.duration_seconds:
            raise HTTPException(
                status_code=400,
                detail=f"time_seconds exceeds recording duration ({recording.duration_seconds})"
            )

    updated_marker = MarkerService.update_marker(marker_id, marker)
    if not updated_marker:
        raise HTTPException(status_code=404, detail="Marker not found")
    return updated_marker


@router.delete("/markers/{marker_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_marker(marker_id: str, current_user: schemas.User = Depends(get_current_user)):
    """Delete a marker"""
    existing_marker = MarkerService.get_marker_by_id(marker_id)
    if not existing_marker:
        raise HTTPException(status_code=404, detail="Marker not found")

    # Verify ownership
    recording = RecordingService.get_recording_details(current_user.user_id, existing_marker.recording_id)
    if not recording:
        raise HTTPException(status_code=403, detail="Access denied")

    MarkerService.delete_marker(marker_id)
    return None


# Optional: Get all markers (admin view)
@router.get("/markers", response_model=List[schemas.Marker], tags=["Markers"], dependencies=[Depends(RoleChecker([schemas.UserRole.ADMIN]))])
def get_all_markers():
    """Get all markers across all recordings (admin)"""
    return MarkerService.get_all_markers()
