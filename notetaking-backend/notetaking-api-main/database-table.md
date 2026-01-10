CREATE TYPE user_role AS ENUM ('USER', 'ADMIN');

CREATE TYPE recording_source_type AS ENUM ('RECORDED', 'IMPORTED');

CREATE TYPE recording_status AS ENUM ('UPLOADING', 'PROCESSED', 'ERROR');

CREATE TYPE transcript_type AS ENUM ('AI_ORIGINAL', 'USER_EDITED', 'REGENERATED');

CREATE TYPE summary_type AS ENUM ('AI_GENERATED', 'USER_EDITED');

CREATE TYPE marker_type AS ENUM ('NORMAL', 'HIGHLIGHT');

CREATE TYPE export_status AS ENUM ('PENDING', 'PROCESSING', 'DONE', 'FAILED');

CREATE TYPE audit_status AS ENUM ('SUCCESS', 'FAILED');

-- =============================================
-- CREATE TABLES
-- =============================================

## 1. **TIERS**

```sql
CREATE TABLE tiers (
    tier_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    description TEXT,
    max_storage_mb INTEGER,
    max_ai_minutes_monthly INTEGER,
    max_recordings INTEGER,
    max_duration_per_recording_sec INTEGER,
    allow_diarization BOOLEAN DEFAULT FALSE,
    allow_summarization BOOLEAN DEFAULT FALSE,
    price_monthly DECIMAL(10, 2) DEFAULT 0
);
```

---

## 2. **USERS**

```sql
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE,
    full_name VARCHAR(255),
    tier_id INTEGER REFERENCES tiers(tier_id) ON DELETE SET NULL,
    role user_role DEFAULT 'USER',
    is_active BOOLEAN DEFAULT TRUE,
    storage_used_mb DECIMAL(10, 2) DEFAULT 0,
    email_verified BOOLEAN DEFAULT FALSE,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);
```

---

## 3. **AUDIT_LOGS**

```sql
CREATE TABLE audit_logs (
    log_id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    action_type VARCHAR(100),
    resource_type VARCHAR(100),
    resource_id UUID,
    ip_address VARCHAR(50),
    status audit_status,
    error_code VARCHAR(50),
    details TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 4. **FOLDERS**

```sql
CREATE TABLE folders (
    folder_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    name VARCHAR(255),
    parent_folder_id UUID REFERENCES folders(folder_id) ON DELETE CASCADE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);
```

---

## 5. **RECORDINGS**

```sql
CREATE TABLE recordings (
    recording_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    folder_id UUID REFERENCES folders(folder_id) ON DELETE SET NULL,
    title VARCHAR(255),
    file_path TEXT,
    duration_seconds DECIMAL(10, 2),
    file_size_mb DECIMAL(10, 2),
    source_type recording_source_type,
    original_file_name VARCHAR(255),
    status recording_status DEFAULT 'UPLOADING',
    is_pinned BOOLEAN DEFAULT FALSE,
    is_trashed BOOLEAN DEFAULT FALSE,
    auto_title BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);
```

---

## 6. **TRANSCRIPTS**

```sql
CREATE TABLE transcripts (
    transcript_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recording_id UUID REFERENCES recordings(recording_id) ON DELETE CASCADE,
    version_no INTEGER,
    type transcript_type,
    language VARCHAR(10),
    confidence_score DECIMAL(5, 4),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(recording_id, version_no)
);
```

---

## 7. **TRANSCRIPT_SEGMENTS**

```sql
CREATE TABLE transcript_segments (
    segment_id BIGSERIAL PRIMARY KEY,
    transcript_id UUID REFERENCES transcripts(transcript_id) ON DELETE CASCADE,
    sequence INTEGER,
    start_time DECIMAL(10, 2),
    end_time DECIMAL(10, 2),
    content TEXT,
    speaker_label VARCHAR(50),
    confidence DECIMAL(5, 4),
    is_user_edited BOOLEAN DEFAULT FALSE
);
```

---

## 8. **RECORDING_SPEAKERS**

```sql
CREATE TABLE recording_speakers (
    id BIGSERIAL PRIMARY KEY,
    recording_id UUID REFERENCES recordings(recording_id) ON DELETE CASCADE,
    speaker_label VARCHAR(50),
    display_name VARCHAR(255),
    color VARCHAR(20),
    UNIQUE(recording_id, speaker_label)
);
```

---

## 9. **SUMMARIES**

```sql
CREATE TABLE summaries (
    summary_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recording_id UUID REFERENCES recordings(recording_id) ON DELETE CASCADE,
    version_no INTEGER,
    type summary_type,
    summary_style VARCHAR(50),
    content_structure JSONB,
    is_latest BOOLEAN DEFAULT TRUE,
    generated_by UUID REFERENCES users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(recording_id, version_no)
);
```

---

## 10. **AI_USAGE_LOGS**

```sql
CREATE TABLE ai_usage_logs (
    usage_id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    recording_id UUID REFERENCES recordings(recording_id) ON DELETE SET NULL,
    action_type VARCHAR(50),
    duration_seconds DECIMAL(10, 2),
    ai_minutes_charged DECIMAL(10, 2),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 11. **MARKERS**

```sql
CREATE TABLE markers (
    marker_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recording_id UUID REFERENCES recordings(recording_id) ON DELETE CASCADE,
    time_seconds DECIMAL(10, 2),
    label TEXT,
    type marker_type DEFAULT 'NORMAL',
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 12. **EXPORT_JOBS**

```sql
CREATE TABLE export_jobs (
    export_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    recording_id UUID REFERENCES recordings(recording_id) ON DELETE CASCADE,
    export_type VARCHAR(50),
    status export_status DEFAULT 'PENDING',
    file_path TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);
```

---

## 13. **RECORDING_TAGS**

```sql
CREATE TABLE recording_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recording_id UUID REFERENCES recordings(recording_id) ON DELETE CASCADE,
    tag VARCHAR(100)
);
```

---

