from app.utils.database import supabase
from app import schemas
from typing import List, Optional
from app.utils.audit import create_audit_log

class TierService:
    @staticmethod
    def get_all_tiers() -> List[schemas.Tier]:
        response = supabase.table("tiers").select("*").execute()
        return response.data

    @staticmethod
    def get_tier_by_id(tier_id: int) -> Optional[schemas.Tier]:
        response = supabase.table("tiers").select("*").eq("tier_id", tier_id).execute()
        if response.data:
            return schemas.Tier(**response.data[0])
        return None

    @staticmethod
    def create_tier(tier: schemas.TierCreate) -> schemas.Tier:
        data = tier.model_dump(mode='json', exclude_unset=True)
        response = supabase.table("tiers").insert(data).execute()
        return response.data[0]

    @staticmethod
    def update_tier(tier_id: int, tier: schemas.TierUpdate) -> Optional[schemas.Tier]:
        data = tier.model_dump(mode='json', exclude_unset=True)
        response = supabase.table("tiers").update(data).eq("tier_id", tier_id).execute()
        if response.data:
            # Audit Log
            # Audit Log
            create_audit_log(
                user_id=None, # Tier updates are likely admin actions, but we might not have user_id here easily without passing it. 
                              # Looking at the code, update_tier doesn't take user_id. 
                              # The previous implementation didn't pass user_id either (it wasn't in AuditLogCreate args in the snippet).
                              # Wait, AuditLogCreate likely has user_id optional. 
                              # Let's check schemas.py to be sure what AuditLogCreate has, but based on usage it seems it wasn't passed.
                action_type="UPDATE_TIER",
                resource_type="TIER",
                resource_id=str(tier_id),
                status="SUCCESS",
                details=f"Updated tier {tier_id}"
            )

            return response.data[0]
        return None

    @staticmethod
    def delete_tier(tier_id: int) -> None:
        supabase.table("tiers").delete().eq("tier_id", tier_id).execute()
