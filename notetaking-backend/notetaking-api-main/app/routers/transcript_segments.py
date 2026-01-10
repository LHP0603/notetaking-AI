from fastapi import APIRouter, HTTPException, status
from typing import List

from app import schemas
from app.services.transcript_segment_service import TranscriptSegmentService

router = APIRouter(prefix="/transcripts", tags=["Transcript Segments"])

@router.get("/{transcript_id}/segments", response_model=List[schemas.TranscriptSegment])
def get_transcript_segments(transcript_id: str):
    return TranscriptSegmentService.get_segments_by_transcript_id(transcript_id)

@router.post("/{transcript_id}/segments", response_model=schemas.TranscriptSegment, status_code=status.HTTP_201_CREATED)
def create_transcript_segment(transcript_id: str, segment: schemas.TranscriptSegmentCreate):
    return TranscriptSegmentService.create_transcript_segment(transcript_id, segment)

@router.put("/{transcript_id}/segments/{segment_id}", response_model=schemas.TranscriptSegment)
def update_transcript_segment(transcript_id: str, segment_id: int, segment: schemas.TranscriptSegmentUpdate):
    updated_segment = TranscriptSegmentService.update_transcript_segment(transcript_id, segment_id, segment)
    if not updated_segment:
        raise HTTPException(status_code=404, detail="Segment not found")
    return updated_segment

@router.delete("/{transcript_id}/segments/{segment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_transcript_segment(transcript_id: str, segment_id: int):
    TranscriptSegmentService.delete_transcript_segment(transcript_id, segment_id)
    return None

@router.patch("/{transcript_id}/segments/{segment_id}", response_model=schemas.TranscriptSegment)
def patch_transcript_segment(transcript_id: str, segment_id: int, segment: schemas.TranscriptSegmentUpdate):
    # Logic: update content/speaker_label, set is_user_edited=true
    segment.is_user_edited = True
    updated_segment = TranscriptSegmentService.update_transcript_segment(transcript_id, segment_id, segment)
    if not updated_segment:
        raise HTTPException(status_code=404, detail="Segment not found")
    return updated_segment
