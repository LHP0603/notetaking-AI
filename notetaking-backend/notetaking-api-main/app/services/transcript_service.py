from app.utils.database import supabase
from app import schemas
from typing import List, Optional
from fastapi import HTTPException

class TranscriptService:
    @staticmethod
    def get_all_transcripts() -> List[schemas.Transcript]:
        response = supabase.table("transcripts").select("*").execute()
        return response.data

    @staticmethod
    def get_transcript_by_id(transcript_id: str) -> Optional[schemas.TranscriptDetail]:
        response = supabase.table("transcripts").select("*").eq("transcript_id", transcript_id).execute()
        if not response.data:
            return None
            
        transcript_data = response.data[0]
        
        # Fetch segments
        segments_response = supabase.table("transcript_segments").select("*").eq("transcript_id", transcript_id).order("sequence").execute()
        segments_data = segments_response.data
        
        return schemas.TranscriptDetail(**transcript_data, segments=segments_data)

    @staticmethod
    def create_transcript(transcript: schemas.TranscriptCreate) -> schemas.Transcript:
        data = transcript.model_dump(mode='json', exclude_unset=True)
        response = supabase.table("transcripts").insert(data).execute()
        return response.data[0]

    @staticmethod
    def update_transcript(user_id: str, transcript_id: str, transcript: schemas.TranscriptUpdate) -> Optional[schemas.Transcript]:
        # If setting to active, we need to deactivate others
        if transcript.is_active is True:
            # Get recording_id of this transcript
            res = supabase.table("transcripts").select("recording_id").eq("transcript_id", transcript_id).execute()
            if res.data:
                recording_id = res.data[0]['recording_id']
                # Deactivate all transcripts for this recording
                supabase.table("transcripts").update({"is_active": False}).eq("recording_id", recording_id).execute()
            else:
                return None  # Transcript not found

        data = transcript.model_dump(mode='json', exclude_unset=True)
        response = supabase.table("transcripts").update(data).eq("transcript_id", transcript_id).execute()
        if response.data:
            from app.utils.audit import create_audit_log
            create_audit_log(
                user_id=user_id,
                action_type="UPDATE_TRANSCRIPT",
                resource_type="TRANSCRIPT",
                resource_id=transcript_id,
                status="SUCCESS",
                details=f"Updated usage/content"
            )
            return response.data[0]
        return None

    @staticmethod
    def delete_transcript(transcript_id: str) -> None:
        supabase.table("transcripts").delete().eq("transcript_id", transcript_id).execute()

    @staticmethod
    def get_transcripts_by_recording_id(recording_id: str, latest: bool = False) -> List[schemas.Transcript]:
        try:
            query = supabase.table("transcripts").select("*").eq("recording_id", recording_id)
            if latest:
                query = query.eq("is_active", True)
            
            # Order by version_no descending to show latest first (optional but good UX)
            query = query.order("version_no", desc=True)
            
            response = query.execute()
            return response.data
        except Exception as e:
            # Log the error and return empty list instead of crashing
            print(f"Error fetching transcripts for recording {recording_id}: {e}")
            raise HTTPException(
                status_code=503,
                detail=f"Database connection error: {str(e)}"
            )
