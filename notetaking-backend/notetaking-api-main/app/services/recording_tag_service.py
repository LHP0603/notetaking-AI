from app.utils.database import supabase
from app import schemas
from typing import List, Optional


class RecordingTagService:
    @staticmethod
    def get_tags_by_recording_id(recording_id: str) -> List[schemas.RecordingTag]:
        response = supabase.table("recording_tags").select("*").eq("recording_id", recording_id).execute()
        return response.data

    @staticmethod
    def get_tags_by_recording_id(recording_id: str) -> List[schemas.RecordingTag]:
        """Get all tags for a specific recording"""
        response = supabase.table("recording_tags") \
            .select("*") \
            .eq("recording_id", recording_id) \
            .execute()
        return response.data

    @staticmethod
    def get_recording_tag_by_id(id: str) -> Optional[schemas.RecordingTag]:
        response = supabase.table("recording_tags").select("*").eq("id", id).execute()
        if response.data:
            return schemas.RecordingTag(**response.data[0])
        return None

    @staticmethod
    def add_tags_to_recording(recording_id: str, tags: List[str]) -> List[schemas.RecordingTag]:
        """
        Add multiple tags to a recording.
        Handles duplicates by checking existing tags first.
        Returns list of created tags.
        """
        # Get existing tags for this recording
        existing_response = supabase.table("recording_tags") \
            .select("tag") \
            .eq("recording_id", recording_id) \
            .execute()

        existing_tags = {item['tag'] for item in existing_response.data}

        # Filter out duplicates
        new_tags = [tag for tag in tags if tag not in existing_tags]

        if not new_tags:
            return []

        # Prepare data for insertion
        tags_data = [{"recording_id": recording_id, "tag": tag} for tag in new_tags]

        # Insert new tags
        response = supabase.table("recording_tags").insert(tags_data).execute()
        return response.data

    @staticmethod
    def create_recording_tag(tag: schemas.RecordingTagCreate) -> schemas.RecordingTag:
        """Create a single tag (legacy method)"""
        # Normalize tag
        normalized_tag = tag.tag.strip().lower()

        # Check if tag already exists for this recording
        existing = supabase.table("recording_tags") \
            .select("*") \
            .eq("recording_id", tag.recording_id) \
            .eq("tag", normalized_tag) \
            .execute()

        if existing.data:
            return schemas.RecordingTag(**existing.data[0])

        data = {"recording_id": tag.recording_id, "tag": normalized_tag}
        response = supabase.table("recording_tags").insert(data).execute()
        return schemas.RecordingTag(**response.data[0])

    @staticmethod
    def delete_tag_from_recording(recording_id: str, tag: str) -> bool:
        """
        Delete a specific tag from a recording.
        Returns True if deleted, False if not found.
        """
        response = supabase.table("recording_tags") \
            .delete() \
            .eq("recording_id", recording_id) \
            .eq("tag", tag) \
            .execute()

        return len(response.data) > 0

    @staticmethod
    def delete_recording_tag(id: str) -> None:
        """Delete tag by ID (legacy method)"""
        supabase.table("recording_tags").delete().eq("id", id).execute()

    @staticmethod
    def get_recordings_by_tag(tag: str) -> List[schemas.Recording]:
        """Get all recordings that have a specific tag"""
        # First get all recording_ids with this tag
        tags_response = supabase.table("recording_tags") \
            .select("recording_id") \
            .eq("tag", tag) \
            .execute()

        if not tags_response.data:
            return []

        recording_ids = [item['recording_id'] for item in tags_response.data]

        # Then get the recordings
        recordings_response = supabase.table("recordings") \
            .select("*") \
            .in_("recording_id", recording_ids) \
            .order("created_at", desc=True) \
            .execute()

        return recordings_response.data

    @staticmethod
    def get_distinct_tags() -> List[str]:
        """Get all distinct tag values across all recordings"""
        response = supabase.table("recording_tags") \
            .select("tag") \
            .execute()

        # Extract unique tags
        tags_set = {item['tag'] for item in response.data}
        return sorted(list(tags_set))
