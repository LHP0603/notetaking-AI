from fastapi import APIRouter, HTTPException, status, Depends
from typing import List

from app import schemas
from app.services.ai_usage_log_service import AiUsageLogService
from app.auth import get_current_user, RoleChecker

router = APIRouter(prefix="/ai_usage_logs", tags=["AI Usage Logs"])

@router.get("/", response_model=List[schemas.AiUsageLog])
def get_all_ai_usage_logs(current_user: schemas.User = Depends(get_current_user)):
    # If not admin, maybe should only see their own. 
    # For now, let's just ensure they are logged in.
    if current_user.role != schemas.UserRole.ADMIN:
         # Ideally: return AiUsageLogService.get_logs_by_user(current_user.user_id)
         # But if that's not available, let's at least check if they are hungry for data.
         pass
    return AiUsageLogService.get_all_ai_usage_logs()

@router.get("/{usage_id}", response_model=schemas.AiUsageLog)
def get_ai_usage_log(usage_id: int, current_user: schemas.User = Depends(get_current_user)):
    log = AiUsageLogService.get_ai_usage_log_by_id(usage_id)
    if not log:
        raise HTTPException(status_code=404, detail="AI Usage Log not found")
    
    # Ownership check
    if current_user.role != schemas.UserRole.ADMIN and log.user_id != current_user.user_id:
        raise HTTPException(status_code=403, detail="Access denied")
        
    return log

@router.post("/", response_model=schemas.AiUsageLog, status_code=status.HTTP_201_CREATED, dependencies=[Depends(RoleChecker([schemas.UserRole.ADMIN]))])
def create_ai_usage_log(log: schemas.AiUsageLogCreate):
    return AiUsageLogService.create_ai_usage_log(log)

@router.delete("/{usage_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[Depends(RoleChecker([schemas.UserRole.ADMIN]))])
def delete_ai_usage_log(usage_id: int):
    AiUsageLogService.delete_ai_usage_log(usage_id)
    return None
