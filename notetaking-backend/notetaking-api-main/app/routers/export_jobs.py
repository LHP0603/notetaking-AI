from fastapi import APIRouter, HTTPException, status, BackgroundTasks
from typing import List
from pydantic import BaseModel

from app import schemas
from app.services.export_job_service import ExportJobService
from app.services.recording_service import RecordingService

router = APIRouter(prefix="/recordings", tags=["Export Jobs"])


class ExportRequest(BaseModel):
    export_type: str  # "TRANSCRIPT_PDF", "TRANSCRIPT_DOCX", "SUMMARY_PDF", "SUMMARY_DOCX", "FULL_ZIP"


@router.post("/{recording_id}/export", response_model=schemas.ExportJob, status_code=status.HTTP_201_CREATED)
def create_export_job(recording_id: str, request: ExportRequest, background_tasks: BackgroundTasks):
    """
    Create an export job for a recording.
    Export types: TRANSCRIPT_PDF, TRANSCRIPT_DOCX, SUMMARY_PDF, SUMMARY_DOCX, FULL_ZIP
    """
    # Verify recording exists
    recording = RecordingService.get_recording_by_id(recording_id)
    if not recording:
        raise HTTPException(status_code=404, detail="Recording not found")

    # Validate export type
    valid_types = ["TRANSCRIPT_PDF", "TRANSCRIPT_DOCX", "SUMMARY_PDF", "SUMMARY_DOCX", "FULL_ZIP"]
    if request.export_type not in valid_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid export_type. Must be one of: {', '.join(valid_types)}"
        )

    # Check if recording is processed
    if recording.status != 'PROCESSED':
        raise HTTPException(
            status_code=400,
            detail="Recording must be in PROCESSED status to export"
        )

    # Check if transcript/summary exists based on export type
    if request.export_type.startswith("TRANSCRIPT"):
        from app.services.transcript_service import TranscriptService
        transcripts = TranscriptService.get_transcripts_by_recording_id(recording_id, latest=True)
        if not transcripts:
            raise HTTPException(
                status_code=400,
                detail="No transcript available for this recording. Please transcribe first."
            )

    if request.export_type.startswith("SUMMARY"):
        from app.services.summary_service import SummaryService
        summaries = SummaryService.get_summaries_by_recording_id(recording_id, latest=True)
        if not summaries:
            raise HTTPException(
                status_code=400,
                detail="No summary available for this recording. Please generate summary first."
            )

    # Create export job
    job_data = schemas.ExportJobCreate(
        user_id=recording.user_id,
        recording_id=recording_id,
        export_type=request.export_type,
        status=schemas.ExportStatus.PENDING
    )

    job = ExportJobService.create_export_job(job_data)

    # Add background task to process export
    # DEBUG: Run synchronously to catch errors
    # background_tasks.add_task(
    #     ExportJobService.process_export_job,
    #     job.export_id
    # )
    ExportJobService.process_export_job(job.export_id)

    return job


@router.get("/{recording_id}/exports", response_model=List[schemas.ExportJob])
def get_recording_exports(recording_id: str):
    """Get all export jobs for a specific recording"""
    recording = RecordingService.get_recording_by_id(recording_id)
    if not recording:
        raise HTTPException(status_code=404, detail="Recording not found")

    return ExportJobService.get_exports_by_recording_id(recording_id)


# Export job management endpoints
@router.get("/export-jobs/{export_id}", response_model=schemas.ExportJobDetail, tags=["Export Jobs"])
def get_export_job(export_id: str):
    """Get export job status and download URL if completed"""
    job = ExportJobService.get_export_job_by_id(export_id)
    if not job:
        raise HTTPException(status_code=404, detail="Export Job not found")

    # If job is done, get signed URL for download
    download_url = None
    if job.status == 'DONE' and job.file_path:
        download_url = ExportJobService.get_download_url(job.file_path)

    return schemas.ExportJobDetail(
        **job.model_dump(),
        download_url=download_url
    )


@router.get("/export-jobs", response_model=List[schemas.ExportJob], tags=["Export Jobs"])
def get_all_export_jobs():
    """Get all export jobs (admin)"""
    return ExportJobService.get_all_export_jobs()


@router.delete("/export-jobs/{export_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Export Jobs"])
def delete_export_job(export_id: str):
    """Delete an export job and its file"""
    job = ExportJobService.get_export_job_by_id(export_id)
    if not job:
        raise HTTPException(status_code=404, detail="Export Job not found")

    # Delete file from storage if exists
    if job.file_path:
        try:
            ExportJobService.delete_export_file(job['file_path'])
        except Exception as e:
            print(f"Error deleting export file: {e}")

    ExportJobService.delete_export_job(export_id)
    return None