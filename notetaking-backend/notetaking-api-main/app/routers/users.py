from fastapi import APIRouter, HTTPException, status, Depends
from typing import List

from app import schemas
from app.services.user_service import UserService
from app.auth import get_current_user, RoleChecker

router = APIRouter(prefix="/users", tags=["Users"])

@router.get("/me", response_model=schemas.User)
def get_me(current_user: schemas.User = Depends(get_current_user)):
    return current_user

@router.get("/", response_model=List[schemas.User], dependencies=[Depends(RoleChecker([schemas.UserRole.ADMIN]))])
def get_all_users():
    return UserService.get_all_users()

@router.get("/{user_id}", response_model=schemas.User)
def get_user(user_id: str, current_user: schemas.User = Depends(get_current_user)):
    # Only self or admin
    if current_user.user_id != user_id and current_user.role != schemas.UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Not enough permissions")
        
    user = UserService.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.post("/", response_model=schemas.User, status_code=status.HTTP_201_CREATED, dependencies=[Depends(RoleChecker([schemas.UserRole.ADMIN]))])
def create_user(user: schemas.UserCreate):
    return UserService.create_user(user)

@router.put("/{user_id}", response_model=schemas.User)
def update_user(user_id: str, user: schemas.UserUpdate, current_user: schemas.User = Depends(get_current_user)):
    # Only self or admin
    if current_user.user_id != user_id and current_user.role != schemas.UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Not enough permissions")
        
    updated_user = UserService.update_user(user_id, user)
    if not updated_user:
        raise HTTPException(status_code=404, detail="User not found")
    return updated_user

@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(user_id: str, current_user: schemas.User = Depends(get_current_user)):
    # Only self or admin
    if current_user.user_id != user_id and current_user.role != schemas.UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Not enough permissions")
        
    UserService.delete_user(user_id)
    return None
