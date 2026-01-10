from fastapi import APIRouter, HTTPException, status, Query, Depends
from typing import List, Optional
from app import schemas
from app.services.user_service import UserService
from app.services.tier_service import TierService
from app.auth import RoleChecker

router = APIRouter(
    prefix="/admin", 
    tags=["Admin"],
    dependencies=[Depends(RoleChecker([schemas.UserRole.ADMIN]))]
)

@router.get("/users", response_model=List[schemas.User])
def get_admin_users(
    email: Optional[str] = Query(None, description="Filter by email (partial match)"),
    tier_id: Optional[int] = Query(None, description="Filter by tier ID"),
    is_active: Optional[bool] = Query(None, description="Filter by active status")
):
    #gọi service kèm theo các tham số filter
    return UserService.get_all_users(email=email, tier_id=tier_id, is_active=is_active)

@router.patch("/users/{user_id}", response_model=schemas.User)
def update_user_admin(user_id: str, user_update: schemas.UserAdminUpdate):

    update_data = user_update.model_dump(exclude_unset=True)
    if not update_data:
         raise HTTPException(status_code=400, detail="No fields provided for update")
    
    service_update_model = schemas.UserUpdate(**update_data)
    
    updated_user = UserService.update_user(user_id, service_update_model)
    if not updated_user:
        raise HTTPException(status_code=404, detail="User not found")
    return updated_user

@router.get("/tiers", response_model=List[schemas.Tier])
def get_all_tiers():
    return TierService.get_all_tiers()

@router.post("/tiers", response_model=schemas.Tier, status_code=status.HTTP_201_CREATED)
def create_tier(tier: schemas.TierCreate):
    return TierService.create_tier(tier)

@router.patch("/tiers/{tier_id}", response_model=schemas.Tier)
def update_tier(tier_id: int, tier_update: schemas.TierUpdate):
    updated_tier = TierService.update_tier(tier_id, tier_update)
    if not updated_tier:
        raise HTTPException(status_code=404, detail="Tier not found")
    return updated_tier

@router.delete("/tiers/{tier_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_tier(tier_id: int):
    #hard delete vì không có is_active
    
    # Check if tier exists
    existing_tier = TierService.get_tier_by_id(tier_id)
    if not existing_tier:
        raise HTTPException(status_code=404, detail="Tier not found")

    TierService.delete_tier(tier_id)
    return None

@router.get("/audit-logs", response_model=List[schemas.AuditLogWithUser])
def get_audit_logs(
    user_id: Optional[str] = Query(None, description="Filter by user ID"),
    action_type: Optional[str] = Query(None, description="Filter by action type"),
    status: Optional[str] = Query(None, description="Filter by status"),
    date_from: Optional[str] = Query(None, description="Filter by date from (ISO format)"),
    date_to: Optional[str] = Query(None, description="Filter by date to (ISO format)")
):
    from app.services.audit_log_service import AuditLogService
    return AuditLogService.get_audit_logs_filtered(
        user_id=user_id,
        action_type=action_type,
        status=status,
        date_from=date_from,
        date_to=date_to
    )

@router.get("/users/{user_id}/recordings", response_model=List[schemas.Recording])
def get_user_recordings(user_id: str):
    from app.services.recording_service import RecordingService
    return RecordingService.get_recordings_by_user_id(user_id)

@router.get("/recordings/{recording_id}", response_model=schemas.Recording)
def get_recording_detail_admin(recording_id: str):
    from app.services.recording_service import RecordingService
    recording = RecordingService.get_recording_by_id(recording_id)
    if not recording:
        raise HTTPException(status_code=404, detail="Recording not found")
    return recording
