from app.utils.database import supabase
from app import schemas
from typing import List, Optional

class AiUsageLogService:
    @staticmethod
    def get_all_ai_usage_logs() -> List[schemas.AiUsageLog]:
        response = supabase.table("ai_usage_logs").select("*").execute()
        return response.data

    @staticmethod
    def get_ai_usage_log_by_id(usage_id: int) -> Optional[schemas.AiUsageLog]:
        response = supabase.table("ai_usage_logs").select("*").eq("usage_id", usage_id).execute()
        if response.data:
            return schemas.AiUsageLog(**response.data[0])
        return None

    @staticmethod
    def create_ai_usage_log(log: schemas.AiUsageLogCreate) -> schemas.AiUsageLog:
        data = log.model_dump(mode='json', exclude_unset=True)
        response = supabase.table("ai_usage_logs").insert(data).execute()
        return schemas.AiUsageLog(**response.data[0])

    @staticmethod
    def delete_ai_usage_log(usage_id: int) -> None:
        supabase.table("ai_usage_logs").delete().eq("usage_id", usage_id).execute()
