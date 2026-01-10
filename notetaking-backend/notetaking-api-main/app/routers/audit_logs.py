from fastapi import APIRouter, HTTPException, status, Depends
from typing import List
from app import schemas
from app.services.audit_log_service import AuditLogService
from app.auth import RoleChecker

router = APIRouter(
    prefix="/audit-logs", 
    tags=["Audit Logs"],
    dependencies=[Depends(RoleChecker([schemas.UserRole.ADMIN]))]
)

@router.get("/", response_model=List[schemas.AuditLog])
def get_all_audit_logs():
    return AuditLogService.get_all_audit_logs()

@router.get("/{log_id}", response_model=schemas.AuditLog)
def get_audit_log(log_id: int):
    log = AuditLogService.get_audit_log_by_id(log_id)
    if not log:
        raise HTTPException(status_code=404, detail="Audit log not found")
    return log

@router.post("/", response_model=schemas.AuditLog, status_code=status.HTTP_201_CREATED)
def create_audit_log(log: schemas.AuditLogCreate):
    return AuditLogService.create_audit_log(log)

@router.delete("/{log_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_audit_log(log_id: int):
    AuditLogService.delete_audit_log(log_id)
    return None
