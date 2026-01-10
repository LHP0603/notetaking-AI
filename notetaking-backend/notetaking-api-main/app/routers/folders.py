from fastapi import APIRouter, HTTPException, status, Depends, Query
from typing import List, Optional

from app import schemas
from app.services.folder_service import FolderService
from app.auth import get_current_user

router = APIRouter(prefix="/folders", tags=["Folders"])

@router.get("/", response_model=List[schemas.Folder])
def get_all_folders(
    parent_folder_id: Optional[str] = Query(None, description="Filter by parent folder ID"),
    current_user: schemas.User = Depends(get_current_user)
):
    return FolderService.get_all_folders(current_user.user_id, parent_folder_id)

@router.get("/{folder_id}", response_model=schemas.Folder)
def get_folder(folder_id: str, current_user: schemas.User = Depends(get_current_user)):
    folder = FolderService.get_folder_by_id(folder_id, current_user.user_id)
    if not folder:
        raise HTTPException(status_code=404, detail="Folder not found")
    return folder

@router.post("/", response_model=schemas.Folder, status_code=status.HTTP_201_CREATED)
def create_folder(folder: schemas.FolderCreate, current_user: schemas.User = Depends(get_current_user)):
    try:
        return FolderService.create_folder(folder, current_user.user_id)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.patch("/{folder_id}", response_model=schemas.Folder)
def update_folder(folder_id: str, folder: schemas.FolderUpdate, current_user: schemas.User = Depends(get_current_user)):
    try:
        updated_folder = FolderService.update_folder(folder_id, folder, current_user.user_id)
        if not updated_folder:
            raise HTTPException(status_code=404, detail="Folder not found")
        return updated_folder
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.delete("/{folder_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_folder(folder_id: str, current_user: schemas.User = Depends(get_current_user)):
    success = FolderService.delete_folder(folder_id, current_user.user_id)
    if not success:
        raise HTTPException(status_code=404, detail="Folder not found")
    return None
