from app.utils.database import supabase
from app import schemas
from typing import List, Optional
from datetime import datetime

class FolderService:
    @staticmethod
    def get_all_folders(user_id: str, parent_folder_id: Optional[str] = None) -> List[schemas.Folder]:
        query = supabase.table("folders").select("*").eq("user_id", user_id).eq("is_deleted", False)
        
        if parent_folder_id is not None:
             query = query.eq("parent_folder_id", parent_folder_id)
        
        response = query.execute()
        return response.data

    @staticmethod
    def get_folder_by_id(folder_id: str, user_id: str) -> Optional[schemas.Folder]:
        response = supabase.table("folders").select("*").eq("folder_id", folder_id).eq("user_id", user_id).execute()
        if response.data:
            return schemas.Folder(**response.data[0])
        return None

    @staticmethod
    def create_folder(folder: schemas.FolderCreate, user_id: str) -> schemas.Folder:
        # Check uniqueness: (user_id, parent_folder_id, name)
        query = supabase.table("folders").select("folder_id")\
            .eq("user_id", user_id)\
            .eq("name", folder.name)\
            .eq("is_deleted", False)
        
        if folder.parent_folder_id:
            query = query.eq("parent_folder_id", folder.parent_folder_id)
        else:
            query = query.is_("parent_folder_id", "null")
            
        if query.execute().data:
            raise ValueError("Folder with this name already exists in this location")

        data = folder.model_dump(mode='json', exclude_unset=True)
        data['user_id'] = user_id
        response = supabase.table("folders").insert(data).execute()
        return response.data[0]

    @staticmethod
    def update_folder(folder_id: str, folder: schemas.FolderUpdate, user_id: str) -> Optional[schemas.Folder]:
        # 1. Check existence and ownership
        curr_res = supabase.table("folders").select("*").eq("folder_id", folder_id).eq("user_id", user_id).execute()
        if not curr_res.data:
            return None
        current_data = curr_res.data[0]

        updates = folder.model_dump(mode='json', exclude_unset=True)
        if not updates:
            return current_data

        # 2. Check Uniqueness if name or parent changed
        target_name = updates.get("name", current_data["name"])
        target_parent = updates.get("parent_folder_id", current_data["parent_folder_id"])
        
        if "name" in updates or "parent_folder_id" in updates:
            query = supabase.table("folders").select("folder_id")\
                .eq("user_id", user_id)\
                .eq("name", target_name)\
                .neq("folder_id", folder_id)\
                .eq("is_deleted", False)
            
            if target_parent:
                query = query.eq("parent_folder_id", target_parent)
            else:
                query = query.is_("parent_folder_id", "null")
            
            if query.execute().data:
                raise ValueError("Folder with this name already exists in the destination")

        # 3. Check Circular Dependency if parent changed
        if "parent_folder_id" in updates and updates["parent_folder_id"]:
            new_parent_id = updates["parent_folder_id"]
            if new_parent_id == folder_id:
                raise ValueError("Cannot move folder into itself")
            
            # Check if new_parent_id is a descendant of folder_id
            # Tracing up from new_parent_id
            trace_id = new_parent_id
            depth = 0
            max_depth = 15 # Safety break
            while trace_id and depth < max_depth:
                p_res = supabase.table("folders").select("parent_folder_id").eq("folder_id", trace_id).single().execute()
                if not p_res.data: 
                    break # Should not happen if referential integrity is good, but safeguard
                
                pid = p_res.data.get("parent_folder_id")
                if pid == folder_id:
                     raise ValueError("Cannot move folder into its own subfolder")
                trace_id = pid
                depth += 1

        response = supabase.table("folders").update(updates).eq("folder_id", folder_id).eq("user_id", user_id).execute()
        return response.data[0] if response.data else None

    @staticmethod
    def delete_folder(folder_id: str, user_id: str) -> bool:
        # Soft delete: is_deleted=True, deleted_at=now
        # Check ownership implicitly by query
        updates = {
            "is_deleted": True,
            "deleted_at": datetime.now().isoformat()
        }
        response = supabase.table("folders").update(updates).eq("folder_id", folder_id).eq("user_id", user_id).execute()
        return len(response.data) > 0
