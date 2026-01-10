from app.utils.database import supabase
from app import schemas
from typing import List, Optional
from app.utils.audit import create_audit_log

class SummaryService:
    @staticmethod
    def get_all_summaries() -> List[schemas.Summary]:
        response = supabase.table("summaries").select("*").execute()
        return response.data

    @staticmethod
    def get_summary_by_id(summary_id: str) -> Optional[schemas.Summary]:
        response = supabase.table("summaries").select("*").eq("summary_id", summary_id).execute()
        if response.data:
            return schemas.Summary(**response.data[0])
        return None

    @staticmethod
    def get_summaries_by_recording_id(recording_id: str, latest: bool = False) -> List[schemas.Summary]:
        query = supabase.table("summaries").select("*").eq("recording_id", recording_id)
        if latest:
            query = query.eq("is_latest", True)
        
        # Order by version_no descending
        query = query.order("version_no", desc=True)
        
        response = query.execute()
        return response.data

    @staticmethod
    def create_summary(summary: schemas.SummaryCreate) -> schemas.Summary:
        data = summary.model_dump(mode='json', exclude_unset=True)
        response = supabase.table("summaries").insert(data).execute()
        return response.data[0]

    @staticmethod
    def update_summary(summary_id: str, summary: schemas.SummaryUpdate) -> Optional[schemas.Summary]:
        # 1. Get existing summary to find recording_id
        # Note: get_summary_by_id returns a dict from supabase, despite the type hint
        existing_summary = SummaryService.get_summary_by_id(summary_id)
        if not existing_summary:
            return None
        
        recording_id = existing_summary.recording_id
        
        # 2. Handle is_latest logic
        if summary.is_latest:
             supabase.table("summaries").update({"is_latest": False}).eq("recording_id", recording_id).execute()

        # 3. Prepare update data
        data = summary.model_dump(mode='json', exclude_unset=True)
        
        # 4. Update
        response = supabase.table("summaries").update(data).eq("summary_id", summary_id).execute()
        if response.data:
            return response.data[0]
        return None

    @staticmethod
    def delete_summary(summary_id: str) -> None:
        supabase.table("summaries").delete().eq("summary_id", summary_id).execute()

    @staticmethod
    def generate_summary(recording_id: str, summary_style: str = "MEETING") -> schemas.Summary:
        from app.services.transcript_service import TranscriptService
        from app.utils.transcript_utils import clean_transcript_for_summary
        from app.utils.summarizer import generate_summary_gemini
        
        # 1. Get active transcript
        active_transcripts = TranscriptService.get_transcripts_by_recording_id(recording_id, latest=True)
        if not active_transcripts:
            raise ValueError("No active transcript found for this recording.")
        
        active_transcript = active_transcripts[0]


        
        # 2. Get transcript details (with segments)
        transcript_detail = TranscriptService.get_transcript_by_id(active_transcript['transcript_id'])
        if not transcript_detail:
             raise ValueError("Failed to retrieve transcript details.")

        # 3. Prepare text for AI
        cleaned_text = clean_transcript_for_summary(transcript_detail.segments)
        
        # 4. Call Gemini
        summary_content = generate_summary_gemini(cleaned_text, summary_style)
        
        # 5. Handle Versioning
        # Get current max version
        res = supabase.table("summaries").select("version_no").eq("recording_id", recording_id).order("version_no", desc=True).limit(1).execute()
        current_version = 0
        if res.data:
            current_version = res.data[0]['version_no']
        
        new_version = current_version + 1
        
        # Set old summaries to is_latest=False
        supabase.table("summaries").update({"is_latest": False}).eq("recording_id", recording_id).execute()
        
        # 6. Insert new summary
        new_summary_data = {
            "recording_id": recording_id,
            "version_no": new_version,
            "type": "AI_GENERATED",
            "summary_style": summary_style,
            "content_structure": summary_content,
            "is_latest": True,          
        }
        
        response = supabase.table("summaries").insert(new_summary_data).execute()
        new_summary = response.data[0]

        # 7. Log AI Usage
        try:
            ai_usage_log = {
                "recording_id": recording_id,
                "action_type": "SUMMARIZE"
            }
            supabase.table("ai_usage_logs").insert(ai_usage_log).execute()
        except Exception as e:
            print(f"Error creating AI usage log: {e}")

        # 8. Log Audit
        # 8. Log Audit
        create_audit_log(
            user_id=None, # generate_summary doesn't take user_id. The previous code didn't pass it either.
            action_type="GENERATE_SUMMARY",
            resource_type="SUMMARY",
            resource_id=new_summary['summary_id'],
            status="SUCCESS",
            details=f"Generated summary for recording {recording_id}"
        )

        return new_summary
