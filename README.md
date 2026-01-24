# 🎙️Voicely – Voice Note & AI Assistant Platform

Voicely is a **full-stack voice-based note-taking and AI assistant platform** that allows users to record audio, process it asynchronously, generate notes, and interact with an AI-powered chatbot.

This project is built with a **Flutter frontend** and a **Node.js backend**, following **Clean Architecture** principles and supported by **comprehensive Mermaid diagram documentation**.
---

## 📌 Project Overview

**Voicely** helps users:
- Record and upload voice audio
- Process audio with background jobs
- Automatically generate notes from audio
- Organize notes and audios into folders
- Search notes using embeddings
- Chat with an AI assistant (RAG-based)
- Receive system notifications

---
## 🧩 Tech Stack

### Frontend
- Flutter
- Clean Architecture
- BLoC (State Management)
- Dio (HTTP Client)
- GetIt (Dependency Injection)

### Backend
- Node.js
- RESTful API
- Background job processing
- Database with relational modeling
- AI & Embedding integration

---
## 📌 Luồng hoạt động hệ thống (System Workflow)

```mermaid
    User -->|Record Audio| FE[Flutter App]
    FE -->|Upload Audio| BE[Backend API]
    BE -->|Save Metadata| DB[(Database)]
    BE -->|Create Job| Queue[Background Job Queue]

    Queue --> Worker[Audio Worker]
    Worker -->|Process Audio| AI[AI Services]
    AI -->|Generate Note| BE

    BE -->|Store Note| DB
    BE -->|Send Response| FE
    FE -->|Display Result| User
```

