from app.utils.database import supabase
from app import schemas
from typing import List, Optional
from datetime import datetime, timedelta
import os


class ExportJobService:
    @staticmethod
    def get_all_export_jobs() -> List[schemas.ExportJob]:
        response = supabase.table("export_jobs") \
            .select("*") \
            .order("created_at", desc=True) \
            .execute()
        return response.data

    @staticmethod
    def get_exports_by_recording_id(recording_id: str) -> List[schemas.ExportJob]:
        """Get all export jobs for a specific recording"""
        response = supabase.table("export_jobs") \
            .select("*") \
            .eq("recording_id", recording_id) \
            .order("created_at", desc=True) \
            .execute()
        return response.data

    @staticmethod
    def get_export_job_by_id(export_id: str) -> Optional[schemas.ExportJob]:
        response = supabase.table("export_jobs") \
            .select("*") \
            .eq("export_id", export_id) \
            .execute()
        if response.data:
            return schemas.ExportJob(**response.data[0])
        return None

    @staticmethod
    def create_export_job(user_id: str, recording_id: str, export_type: str) -> schemas.ExportJob:
        # Validate recording ownership? Logic says "Insert EXPORT_JOBS".
        # Assume caller validates or we do it here.
        # Let's do a quick ownership check to be safe.
        rec = supabase.table("recordings").select("user_id").eq("recording_id", recording_id).single().execute()
        if not rec.data:
             raise ValueError("Recording not found")
        if rec.data['user_id'] != user_id:
             raise ValueError("Not authorized")

        new_job = {
            "user_id": user_id,
            "recording_id": recording_id,
            "export_type": export_type,
            "status": "PENDING"
        }
        response = supabase.table("export_jobs").insert(new_job).execute()
        return schemas.ExportJob(**response.data[0])

    # update and delete can remain valid for internal/admin use or if user cancels.
    @staticmethod
    def update_export_job(export_id: str, job: schemas.ExportJobUpdate) -> Optional[schemas.ExportJob]:
        data = job.model_dump(mode='json', exclude_unset=True)
        response = supabase.table("export_jobs") \
            .update(data) \
            .eq("export_id", export_id) \
            .execute()
        if response.data:
            return schemas.ExportJob(**response.data[0])
        return None

    @staticmethod
    def delete_export_job(export_id: str) -> None:
        supabase.table("export_jobs").delete().eq("export_id", export_id).execute()

    @staticmethod
    def get_download_url(file_path: str, expires_in: int = 3600) -> Optional[str]:
        """
        Generate a signed URL for downloading the export file.
        expires_in: seconds until URL expires (default 1 hour)
        """
        try:
            response = supabase.storage.from_("exports").create_signed_url(
                file_path,
                expires_in=expires_in
            )
            return response.get('signedURL')
        except Exception as e:
            print(f"Error generating signed URL: {e}")
            return None

    @staticmethod
    def delete_export_file(file_path: str) -> None:
        """Delete export file from storage"""
        try:
            supabase.storage.from_("exports").remove([file_path])
        except Exception as e:
            print(f"Error deleting file from storage: {e}")
            raise

    @staticmethod
    def process_export_job(export_id: str) -> None:
        """
        Background task to process export job.
        This would typically be handled by a separate worker/edge function.
        """
        from app.utils.export_processor import ExportProcessor

        try:
            print(f"!!! STARTING EXPORT JOB {export_id} !!!")
            # Update status to PROCESSING
            ExportJobService.update_export_job(
                export_id,
                schemas.ExportJobUpdate(status=schemas.ExportStatus.PROCESSING)
            )
            print(f"!!! STATUS UPDATED TO PROCESSING {export_id} !!!")

            # Get job details
            job = ExportJobService.get_export_job_by_id(export_id)
            if not job:
                print(f"!!! JOB NOT FOUND {export_id} !!!")
                return

            # Process export based on type
            print(f"!!! INITIALIZING PROCESSOR FOR {export_id} !!!")
            processor = ExportProcessor(job)
            print(f"!!! PROCESSING START {export_id} !!!")
            file_path = processor.process()
            print(f"!!! PROCESSING COMPLETE. FILE: {file_path} !!!")

            # Update job with result
            ExportJobService.update_export_job(
                export_id,
                schemas.ExportJobUpdate(
                    status=schemas.ExportStatus.DONE,
                    file_path=file_path,
                    completed_at=datetime.utcnow()
                )
            )
            print(f"!!! JOB DONE {export_id} !!!")

        except Exception as e:
            print(f"!!! EXPORT ERROR {export_id}: {e} !!!")
            import traceback
            traceback.print_exc()
            # Update status to FAILED
            ExportJobService.update_export_job(
                export_id,
                schemas.ExportJobUpdate(
                    status=schemas.ExportStatus.FAILED,
                    completed_at=datetime.utcnow()
                )
            )