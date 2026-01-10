from app.utils.database import supabase
from app import schemas
from typing import List, Optional
from app.utils.audit import create_audit_log

class TranscriptSegmentService:
    @staticmethod
    def get_segments_by_transcript_id(transcript_id: str) -> List[schemas.TranscriptSegment]:
        response = supabase.table("transcript_segments").select("*").eq("transcript_id", transcript_id).order("start_time").execute()
        return response.data

    @staticmethod
    def create_transcript_segment(transcript_id: str, segment: schemas.TranscriptSegmentCreate) -> schemas.TranscriptSegment:
        data = segment.model_dump(mode='json', exclude_unset=True)
        data["transcript_id"] = transcript_id
        response = supabase.table("transcript_segments").insert(data).execute()
        return schemas.TranscriptSegment(**response.data[0])

    @staticmethod
    def update_transcript_segment(transcript_id: str, segment_id: int, segment: schemas.TranscriptSegmentUpdate) -> Optional[schemas.TranscriptSegment]:
        data = segment.model_dump(mode='json', exclude_unset=True)
        response = supabase.table("transcript_segments").update(data).eq("transcript_id", transcript_id).eq("segment_id", segment_id).execute()
        if response.data:
            # Create audit log
            # Create audit log
            # Note: We don't have user_id here, so it will be None.
            create_audit_log(
                user_id=None,
                action_type="UPDATE_TRANSCRIPT_SEGMENT",
                resource_type="TRANSCRIPT_SEGMENT",
                resource_id=str(segment_id),
                status="SUCCESS",
                details=f"Updated segment {segment_id} in transcript {transcript_id}"
            )

            return schemas.TranscriptSegment(**response.data[0])
        return None

    @staticmethod
    def delete_transcript_segment(transcript_id: str, segment_id: int) -> None:
        supabase.table("transcript_segments").delete().eq("transcript_id", transcript_id).eq("segment_id", segment_id).execute()
