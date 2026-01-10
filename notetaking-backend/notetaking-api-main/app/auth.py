from fastapi import APIRouter, HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import List
from pydantic import BaseModel, EmailStr

from supabase_auth.errors import AuthApiError

from app.utils.database import supabase
from app.services.user_service import UserService
from app import schemas

security = HTTPBearer()
router = APIRouter(prefix="/auth", tags=["auth"])


# ============== AUTH HELPERS ==============

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> schemas.User:
    token = credentials.credentials
    try:
        user_response = supabase.auth.get_user(token)
        if not user_response or not user_response.user:
            raise HTTPException(status_code=401, detail="Invalid token")

        user_id = user_response.user.id
        auth_user = user_response.user
        
        # Try to get user profile from database
        # If it fails due to stack depth (recursive RLS/trigger), create minimal user from auth data
        try:
            user = UserService.get_user_by_id(user_id)
            if user:
                return user
        except Exception as db_error:
            # Check if it's a stack depth error (PostgreSQL error 54001)
            error_str = str(db_error)
            if any(keyword in error_str.lower() for keyword in ["stack depth", "54001", "max_stack_depth"]):
                # Database has recursive trigger/RLS issue - create minimal user from auth
                # This is a temporary workaround until database policies/triggers are fixed
                user_metadata = getattr(auth_user, "user_metadata", {}) or {}
                if not isinstance(user_metadata, dict):
                    user_metadata = {}
                    
                return schemas.User(
                    user_id=user_id,
                    email=getattr(auth_user, "email", ""),
                    full_name=user_metadata.get("full_name"),
                    tier_id=None,
                    role=schemas.UserRole.USER,
                    is_active=True,
                    storage_used_mb=0.0,
                    email_verified=getattr(auth_user, "email_confirmed_at") is not None,
                    last_login_at=None,
                    created_at=None,
                    deleted_at=None
                )
            # Re-raise if it's a different error
            raise
        
        # User profile not found in database - create minimal user from auth
        user_metadata = getattr(auth_user, "user_metadata", {}) or {}
        if not isinstance(user_metadata, dict):
            user_metadata = {}
            
        return schemas.User(
            user_id=user_id,
            email=getattr(auth_user, "email", ""),
            full_name=user_metadata.get("full_name"),
            tier_id=None,
            role=schemas.UserRole.USER,
            is_active=True,
            storage_used_mb=0.0,
            email_verified=getattr(auth_user, "email_confirmed_at") is not None,
            last_login_at=None,
            created_at=None,
            deleted_at=None
        )
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=401,
            detail=f"Authentication failed: {str(e)}",
        )


class RoleChecker:
    def __init__(self, allowed_roles: List[schemas.UserRole]):
        self.allowed_roles = allowed_roles

    def __call__(self, user: schemas.User = Depends(get_current_user)):
        if user.role not in self.allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have enough permissions",
            )
        return user


# ============== REQUEST MODELS ==============

class UserLoginRequest(BaseModel):
    email: EmailStr
    password: str


class UserSignupRequest(BaseModel):
    # FE gửi "name"
    name: str | None = None
    email: EmailStr
    password: str


# ============== LOGIN ==============

@router.post("/login", summary="Login user with Supabase")
def login_user(request: UserLoginRequest):
    """
    FE gửi:
      POST /auth/login
      body: { "email": "...", "password": "..." }

    FE expect:
      {
        "access_token": "...",
        "refresh_token": "...",
        "token_type": "Bearer",
        "user": { "id": "...", "email": "..." }
      }
    """
    try:
        resp = supabase.auth.sign_in_with_password(
            {"email": request.email, "password": request.password}
        )
    except AuthApiError as e:
        # Lỗi auth từ Supabase (sai pass, email_not_confirmed, ...)
        error_msg = str(e)
        if "Invalid login credentials" in error_msg or "Invalid email or password" in error_msg:
             raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password",
            )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error_msg,
        )

    if not resp or not resp.session:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    session = resp.session
    user = resp.user

    # ✨ Trả token ở top-level, match FE
    return {
        "access_token": getattr(session, "access_token", None),
        "refresh_token": getattr(session, "refresh_token", None),
        "token_type": "Bearer",
        "user": {
            "id": getattr(user, "id", None) if user else None,
            "email": getattr(user, "email", request.email) if user else request.email,
        },
    }


# ============== SIGNUP ==============

@router.post("/signup", summary="Sign up user with Supabase")
def signup_user(request: UserSignupRequest):
    """
    FE gửi:
      POST /auth/signup
      body: { "name": "...", "email": "...", "password": "..." }

    FE expect:
      {
        "access_token": "...",
        "refresh_token": "...",
        "token_type": "Bearer",
        "user": { "id": "...", "email": "...", "full_name": "..." }
      }
    """
    # 1. Tạo user trên Supabase Auth
    signup_payload = {
        "email": request.email,
        "password": request.password,
    }
    if request.name:
        signup_payload["data"] = {"full_name": request.name}

    try:
        signup_resp = supabase.auth.sign_up(signup_payload)
    except AuthApiError as e:
        msg = str(e)
        # Case rate limit: "For security purposes, you can only request this after ..."
        if "For security purposes" in msg:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=msg,
            )
        raise HTTPException(status_code=400, detail=msg)

    if not signup_resp or not signup_resp.user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Error signing up user",
        )

    # 2. Tạo profile trong bảng public.users
    try:
        supabase.table("users").insert({
            "user_id": signup_resp.user.id,
            "email": request.email,
            "full_name": request.name,
            # Tùy DB: nếu column role là text, dùng str(...). Nếu là enum type của Postgres thì mapping theo value tương ứng.
            "role": getattr(schemas.UserRole.USER, "value", schemas.UserRole.USER),
            "email_verified": True,
        }).execute()
    except Exception:
        # Có thể log, nhưng không block signup
        pass

    # 3. Auto login để trả token cho FE
    try:
        login_resp = supabase.auth.sign_in_with_password(
            {"email": request.email, "password": request.password}
        )
    except AuthApiError as e:
        raise HTTPException(
            status_code=400,
            detail=f"Signup succeeded but login failed: {str(e)}",
        )

    session = getattr(login_resp, "session", None)
    user = getattr(login_resp, "user", None)

    if session is None:
        raise HTTPException(
            status_code=400,
            detail=(
                "Signup succeeded but no session returned. "
                "Email confirmation may be required."
            ),
        )

    # 4. Trả về token + thông tin user (match FE)
    return {
        "access_token": getattr(session, "access_token", None),
        "refresh_token": getattr(session, "refresh_token", None),
        "token_type": "Bearer",
        "user": {
            "id": getattr(user, "id", None) if user else None,
            "email": getattr(user, "email", request.email) if user else request.email,
            "full_name": request.name,
        },
    }
 