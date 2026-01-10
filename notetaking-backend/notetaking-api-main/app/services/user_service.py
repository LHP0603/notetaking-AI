from app.utils.database import supabase
from app import schemas
from typing import List, Optional

class UserService:
    @staticmethod
    def get_all_users(
        email: Optional[str] = None, 
        tier_id: Optional[int] = None, 
        is_active: Optional[bool] = None
    ) -> List[schemas.User]:
        query = supabase.table("users").select("*")
        
        if email:
            query = query.ilike("email", f"%{email}%")
        if tier_id is not None:
            query = query.eq("tier_id", tier_id)
        if is_active is not None:
            query = query.eq("is_active", is_active)
            
        response = query.execute()
        return response.data

    @staticmethod
    def get_user_by_id(user_id: str) -> Optional[schemas.User]:
        response = supabase.table("users").select("*").eq("user_id", user_id).execute()
        if response.data:
            return schemas.User(**response.data[0])
        return None

    @staticmethod
    def create_user(user: schemas.UserCreate) -> schemas.User:
        data = user.model_dump(mode='json', exclude_unset=True)
        response = supabase.table("users").insert(data).execute()
        return response.data[0]

    @staticmethod
    def update_user(user_id: str, user: schemas.UserUpdate) -> Optional[schemas.User]:
        data = user.model_dump(mode='json', exclude_unset=True)
        response = supabase.table("users").update(data).eq("user_id", user_id).execute()
        if response.data:
            return response.data[0]
        return None

    @staticmethod
    def delete_user(user_id: str) -> None:
        supabase.table("users").delete().eq("user_id", user_id).execute()
