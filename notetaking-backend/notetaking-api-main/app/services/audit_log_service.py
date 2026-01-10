from app.utils.database import supabase
from app import schemas
from typing import List, Optional

class AuditLogService:
    @staticmethod
    def get_all_audit_logs() -> List[schemas.AuditLog]:
        response = supabase.table("audit_logs").select("*").execute()
        return response.data

    @staticmethod
    def get_audit_logs_filtered(
        user_id: Optional[str] = None,
        action_type: Optional[str] = None,
        status: Optional[str] = None,
        date_from: Optional[str] = None,
        date_to: Optional[str] = None
    ) -> List[schemas.AuditLogWithUser]:
        query = supabase.table("audit_logs").select("*, users(email)")
        
        if user_id:
            query = query.eq("user_id", user_id)
        if action_type:
            query = query.eq("action_type", action_type)
        if status:
            query = query.eq("status", status)
        if date_from:
            query = query.gte("created_at", date_from)
        if date_to:
            query = query.lte("created_at", date_to)
            
        response = query.order("created_at", desc=True).execute()
        
        result = []
        for item in response.data:
            user_data = item.get("users")
            user_email = user_data.get("email") if user_data else None
            
            item_copy = item.copy()
            if "users" in item_copy:
                del item_copy["users"]
            
            audit_log = schemas.AuditLogWithUser(**item_copy, user_email=user_email)
            result.append(audit_log)

        ''' 
        chuyển:          
        {
        "log_id": 123,
        "user_id": "550e8400-e29b-41d4-a716-446655440000",
        "action_type": "DELETE_RECORDING",
        "resource_type": "RECORDING",
        "status": "SUCCESS",
        "created_at": "2024-12-03T10:00:00Z",
        "users": {
            "email": "nguoidung@example.com"
            }
        }

        thành:
        {
        "log_id": 123,
        "user_id": "550e8400-e29b-41d4-a716-446655440000",
        "action_type": "DELETE_RECORDING",
        "resource_type": "RECORDING",
        "status": "SUCCESS",
        "created_at": "2024-12-03T10:00:00Z",
        "user_email": "nguoidung@example.com"
        }
        '''
            
        return result

    @staticmethod
    def get_audit_log_by_id(log_id: int) -> Optional[schemas.AuditLog]:
        response = supabase.table("audit_logs").select("*").eq("log_id", log_id).execute()
        if response.data:
            return response.data[0]
        return None

    @staticmethod
    def create_audit_log(log: schemas.AuditLogCreate) -> schemas.AuditLog:
        data = log.model_dump(mode='json', exclude_unset=True)
        response = supabase.table("audit_logs").insert(data).execute()
        return response.data[0]

    @staticmethod
    def delete_audit_log(log_id: int) -> None:
        supabase.table("audit_logs").delete().eq("log_id", log_id).execute()
