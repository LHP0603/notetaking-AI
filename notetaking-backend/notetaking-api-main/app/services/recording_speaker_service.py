from app.utils.database import supabase
from app import schemas
from typing import List, Optional

class RecordingSpeakerService:
    @staticmethod
    def get_speakers_by_recording_id(recording_id: str) -> List[schemas.RecordingSpeaker]:
        response = supabase.table("recording_speakers").select("*").eq("recording_id", recording_id).execute()
        return response.data

    @staticmethod
    def create_recording_speaker(recording_id: str, speaker: schemas.RecordingSpeakerCreate) -> schemas.RecordingSpeaker:
        data = speaker.model_dump(mode='json', exclude_unset=True)
        data["recording_id"] = recording_id
        response = supabase.table("recording_speakers").insert(data).execute()
        return response.data[0]

    @staticmethod
    def update_recording_speaker(speaker_id: int, speaker: schemas.RecordingSpeakerUpdate) -> Optional[schemas.RecordingSpeaker]:
        data = speaker.model_dump(mode='json', exclude_unset=True)
        response = supabase.table("recording_speakers").update(data).eq("id", speaker_id).execute()
        if response.data:
            return response.data[0]
        return None

    @staticmethod
    def delete_recording_speaker(speaker_id: int) -> None:
        supabase.table("recording_speakers").delete().eq("id", speaker_id).execute()
