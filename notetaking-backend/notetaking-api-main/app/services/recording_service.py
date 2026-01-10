from app.utils.database import supabase
from app import schemas
from app.utils import transcriber
from typing import List, Optional, Dict, Any
import json
import os
from datetime import datetime
from fastapi import HTTPException
from app.utils.audit import create_audit_log
from postgrest.exceptions import APIError

class RecordingService:
    @staticmethod
    def get_all_recordings() -> List[schemas.Recording]:
        response = supabase.table("recordings").select("*").execute()
        return response.data

    @staticmethod
    def get_filtered_recordings(
        user_id: str,
        folder_id: Optional[str] = None,
        is_trashed: Optional[bool] = False,
        search_query: Optional[str] = None,
        tag: Optional[str] = None,
        page: int = 1,
        page_size: int = 10
    ) -> Dict[str, Any]:
        # Base query
        if tag:
            # Inner join to filter by tag
            tag = tag.strip().lower()
            query = supabase.table("recordings").select("*, recording_tags!inner(tag)", count="exact")
            query = query.eq("recording_tags.tag", tag)
        else:
            query = supabase.table("recordings").select("*", count="exact")

        # Filters
        query = query.eq("user_id", user_id)
        
        if is_trashed is not None:
            query = query.eq("is_trashed", is_trashed)
            
        if folder_id:
            query = query.eq("folder_id", folder_id)
            
        if search_query:
            query = query.ilike("title", f"%{search_query}%")
            
        # Pagination
        start = (page - 1) * page_size
        end = start + page_size - 1
        
        # Order and execute
        query = query.range(start, end).order("created_at", desc=True)
        response = query.execute()
        
        return {
            "data": response.data,
            "total": response.count
        }

    @staticmethod
    def get_recordings_by_user_id(user_id: str) -> List[schemas.Recording]:
        response = supabase.table("recordings").select("*").eq("user_id", user_id).order("created_at", desc=True).execute()
        return response.data

    @staticmethod
    def get_recording_by_id(recording_id: str) -> Optional[schemas.Recording]:
        response = supabase.table("recordings").select("*").eq("recording_id", recording_id).execute()
        if response.data:
            return schemas.Recording(**response.data[0])
        return None

    @staticmethod
    def get_recording_details(user_id: str, recording_id: str) -> Optional[schemas.RecordingDetail]:
        # 1. Fetch recording
        response = supabase.table("recordings").select("*").eq("recording_id", recording_id).execute()
        if not response.data:
            return None
        
        recording = response.data[0]
        
        # 2. Check ownership
        if recording['user_id'] != user_id:
            raise HTTPException(status_code=403, detail="Not authorized to access this recording")

        # 3. Generate Signed URL
        audio_url = None
        if recording.get('file_path'):
            try:
                # Assuming bucket name is 'recordings' as seen in transcribe_recording
                signed_url_response = supabase.storage.from_("recordings").create_signed_url(recording['file_path'], 60 * 60) # 1 hour
                if signed_url_response:
                    # Supabase python client returns a string or a dict usually? 
                    # create_signed_url usually returns a dict with 'signedURL' or string in some versions.
                    # Commonly it returns a string in some implementations or {'signedURL': '...'} in others.
                    # Looking at supabase-py storage-py logic: it returns dictionary usually if not raw.
                    # Actually storage-py returns the URL string in newer versions or a dict.
                    # Let's handle generic case or check context. 
                    # The transcribe method used download(). 
                    # Let's assume it returns a dict or check usage.
                    # If create_signed_url returns a dict:
                    if isinstance(signed_url_response, dict) and 'signedURL' in signed_url_response:
                         audio_url = signed_url_response['signedURL']
                    elif isinstance(signed_url_response, str):
                         audio_url = signed_url_response
            except Exception as e:
                print(f"Error generating signed URL: {e}")

        # 4. Get counts
        transcript_count_res = supabase.table("transcripts").select("transcript_id", count="exact").eq("recording_id", recording_id).execute()
        transcript_count = transcript_count_res.count or 0

        summary_count_res = supabase.table("summaries").select("summary_id", count="exact").eq("recording_id", recording_id).execute()
        summary_count = summary_count_res.count or 0

        # 5. Construct response
        # schemas.RecordingDetail expects fields from Recording + extra
        return schemas.RecordingDetail(
            **recording,
            audio_url=audio_url,
            transcript_count=transcript_count,
            summary_count=summary_count
        )


    @staticmethod
    def create_recording(recording: schemas.RecordingCreate) -> schemas.Recording:
        data = recording.model_dump(mode='json', exclude_unset=True)
        response = supabase.table("recordings").insert(data).execute()
        return response.data[0]

    @staticmethod
    def update_recording(recording_id: str, recording: schemas.RecordingUpdate) -> Optional[schemas.Recording]:
        data = recording.model_dump(mode='json', exclude_unset=True)
        response = supabase.table("recordings").update(data).eq("recording_id", recording_id).execute()
        if response.data:
            return response.data[0]
        return None

    @staticmethod
    def update_recording_details(user_id: str, recording_id: str, update_data: schemas.RecordingUserUpdate) -> schemas.Recording:
        # 1. Fetch recording, check ownership
        response = supabase.table("recordings").select("*").eq("recording_id", recording_id).single().execute()
        if not response.data:
             raise HTTPException(status_code=404, detail="Recording not found")
        recording = response.data

        if recording['user_id'] != user_id:
             raise HTTPException(status_code=403, detail="Not authorized to update this recording")

        # 2. Prepare update payload
        data = update_data.model_dump(exclude_unset=True)
        if not data:
             return schemas.Recording(**recording)

        # 3. Update in Supabase
        update_response = supabase.table("recordings").update(data).eq("recording_id", recording_id).execute()
        updated_recording = update_response.data[0]

        # 4. Audit Log
        changes = []
        if 'title' in data and data['title'] != recording['title']:
             changes.append(f"Title: {recording['title']} -> {data['title']}")
        
        if 'folder_id' in data and data['folder_id'] != recording['folder_id']:
             old_f = recording.get('folder_id') or 'Root'
             new_f = data.get('folder_id') or 'Root'
             changes.append(f"Folder: {old_f} -> {new_f}")

        if 'is_pinned' in data and data['is_pinned'] != recording['is_pinned']:
             changes.append(f"Pinned: {data['is_pinned']}")

        if changes:
             create_audit_log(
                 user_id=user_id,
                 action_type="UPDATE_RECORDING",
                 resource_type="RECORDING",
                 resource_id=recording_id,
                 status="SUCCESS",
                 details=", ".join(changes)
             )

        return schemas.Recording(**updated_recording)

    @staticmethod
    def soft_delete_recording(user_id: str, recording_id: str) -> None:
        # 1. Fetch recording, check ownership
        response = supabase.table("recordings").select("user_id").eq("recording_id", recording_id).single().execute()
        if not response.data:
             raise HTTPException(status_code=404, detail="Recording not found")
        
        if response.data['user_id'] != user_id:
             raise HTTPException(status_code=403, detail="Not authorized to delete this recording")

        # 2. Update is_trashed
        supabase.table("recordings").update({
            "is_trashed": True, 
            "deleted_at": datetime.now().isoformat()
        }).eq("recording_id", recording_id).execute()

        # 3. Audit Log
        create_audit_log(
            user_id=user_id,
            action_type="SOFT_DELETE_RECORDING",
            resource_type="RECORDING",
            resource_id=recording_id,
            status="SUCCESS"
        )

    @staticmethod
    def restore_recording(user_id: str, recording_id: str) -> schemas.Recording:
        # 1. Fetch recording, check ownership and is_trashed status
        response = supabase.table("recordings").select("*").eq("recording_id", recording_id).single().execute()
        if not response.data:
             raise HTTPException(status_code=404, detail="Recording not found")
        
        recording = response.data
        if recording['user_id'] != user_id:
             raise HTTPException(status_code=403, detail="Not authorized to restore this recording")
        
        if not recording.get('is_trashed'):
             # If not trashed, just return it or raise error? Spec applies to restoring from trash. 
             # Let's just return current state if already restored or error. 
             # Usually idempotent is better.
             pass

        # 2. Update is_trashed
        update_response = supabase.table("recordings").update({
            "is_trashed": False, 
            "deleted_at": None
        }).eq("recording_id", recording_id).execute()
        
        restored_recording = update_response.data[0]

        # 3. Audit Log
        create_audit_log(
            user_id=user_id,
            action_type="RESTORE_RECORDING",
            resource_type="RECORDING",
            resource_id=recording_id,
            status="SUCCESS"
        )

        return schemas.Recording(**restored_recording)

    @staticmethod
    def hard_delete_recording(user_id: str, recording_id: str) -> None:
        # 1. Fetch recording, check ownership
        response = supabase.table("recordings").select("*").eq("recording_id", recording_id).single().execute()
        if not response.data:
             raise HTTPException(status_code=404, detail="Recording not found")
        
        recording = response.data
        if recording['user_id'] != user_id:
             raise HTTPException(status_code=403, detail="Not authorized to delete this recording")

        # 2. Delete file from Storage
        if recording.get('file_path'):
             try:
                 supabase.storage.from_("recordings").remove([recording['file_path']])
             except Exception as e:
                 print(f"Error removing file from storage: {e}")

        # 3. Delete RECORDING (Cascades to other tables)
        supabase.table("recordings").delete().eq("recording_id", recording_id).execute()

        # 5. Update User Storage
        # We need to subtract file_size_mb from user's storage_used_mb
        # Handle stack depth errors from recursive RLS policies
        file_size_mb = recording.get('file_size_mb') or 0
        if file_size_mb > 0:
             try:
                 # Fetch current user storage to be safe or use RPC decrement? 
                 # Simple approach: fetch user, substract, update.
                 user_res = supabase.table("users").select("storage_used_mb").eq("user_id", user_id).single().execute()
                 if user_res.data:
                     current_storage = user_res.data['storage_used_mb'] or 0
                     new_storage = max(0, current_storage - file_size_mb)
                     supabase.table("users").update({"storage_used_mb": new_storage}).eq("user_id", user_id).execute()
             except APIError as e:
                 # Check if it's a stack depth error
                 error_str = str(e)
                 if any(keyword in error_str.lower() for keyword in ["stack depth", "54001", "max_stack_depth"]):
                     # Log warning but allow deletion to proceed
                     print(f"Warning: Could not update user storage due to stack depth error. Storage tracking may be inaccurate.")
                 else:
                     # Re-raise if it's a different error
                     raise
             except Exception as e:
                 # For other errors, check if it's stack depth related
                 error_str = str(e)
                 if any(keyword in error_str.lower() for keyword in ["stack depth", "54001", "max_stack_depth"]):
                     print(f"Warning: Could not update user storage due to stack depth error. Storage tracking may be inaccurate.")
                 # For other errors, log but don't fail deletion
                 else:
                     print(f"Warning: Could not update user storage: {str(e)}")

        # 6. Audit Log
        create_audit_log(
            user_id=user_id,
            action_type="HARD_DELETE_RECORDING",
            resource_type="RECORDING",
            resource_id=recording_id,
            status="SUCCESS"
        )

    @staticmethod
    def transcribe_recording(recording_id: str) -> Optional[schemas.Transcript]:
        # 1. Fetch recording
        recording_response = supabase.table("recordings").select("*").eq("recording_id", recording_id).execute()
        if not recording_response.data:
            return None
        recording = recording_response.data[0]

        # 2. Check status
        if recording['status'] != 'PROCESSED':
            raise ValueError("Recording is not processed yet.")

        # 3. Read audio file
        file_path = recording['file_path']
        try:
            audio_bytes = supabase.storage.from_("recordings").download(file_path)
        except Exception as e:
             raise FileNotFoundError(f"Audio file not found in storage at {file_path}: {str(e)}")
        
        file_extension = file_path.split('.')[-1]

        # 4. Call transcriber
        try:
            transcript_json_str = transcriber.transcribe(audio_bytes, file_extension)
            transcript_data = json.loads(transcript_json_str)
        except Exception as e:
            raise RuntimeError(f"Transcription failed: {str(e)}")

        # 5. Determine version_no
        # Get max version_no for this recording
        transcripts_response = supabase.table("transcripts").select("version_no").eq("recording_id", recording_id).order("version_no", desc=True).limit(1).execute()
        current_version = 0
        if transcripts_response.data:
            current_version = transcripts_response.data[0]['version_no']
        new_version = current_version + 1

        # 6. Insert into TRANSCRIPTS
        supabase.table("transcripts").update({"is_active": False}).eq("recording_id", recording_id).execute()

        new_transcript_data = {
            "recording_id": recording_id,
            "version_no": new_version,
            "type": "AI_ORIGINAL",
            "language": "vi", # Default or detect? The prompt implies it handles it, but schema needs it. Let's assume 'vi' or 'en' or null.
            "is_active": True
        }
        transcript_insert_response = supabase.table("transcripts").insert(new_transcript_data).execute()
        new_transcript = transcript_insert_response.data[0]
        transcript_id = new_transcript['transcript_id']

        # 7. Insert into TRANSCRIPT_SEGMENTS
        segments_to_insert = []
        speakers_set = set()
        
        for idx, segment in enumerate(transcript_data):
            segments_to_insert.append({
                "transcript_id": transcript_id,
                "sequence": idx + 1,
                "start_time": segment['start_time'],
                "end_time": segment['end_time'],
                "content": segment['content'],
                "speaker_label": segment['speaker_label'],
                "confidence": 1.0 # Gemini doesn't return confidence per segment in this prompt yet
            })
            speakers_set.add(segment['speaker_label'])

        if segments_to_insert:
            supabase.table("transcript_segments").insert(segments_to_insert).execute()

        # 8. Insert into RECORDING_SPEAKERS
        # Check existing speakers for this recording
        existing_speakers_response = supabase.table("recording_speakers").select("speaker_label").eq("recording_id", recording_id).execute()
        existing_labels = {s['speaker_label'] for s in existing_speakers_response.data}
        
        new_speakers = []
        for label in speakers_set:
            if label not in existing_labels:
                new_speakers.append({
                    "recording_id": recording_id,
                    "speaker_label": label,
                    "display_name": label # Initial display name same as label
                })
        
        if new_speakers:
            supabase.table("recording_speakers").insert(new_speakers).execute()

        # 9. Insert into AI_USAGE_LOGS
        try:
            ai_usage_log = {
                "user_id": recording['user_id'],
                "recording_id": recording_id,
                "action_type": "TRANSCRIBE"
            }
            supabase.table("ai_usage_logs").insert(ai_usage_log).execute()
        except Exception as e:
            # Log error but don't fail transcription if AI usage logging fails
            # This can happen due to RLS policy recursion or stack depth limits
            print(f"Error creating AI usage log: {e}")

        return new_transcript

    @staticmethod
    def create_recording_metadata(user_id: str, request: schemas.RecordingInitRequest) -> dict:
        # 1. Get User and Tier info
        # Handle stack depth errors from recursive RLS policies
        tier_id = None
        current_storage = 0.0
        try:
            user_response = supabase.table("users").select("tier_id, storage_used_mb").eq("user_id", user_id).single().execute()
            if user_response.data:
                user_data = user_response.data
                tier_id = user_data.get('tier_id')
                current_storage = user_data.get('storage_used_mb') or 0.0
        except APIError as e:
            # Check if it's a stack depth error
            error_str = str(e)
            if any(keyword in error_str.lower() for keyword in ["stack depth", "54001", "max_stack_depth"]):
                # Use default values when stack depth error occurs
                tier_id = None
                current_storage = 0.0
            else:
                # Re-raise if it's a different error
                raise
        except Exception as e:
            # For other errors, check if it's stack depth related
            error_str = str(e)
            if any(keyword in error_str.lower() for keyword in ["stack depth", "54001", "max_stack_depth"]):
                tier_id = None
                current_storage = 0.0
            else:
                raise HTTPException(status_code=404, detail="User not found")

        tier_data = None
        if tier_id:
            try:
                tier_response = supabase.table("tiers").select("*").eq("tier_id", tier_id).single().execute()
                tier_data = tier_response.data
            except Exception:
                # If tier query fails, continue without tier data
                tier_data = None

        # 2. Check Folder (if provided)
        if request.folder_id:
            folder_res = supabase.table("folders").select("user_id").eq("folder_id", request.folder_id).execute()
            if not folder_res.data:
                raise HTTPException(status_code=404, detail="Folder not found")
            if folder_res.data[0]['user_id'] != user_id:
                raise HTTPException(status_code=403, detail="Not authorized to use this folder")

        # 3. Check Quota (only if tier is assigned)
        if tier_data:
            # 3.a Max recordings
            count_response = supabase.table("recordings").select("recording_id", count="exact").eq("user_id", user_id).execute()
            current_recording_count = count_response.count if count_response.count is not None else 0
            
            if tier_data['max_recordings'] is not None and current_recording_count >= tier_data['max_recordings']:
                 raise HTTPException(status_code=403, detail="Max recordings quota exceeded")

            # 3.b Storage (Just check if already over limit, exact check comes at upload complete)
            if tier_data['max_storage_mb'] is not None and current_storage >= tier_data['max_storage_mb']:
                 raise HTTPException(status_code=403, detail="Storage quota exceeded")

        # 4. Insert Recording
        new_recording_data = {
            "user_id": user_id,
            "folder_id": request.folder_id,
            "title": request.title,
            "source_type": request.source_type.value if hasattr(request.source_type, 'value') else request.source_type,
            "status": "UPLOADING",
            "is_trashed": False,
            "is_pinned": False,
            "deleted_at": None
        }
        
        try:
            insert_response = supabase.table("recordings").insert(new_recording_data).execute()
            if not insert_response.data:
                raise HTTPException(status_code=500, detail="Failed to create recording record")
            recording = insert_response.data[0]
        except Exception as e:
            if "foreign key constraint" in str(e).lower():
                 raise HTTPException(status_code=404, detail="Referenced record not found (check folder_id)")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

        # 5. Create Audit Log
        create_audit_log(
            user_id=user_id,
            action_type="CREATE_RECORDING",
            resource_type="RECORDING",
            resource_id=recording['recording_id'],
            status="SUCCESS"
        )

        return recording

    @staticmethod
    def complete_upload_recording(user_id: str, recording_id: str, request: schemas.RecordingUploadCompleteRequest) -> schemas.Recording:
        # 1. Fetch Recording and Validate
        recording_response = supabase.table("recordings").select("*").eq("recording_id", recording_id).single().execute()
        if not recording_response.data:
             raise HTTPException(status_code=404, detail="Recording not found")
        recording = recording_response.data

        if recording['user_id'] != user_id:
             raise HTTPException(status_code=403, detail="Not authorized to access this recording")
        
        if recording['status'] != 'UPLOADING':
             raise HTTPException(status_code=400, detail="Recording is not in UPLOADING state")

        # 2. Validate Quota (Size and Duration) with User's Tier (only if tier is assigned)
        # Handle stack depth errors from recursive RLS policies
        tier_id = None
        current_storage = 0.0
        try:
            user_response = supabase.table("users").select("tier_id, storage_used_mb").eq("user_id", user_id).single().execute()
            if user_response.data:
                user_data = user_response.data
                tier_id = user_data.get('tier_id')
                current_storage = user_data.get('storage_used_mb') or 0.0
        except APIError as e:
            # Check if it's a stack depth error
            error_str = str(e)
            if any(keyword in error_str.lower() for keyword in ["stack depth", "54001", "max_stack_depth"]):
                # Use default values when stack depth error occurs
                tier_id = None
                current_storage = 0.0
            else:
                # Re-raise if it's a different error
                raise
        except Exception as e:
            # For other errors, check if it's stack depth related
            error_str = str(e)
            if any(keyword in error_str.lower() for keyword in ["stack depth", "54001", "max_stack_depth"]):
                tier_id = None
                current_storage = 0.0
            else:
                # For non-stack-depth errors, use defaults and continue
                tier_id = None
                current_storage = 0.0

        tier_data = None
        if tier_id:
            try:
                tier_response = supabase.table("tiers").select("*").eq("tier_id", tier_id).single().execute()
                tier_data = tier_response.data
            except Exception:
                # If tier query fails, continue without tier data
                tier_data = None

        new_storage = current_storage + request.file_size_mb
        
        # Only check tier limits if tier is assigned
        if tier_data:
            if tier_data['max_storage_mb'] is not None and new_storage > tier_data['max_storage_mb']:
                 raise HTTPException(status_code=403, detail=f"File size exceeds storage quota. Limit: {tier_data['max_storage_mb']}MB, Used: {current_storage}MB, File: {request.file_size_mb}MB")
            
            if tier_data['max_duration_per_recording_sec'] is not None and request.duration_seconds > tier_data['max_duration_per_recording_sec']:
                 raise HTTPException(status_code=403, detail=f"Duration exceeds tier limit per recording: {tier_data['max_duration_per_recording_sec']}s")

        # 3. Update Recording
        update_data = {
            "file_path": request.file_path,
            "file_size_mb": request.file_size_mb,
            "duration_seconds": request.duration_seconds,
            "original_file_name": request.original_file_name,
            "status": "PROCESSED"
        }
        update_response = supabase.table("recordings").update(update_data).eq("recording_id", recording_id).execute()
        updated_recording = update_response.data[0]

        # 4. Update User Storage
        # Handle stack depth errors when updating storage
        try:
            supabase.table("users").update({"storage_used_mb": new_storage}).eq("user_id", user_id).execute()
        except APIError as e:
            # Check if it's a stack depth error
            error_str = str(e)
            if any(keyword in error_str.lower() for keyword in ["stack depth", "54001", "max_stack_depth"]):
                # Log warning but don't fail the operation
                print(f"Warning: Could not update user storage due to stack depth error. Storage tracking may be inaccurate.")
            else:
                # Re-raise if it's a different error
                raise
        except Exception as e:
            # For other errors, check if it's stack depth related
            error_str = str(e)
            if any(keyword in error_str.lower() for keyword in ["stack depth", "54001", "max_stack_depth"]):
                print(f"Warning: Could not update user storage due to stack depth error. Storage tracking may be inaccurate.")
            # For other errors, log but don't fail
            else:
                print(f"Warning: Could not update user storage: {str(e)}")

        # 5. Audit Log
        create_audit_log(
            user_id=user_id,
            action_type="UPLOAD",
            resource_type="RECORDING",
            resource_id=recording_id,
            status="SUCCESS",
            details=f"Uploaded {request.file_size_mb}MB"
        )

        return updated_recording

    @staticmethod
    def get_speakers(user_id: str, recording_id: str) -> List[schemas.RecordingSpeaker]:
        # 1. Check ownership
        response = supabase.table("recordings").select("user_id").eq("recording_id", recording_id).single().execute()
        if not response.data:
             raise HTTPException(status_code=404, detail="Recording not found")
        
        if response.data['user_id'] != user_id:
             raise HTTPException(status_code=403, detail="Not authorized to access this recording")

        # 2. Fetch speakers
        speakers_response = supabase.table("recording_speakers").select("*").eq("recording_id", recording_id).execute()
        return speakers_response.data

    @staticmethod
    def update_speaker(user_id: str, recording_id: str, speaker_label: str, update_data: schemas.RecordingSpeakerUpdate) -> schemas.RecordingSpeaker:
        # 1. Check ownership
        response = supabase.table("recordings").select("user_id").eq("recording_id", recording_id).single().execute()
        if not response.data:
             raise HTTPException(status_code=404, detail="Recording not found")
        
        if response.data['user_id'] != user_id:
             raise HTTPException(status_code=403, detail="Not authorized to update this recording")

        # 2. Update speaker
        data = update_data.model_dump(exclude_unset=True)
        if not data:
             # Just fetch and return if no updates
             speaker_res = supabase.table("recording_speakers").select("*").eq("recording_id", recording_id).eq("speaker_label", speaker_label).single().execute()
             if not speaker_res.data:
                 raise HTTPException(status_code=404, detail="Speaker not found")
             return speaker_res.data

        update_response = supabase.table("recording_speakers").update(data).eq("recording_id", recording_id).eq("speaker_label", speaker_label).execute()
        
        if not update_response.data:
             raise HTTPException(status_code=404, detail="Speaker not found")

        return update_response.data[0]
