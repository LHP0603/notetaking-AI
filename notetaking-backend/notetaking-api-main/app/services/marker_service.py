from app.utils.database import supabase
from app import schemas
from typing import List, Optional

class MarkerService:
    @staticmethod
    def get_all_markers() -> List[schemas.Marker]:
        response = supabase.table("markers").select("*").order("created_at", desc=True).execute()
        return response.data

    @staticmethod
    def get_markers_by_recording_id(recording_id: str) -> List[schemas.Marker]:
        """Get all markers for a specific recording, ordered by time"""
        response = supabase.table("markers")\
            .select("*")\
            .eq("recording_id", recording_id)\
            .order("time_seconds")\
            .execute()
        return response.data

    @staticmethod
    def get_marker_by_id(marker_id: str) -> Optional[schemas.Marker]:
        response = supabase.table("markers").select("*").eq("marker_id", marker_id).execute()
        if response.data:
            return schemas.Marker(**response.data[0])
        return None

    @staticmethod
    def create_marker(recording_id: str, marker_data: schemas.MarkerCreate) -> schemas.Marker:
        # Check recording duration
        recording_res = supabase.table("recordings").select("duration_seconds").eq("recording_id", recording_id).single().execute()
        if not recording_res.data:
            raise ValueError("Recording not found")
        
        duration = recording_res.data['duration_seconds'] or 0
        if marker_data.time_seconds > duration:
            raise ValueError(f"Marker time {marker_data.time_seconds} exceeds recording duration {duration}")

        data = marker_data.model_dump(mode='json', exclude_unset=True)
        data['recording_id'] = recording_id # Ensure it matches URL
        
        response = supabase.table("markers").insert(data).execute()
        return response.data[0]

    @staticmethod
    def update_marker(marker_id: str, marker: schemas.MarkerUpdate) -> Optional[schemas.Marker]:
        data = marker.model_dump(mode='json', exclude_unset=True)
        
        # If updating time, technically we should check duration again, but let's assume valid or partial update
        # To be safe, we could fetch recording_id from marker -> recording -> duration
        if marker.time_seconds is not None:
             # Fetch current marker to get recording_id
             current_marker = supabase.table("markers").select("recording_id").eq("marker_id", marker_id).single().execute()
             if current_marker.data:
                 rec_id = current_marker.data['recording_id']
                 rec_res = supabase.table("recordings").select("duration_seconds").eq("recording_id", rec_id).single().execute()
                 if rec_res.data:
                     duration = rec_res.data['duration_seconds'] or 0
                     if marker.time_seconds > duration:
                         raise ValueError(f"Marker time {marker.time_seconds} exceeds recording duration {duration}")

        response = supabase.table("markers").update(data).eq("marker_id", marker_id).execute()
        if response.data:
            return response.data[0]
        return None

    @staticmethod
    def delete_marker(marker_id: str) -> None:
        supabase.table("markers").delete().eq("marker_id", marker_id).execute()