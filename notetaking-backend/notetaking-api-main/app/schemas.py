from pydantic import BaseModel, Field
from typing import Optional, Any, Dict, List
from datetime import datetime
from enum import Enum
import uuid

# ============================
# ENUMS
# ============================
class UserRole(str, Enum):
    USER = "USER"
    ADMIN = "ADMIN"

class RecordingSourceType(str, Enum):
    RECORDED = "RECORDED"
    IMPORTED = "IMPORTED"

class RecordingStatus(str, Enum):
    UPLOADING = "UPLOADING"
    PROCESSED = "PROCESSED"
    ERROR = "ERROR"

class TranscriptType(str, Enum):
    AI_ORIGINAL = "AI_ORIGINAL"
    USER_EDITED = "USER_EDITED"
    REGENERATED = "REGENERATED"

class SummaryType(str, Enum):
    AI_GENERATED = "AI_GENERATED"
    USER_EDITED = "USER_EDITED"

class MarkerType(str, Enum):
    NORMAL = "NORMAL"
    HIGHLIGHT = "HIGHLIGHT"

class ExportStatus(str, Enum):
    PENDING = "PENDING"
    PROCESSING = "PROCESSING"
    DONE = "DONE"
    FAILED = "FAILED"

class AuditStatus(str, Enum):
    SUCCESS = "SUCCESS"
    FAILED = "FAILED"

# ============================
# SYSTEM_CONFIG
# ============================
class SystemConfigBase(BaseModel):
    config_key: str
    config_value: str
    description: Optional[str] = None
    config_group: Optional[str] = None
    is_sensitive: Optional[bool] = False

class SystemConfigCreate(SystemConfigBase):
    pass

class SystemConfigUpdate(BaseModel):
    config_value: Optional[str] = None
    description: Optional[str] = None
    config_group: Optional[str] = None
    is_sensitive: Optional[bool] = None

class SystemConfig(SystemConfigBase):
    updated_at: Optional[datetime] = None

# ============================
# TIERS
# ============================
class TierBase(BaseModel):
    name: str
    description: Optional[str] = None
    max_storage_mb: int
    max_ai_minutes_monthly: int
    max_recordings: int
    max_duration_per_recording_sec: int
    allow_diarization: Optional[bool] = False
    allow_summarization: Optional[bool] = False
    price_monthly: Optional[float] = 0.0

class TierCreate(TierBase):
    pass

class TierUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    max_storage_mb: Optional[int] = None
    max_ai_minutes_monthly: Optional[int] = None
    max_recordings: Optional[int] = None
    max_duration_per_recording_sec: Optional[int] = None
    allow_diarization: Optional[bool] = None
    allow_summarization: Optional[bool] = None
    price_monthly: Optional[float] = None

class Tier(TierBase):
    tier_id: int

# ============================
# USERS
# ============================
class UserBase(BaseModel):
    email: str
    full_name: Optional[str] = None
    tier_id: Optional[int] = None
    role: Optional[UserRole] = UserRole.USER
    is_active: Optional[bool] = True
    storage_used_mb: Optional[float] = 0.0
    email_verified: Optional[bool] = True

class UserCreate(UserBase):
    pass


class UserUpdate(BaseModel):
    email: Optional[str] = None
    full_name: Optional[str] = None
    tier_id: Optional[int] = None
    role: Optional[UserRole] = None
    is_active: Optional[bool] = None
    storage_used_mb: Optional[float] = None
    email_verified: Optional[bool] = None


class UserAdminUpdate(BaseModel):
    tier_id: Optional[int] = None
    role: Optional[UserRole] = None
    is_active: Optional[bool] = None


class User(UserBase):
    user_id: str
    last_login_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    deleted_at: Optional[datetime] = None

# ============================
# AUDIT_LOGS
# ============================
class AuditLogBase(BaseModel):
    user_id: Optional[str] = None
    action_type: str
    resource_type: str
    resource_id: Optional[str] = None
    ip_address: Optional[str] = None
    status: AuditStatus
    error_code: Optional[str] = None
    details: Optional[str] = None

class AuditLogCreate(AuditLogBase):
    pass

class AuditLog(AuditLogBase):
    log_id: int
    created_at: Optional[datetime] = None

class AuditLogWithUser(AuditLog):
    user_email: Optional[str] = None

# ============================
# FOLDERS
# ============================
class FolderBase(BaseModel):
    name: str
    parent_folder_id: Optional[str] = None
    is_deleted: Optional[bool] = False

class FolderCreate(BaseModel):
    name: str
    parent_folder_id: Optional[str] = None

class FolderUpdate(BaseModel):
    name: Optional[str] = None
    parent_folder_id: Optional[str] = None
    is_deleted: Optional[bool] = None

class Folder(FolderBase):
    folder_id: str
    user_id: str
    created_at: Optional[datetime] = None
    deleted_at: Optional[datetime] = None

# ============================
# RECORDINGS
# ============================
class RecordingBase(BaseModel):
    user_id: str
    folder_id: Optional[str] = None
    title: str
    file_path: Optional[str] = None
    duration_seconds: Optional[float] = None
    file_size_mb: Optional[float] = None
    source_type: RecordingSourceType
    original_file_name: Optional[str] = None
    status: Optional[RecordingStatus] = RecordingStatus.UPLOADING
    is_pinned: Optional[bool] = False
    is_trashed: Optional[bool] = False
    auto_title: Optional[bool] = False

class RecordingCreate(RecordingBase):
    pass

class RecordingInitRequest(BaseModel):
    folder_id: Optional[str] = None
    title: str
    source_type: RecordingSourceType = RecordingSourceType.RECORDED

