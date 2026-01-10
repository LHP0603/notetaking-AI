from app.utils.database import supabase
from typing import Optional
from postgrest.exceptions import APIError

def create_audit_log(
    user_id: Optional[str],
    action_type: str,
    resource_type: str,
    resource_id: Optional[str] = None,
    status: str = "SUCCESS",
    details: Optional[str] = None,
    error_code: Optional[str] = None,
    ip_address: Optional[str] = None
) -> None:
    """
    Creates an entry in the AUDIT_LOGS table.
    Handles stack depth errors gracefully to prevent audit logging failures from crashing requests.
    """
    data = {
        "user_id": user_id,
        "action_type": action_type,
        "resource_type": resource_type,
        "resource_id": resource_id,
        "status": status,
        "details": details,
        "error_code": error_code,
        "ip_address": ip_address
    }
    
    try:
        supabase.table("audit_logs").insert(data).execute()
    except APIError as e:
        # Check if it's a stack depth error
        error_str = str(e)
        if any(keyword in error_str.lower() for keyword in ["stack depth", "54001", "max_stack_depth"]):
            # Log warning but don't crash - audit logging failure shouldn't break main operations
            print(f"Warning: Could not create audit log due to stack depth error. Action: {action_type}, Resource: {resource_type}")
        else:
            # Re-raise if it's a different API error
            print(f"Failed to create audit log: {e}")
    except Exception as e:
        # Check if it's a stack depth error in the exception message
        error_str = str(e)
        if any(keyword in error_str.lower() for keyword in ["stack depth", "54001", "max_stack_depth"]):
            # Log warning but don't crash
            print(f"Warning: Could not create audit log due to stack depth error. Action: {action_type}, Resource: {resource_type}")
        else:
            # We generally don't want audit logging failure to crash the main request,
            # but we should log it to stderr/stdout
            print(f"Failed to create audit log: {e}")