class RecordingUploadCompleteRequest(BaseModel):
    file_path: str
    file_size_mb: float
    duration_seconds: float
    original_file_name: Optional[str] = None

class RecordingUpdate(BaseModel):
    folder_id: Optional[str] = None
    title: Optional[str] = None
    file_path: Optional[str] = None
    duration_seconds: Optional[float] = None
    file_size_mb: Optional[float] = None
    source_type: Optional[RecordingSourceType] = None
    original_file_name: Optional[str] = None
    status: Optional[RecordingStatus] = None
    is_pinned: Optional[bool] = None
    is_trashed: Optional[bool] = None
    auto_title: Optional[bool] = None

class RecordingUserUpdate(BaseModel):
    title: Optional[str] = None
    folder_id: Optional[str] = None 
    is_pinned: Optional[bool] = None

class Recording(RecordingBase):
    recording_id: str
    created_at: Optional[datetime] = None
    deleted_at: Optional[datetime] = None

class RecordingDetail(Recording):
    audio_url: Optional[str] = None
    transcript_count: int = 0
    summary_count: int = 0


# ============================
# TRANSCRIPTS
# ============================
class TranscriptBase(BaseModel):
    recording_id: str
    version_no: int
    type: TranscriptType
    language: Optional[str] = None
    confidence_score: Optional[float] = None
    is_active: Optional[bool] = True

class TranscriptCreate(TranscriptBase):
    pass

class TranscriptUpdate(BaseModel):
    language: Optional[str] = None
    confidence_score: Optional[float] = None
    is_active: Optional[bool] = None

class Transcript(TranscriptBase):
    transcript_id: str
    created_at: Optional[datetime] = None

class TranscriptDetail(Transcript):
    segments: List["TranscriptSegment"] = []

# ============================
# TRANSCRIPT SEGMENTS
# ============================
class TranscriptSegmentBase(BaseModel):
    transcript_id: str
    sequence: int
    start_time: float
    end_time: float
    content: str
    speaker_label: Optional[str] = None
    confidence: Optional[float] = None
    is_user_edited: Optional[bool] = False

class TranscriptSegmentCreate(TranscriptSegmentBase):
    pass

class TranscriptSegmentUpdate(BaseModel):
    sequence: Optional[int] = None
    start_time: Optional[float] = None
    end_time: Optional[float] = None
    content: Optional[str] = None
    speaker_label: Optional[str] = None
    confidence: Optional[float] = None
    is_user_edited: Optional[bool] = None

class TranscriptSegment(TranscriptSegmentBase):
    segment_id: int

# ============================
# RECORDING SPEAKERS
# ============================
class RecordingSpeakerBase(BaseModel):
    recording_id: str
    speaker_label: str
    display_name: Optional[str] = None
    color: Optional[str] = None

class RecordingSpeakerCreate(RecordingSpeakerBase):
    pass

class RecordingSpeakerUpdate(BaseModel):
    display_name: Optional[str] = None
    color: Optional[str] = None

class RecordingSpeaker(RecordingSpeakerBase):
    id: int

# ============================
# SUMMARIES
# ============================
class SummaryBase(BaseModel):
    recording_id: str
    version_no: int
    type: SummaryType
    summary_style: Optional[str] = None
    content_structure: Optional[Dict[str, Any]] = None
    is_latest: Optional[bool] = True
    generated_by: Optional[str] = None

class SummaryCreate(SummaryBase):
    pass

class SummaryUpdate(BaseModel):
    type: Optional[SummaryType] = None
    summary_style: Optional[str] = None
    content_structure: Optional[Dict[str, Any]] = None
    is_latest: Optional[bool] = None
    generated_by: Optional[str] = None

class Summary(SummaryBase):
    summary_id: str
    created_at: Optional[datetime] = None

class SummaryRequest(BaseModel):
    summary_style: Optional[str] = "MEETING"

# ============================
# AI_USAGE_LOGS
# ============================
class AiUsageLogBase(BaseModel):
    user_id: str
    recording_id: Optional[str] = None
    action_type: str
    duration_seconds: float
    ai_minutes_charged: float

class AiUsageLogCreate(AiUsageLogBase):
    pass

class AiUsageLog(AiUsageLogBase):
    usage_id: int
    created_at: Optional[datetime] = None

# ============================
# MARKERS
# ============================
class MarkerBase(BaseModel):
    recording_id: str
    time_seconds: float
    label: Optional[str] = None
    type: Optional[MarkerType] = MarkerType.NORMAL

class MarkerCreate(MarkerBase):
    pass

class MarkerUpdate(BaseModel):
    time_seconds: Optional[float] = None
    label: Optional[str] = None
    type: Optional[MarkerType] = None

class Marker(MarkerBase):
    marker_id: str
    created_at: Optional[datetime] = None

# ============================
# EXPORT_JOBS
# ============================
class ExportJobBase(BaseModel):
    user_id: str
    recording_id: str
    export_type: str
    status: Optional[ExportStatus] = ExportStatus.PENDING
    file_path: Optional[str] = None

class ExportJobCreate(ExportJobBase):
    pass

class ExportJobUpdate(BaseModel):
    status: Optional[ExportStatus] = None
    file_path: Optional[str] = None
    completed_at: Optional[datetime] = None

class ExportJob(ExportJobBase):
    export_id: str
    created_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

# ============================
# RECORDING_TAGS
# ============================
class RecordingTagBase(BaseModel):
    recording_id: str
    tag: str

class RecordingTagCreate(RecordingTagBase):
    pass

class RecordingTag(RecordingTagBase):
    id: str

# ============================
# EXPORT JOB DETAIL (with download URL)
# ============================
class ExportJobDetail(ExportJob):
    download_url: Optional[str] = None