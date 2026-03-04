# IntelliPost

> AI-powered postal mail scanner for India Post — capture envelope images, extract sender/recipient details via vision AI, and auto-assign sorting centers using pincode lookup.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![FastAPI](https://img.shields.io/badge/FastAPI-0.116-009688?logo=fastapi)
![Python](https://img.shields.io/badge/Python-3.13-3776AB?logo=python)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-4169E1?logo=postgresql)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Envelope Scanning** — Capture postal envelopes via camera or import from gallery
- **AI-Powered Extraction** — Vision model reads handwritten/printed addresses, names, and pincodes from envelope images
- **Sorting Center Assignment** — Automatically resolves receiver pincode to the correct India Post sorting division
- **Presigned Uploads** — Images upload directly to Cloudflare R2 via presigned URLs (zero backend bandwidth)
- **Scan History** — Browse, filter, and review all processed mail with full extracted details
- **JWT Authentication** — Secure user registration and login with bcrypt password hashing

## System Architecture

```mermaid
graph TB
    subgraph Client["Mobile App (Flutter)"]
        UI[UI Layer<br/>Views + Widgets]
        VM[ViewModels<br/>Provider State]
        SVC[Services<br/>API / Auth / Storage]
        HIVE[(Hive<br/>Local Cache)]
    end

    subgraph Backend["Backend API (FastAPI)"]
        ROUTER[Routers<br/>/auth  /mails]
        CTRL[Controllers<br/>Business Logic]
        CRUD[CRUD Layer<br/>SQLModel ORM]
        AGENT[Agent Service<br/>Pydantic AI]
        R2SVC[R2 Service<br/>Presigned URLs]
        PINCODE[Pincode Service<br/>Sorting Lookup]
    end

    subgraph External["External Services"]
        PG[(PostgreSQL 17)]
        R2[(Cloudflare R2<br/>Object Storage)]
        OPENAI[OpenAI Vision API<br/>GPT-5]
        POSTAPI[India Post API<br/>Pincode Lookup]
    end

    UI --> VM
    VM --> SVC
    SVC --> HIVE
    SVC -- "HTTP / JWT" --> ROUTER
    SVC -- "Presigned PUT" --> R2

    ROUTER --> CTRL
    CTRL --> CRUD
    CTRL --> AGENT
    CTRL --> R2SVC
    CTRL --> PINCODE

    CRUD --> PG
    AGENT --> OPENAI
    R2SVC --> R2
    PINCODE --> POSTAPI
    PINCODE --> CRUD
```

## API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/api/v1/auth/register` | No | Create account with username, email, password |
| `POST` | `/api/v1/auth/login` | No | Authenticate and receive JWT access token |
| `POST` | `/api/v1/mails/generate_upload_url` | JWT | Get presigned R2 PUT URL + file key |
| `POST` | `/api/v1/mails/process?file_key=...` | JWT | Trigger background AI processing on uploaded image |
| `GET`  | `/api/v1/mails/?limit=20&offset=0` | JWT | List user's processed mail (paginated) |
| `GET`  | `/api/v1/mails/{mail_id}` | JWT | Get single mail with fresh presigned image URL |

## Mail Processing Pipeline

The core workflow from image capture to sorted mail result:

```mermaid
sequenceDiagram
    actor User
    participant App as Flutter App
    participant API as FastAPI Backend
    participant R2 as Cloudflare R2
    participant AI as OpenAI Vision
    participant Post as India Post API
    participant DB as PostgreSQL

    User ->> App: Capture / import envelope image

    Note over App, R2: Step 1 — Direct Upload (bypasses backend)
    App ->> API: POST /mails/generate_upload_url
    API ->> R2: Generate presigned PUT URL (5 min TTL)
    R2 -->> API: Presigned URL + file key
    API -->> App: {upload_url, file_key}
    App ->> R2: PUT image bytes (direct upload)
    R2 -->> App: 200 OK

    Note over App, DB: Step 2 — Trigger Processing
    App ->> API: POST /mails/process?file_key=...
    API ->> DB: INSERT mail (status: PENDING)
    API -->> App: Mail record (immediate response)

    Note over API, Post: Step 3 — Background Processing
    API ->> DB: UPDATE status → PROCESSING
    API ->> R2: Generate presigned GET URL (1 hr TTL)
    R2 -->> API: Signed image URL
    API ->> AI: Send image URL + extraction prompt
    AI -->> API: VisionOutput {sender, receiver, pincodes}
    API ->> DB: UPDATE mail fields from AI response
    API ->> Post: GET /pincode/{receiver_pincode}
    Post -->> API: Sorting division + district
    API ->> DB: UPDATE sorting_center, status → COMPLETED

    Note over App, DB: Step 4 — Client Polls Result
    App ->> API: GET /mails/{mail_id}
    API ->> R2: Generate fresh GET URL
    API -->> App: Complete mail data + image URL
    App ->> App: Save to Hive local cache
    App -->> User: Display extracted details
```

## Authentication Flow

```mermaid
sequenceDiagram
    actor User
    participant App as Flutter App
    participant API as FastAPI
    participant DB as PostgreSQL

    Note over User, DB: Registration
    User ->> App: Enter username, email, password
    App ->> API: POST /auth/register
    API ->> API: bcrypt.hash(password)
    API ->> DB: INSERT user (hashed_password)
    DB -->> API: User record
    API -->> App: {id, username, email}

    Note over User, DB: Login
    User ->> App: Enter email, password
    App ->> API: POST /auth/login
    API ->> DB: SELECT user WHERE email = ?
    API ->> API: bcrypt.verify(password, hash)
    API ->> API: JWT encode {sub: user_id, exp: +60min}
    API -->> App: {access_token, token_type: "bearer"}
    App ->> App: Store token in Hive

    Note over User, DB: Authenticated Requests
    App ->> API: Any request + Authorization: <JWT>
    API ->> API: Decode JWT, extract user_id
    API ->> DB: SELECT user WHERE id = user_id
    API -->> API: Inject current_user into handler
```

## Database Schema

```mermaid
erDiagram
    users {
        uuid id PK
        string username
        string email
        string hashed_password
        datetime created_at
        datetime updated_at
    }

    mails {
        uuid id PK
        uuid user_id FK
        string image_s3_key
        string image_url
        enum status "PENDING | PROCESSING | COMPLETED | FAILED"
        string sender_name
        string sender_address
        string sender_pincode
        string receiver_name
        string receiver_address
        string receiver_pincode
        string assigned_sorting_center
        json raw_ai_response
        datetime created_at
        datetime updated_at
    }

    pincode_cache {
        string pincode PK
        string sorting_district
        string sorting_division
        string state
        json raw_api_data
        datetime updated_at
    }

    users ||--o{ mails : "has many (cascade delete)"
    mails }o..o| pincode_cache : "receiver_pincode → pincode"
```

## Mobile App Architecture

The Flutter app follows **MVVM** with Provider for state management:

```mermaid
graph TD
    subgraph Views["Views (UI)"]
        AUTH_V[Auth Screens<br/>Login / Register]
        HOME_V[Home Screen<br/>Navigation + Scan List]
        SCAN_V[Scan Screen<br/>Camera + Preview]
        HIST_V[History Screen<br/>Filters + Detail View]
    end

    subgraph ViewModels["ViewModels (State)"]
        AUTH_VM[AuthViewModel<br/>Form validation, login/register]
        HOME_VM[HomeViewModel<br/>Scan list, refresh]
        SCAN_VM[ScanViewModel<br/>Upload, process, status]
        HIST_VM[HistoryViewModel<br/>Filters, search, sort]
    end

    subgraph Services["Services"]
        API_SVC[ApiService<br/>HTTP client, presigned upload]
        AUTH_SVC[AuthService<br/>Register, login, JWT]
        STORE_SVC[StorageService<br/>Hive read/write]
    end

    subgraph Models["Models (Hive)"]
        USER_M[UserModel<br/>id, name, email, token]
        SCAN_M[ScanModel<br/>id, image, sender, receiver, status]
    end

    AUTH_V --> AUTH_VM
    HOME_V --> HOME_VM
    SCAN_V --> SCAN_VM
    HIST_V --> HIST_VM

    AUTH_VM --> AUTH_SVC
    AUTH_VM --> STORE_SVC
    HOME_VM --> API_SVC
    HOME_VM --> STORE_SVC
    SCAN_VM --> API_SVC
    SCAN_VM --> STORE_SVC
    HIST_VM --> STORE_SVC

    API_SVC --> SCAN_M
    AUTH_SVC --> USER_M
    STORE_SVC --> USER_M
    STORE_SVC --> SCAN_M
```

## Getting Started

### Prerequisites

- Flutter SDK 3.10+
- Python 3.13+ with [uv](https://docs.astral.sh/uv/)
- Docker & Docker Compose
- An OpenAI API key (for vision model)
- A Cloudflare R2 bucket (for image storage)

### Backend Setup

1. **Start PostgreSQL:**
   ```bash
   docker compose up -d
   ```

2. **Configure environment** — create a `.env` in the project root:
   ```env
   PROJECT_NAME=IntelliPost
   SECRET_KEY=your-secret-key

   DATABASE_USER=postgres
   DATABASE_PASSWORD=postgres
   DATABASE_HOST=localhost
   DATABASE_PORT=5432
   DATABASE_NAME=intellipost

   R2_ACCOUNT_ID=your-cloudflare-account-id
   R2_ACCESS_KEY_ID=your-r2-access-key
   R2_SECRET_ACCESS_KEY=your-r2-secret-key
   R2_BUCKET_NAME=your-bucket-name

   OPENAI_API_KEY=your-openai-api-key
   VISION_MODEL_NAME=gpt-4o
   ```

3. **Install dependencies and run migrations:**
   ```bash
   uv sync
   uv run alembic upgrade head
   ```

4. **Start the API server:**
   ```bash
   uv run uvicorn backend.app.main:app --reload --port 8000
   ```

### Mobile App Setup

1. **Update the API URL** in `lib/core/config.dart` to point to your backend:
   ```dart
   class AppConfig {
     static const String apiBaseUrl = 'http://localhost:8000';
   }
   ```

2. **Run the app:**
   ```bash
   flutter pub get
   flutter run
   ```

### Docker Deployment

```bash
docker build -t intellipost .
docker compose up -d
docker run -p 8000:8000 --env-file .env intellipost
```

## Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Mobile | Flutter / Dart | Cross-platform UI |
| State | Provider (MVVM) | Reactive state management |
| Local DB | Hive | Offline scan cache |
| Camera | camera, image_picker | Image capture and import |
| Backend | FastAPI / Python 3.13 | REST API server |
| ORM | SQLModel | Async PostgreSQL ORM |
| Database | PostgreSQL 17 | Persistent storage |
| Migrations | Alembic | Schema versioning |
| Auth | JWT (HS256) + bcrypt | Stateless authentication |
| AI | Pydantic AI + OpenAI Vision | Structured envelope OCR |
| Storage | Cloudflare R2 (S3) | Image object storage |
| Deploy | Docker (multi-stage) | Production containerization |

## Project Structure

```
intellipost/
├── lib/                                # Flutter mobile app
│   ├── main.dart                       # Entry point, routing, providers
│   ├── core/
│   │   ├── config.dart                 # API base URL, timeouts
│   │   ├── theme/                      # Colors, text styles, ThemeData
│   │   └── widgets/                    # Shared UI components
│   ├── features/
│   │   ├── auth/
│   │   │   ├── view/                   # Login & register screens
│   │   │   └── viewmodel/              # Form validation, auth state
│   │   ├── home/
│   │   │   ├── view/                   # Home screen, scan list
│   │   │   └── viewmodel/              # Scan fetching, refresh
│   │   ├── scan/
│   │   │   ├── view/                   # Camera, preview, options sheet
│   │   │   └── viewmodel/              # Upload + process workflow
│   │   └── history/
│   │       ├── view/                   # History list, detail view
│   │       └── viewmodel/              # Filtering, sorting
│   ├── models/
│   │   ├── scan_model.dart             # ScanModel (Hive TypeAdapter)
│   │   └── user_model.dart             # UserModel (Hive TypeAdapter)
│   └── services/
│       ├── api_service.dart            # HTTP client, presigned upload, mail CRUD
│       ├── auth_service.dart           # Register, login, JWT storage
│       └── storage_service.dart        # Hive wrapper for local persistence
│
├── backend/                            # FastAPI backend
│   ├── app/
│   │   ├── main.py                     # FastAPI app, CORS, router mount
│   │   ├── api/
│   │   │   ├── deps.py                 # get_db session, get_current_user JWT dep
│   │   │   └── v1/
│   │   │       ├── api.py              # Router aggregator (/auth + /mails)
│   │   │       └── routers/
│   │   │           ├── auth.py         # POST /register, POST /login
│   │   │           └── mail.py         # Upload URL, process, list, get
│   │   ├── controllers/
│   │   │   ├── mail.py                 # Mail lifecycle: init → process → query
│   │   │   └── r2.py                   # File key generation + upload URL
│   │   ├── core/
│   │   │   ├── config.py              # Pydantic Settings, env vars, AI model init
│   │   │   ├── jwt.py                 # HS256 token create / decode
│   │   │   └── security.py            # bcrypt hash / verify
│   │   ├── crud/
│   │   │   ├── base_crud.py           # Generic async CRUD (get, create, update, remove)
│   │   │   └── user_crud.py           # User-specific: get_by_email, hashed create
│   │   ├── db/
│   │   │   └── database.py            # AsyncSession factory, connection pool
│   │   ├── models/
│   │   │   ├── base_model.py          # BaseUUIDModel (id, created_at, updated_at)
│   │   │   ├── user_model.py          # User table
│   │   │   ├── mail_model.py          # Mail table (status enum, AI fields)
│   │   │   ├── pincode_cache_model.py # Pincode → sorting center cache
│   │   │   └── enums/enums.py         # ProcessingStatus enum
│   │   ├── schemas/
│   │   │   ├── user_schema.py         # UserCreate, UserRead, UserLogin
│   │   │   └── agent_output_schema.py # VisionOutput (structured AI response)
│   │   ├── services/
│   │   │   ├── agent_service.py       # Pydantic AI agent wrapper
│   │   │   ├── r2_service.py          # boto3 S3 client for Cloudflare R2
│   │   │   └── pincode_lookup_service.py  # India Post API + DB cache
│   │   ├── prompts/
│   │   │   └── prompt.md              # Vision model system prompt
│   │   └── utils/
│   │       ├── agent.py               # Secondary AI agents (summary, sentiment)
│   │       ├── pdf_extractor.py       # PyPDF2 text extraction
│   │       └── report_generator.py    # Jinja2 + WeasyPrint PDF reports
│   ├── alembic/
│   │   ├── env.py                     # Async migration runner (SSL for NeonDB)
│   │   └── versions/                  # Migration scripts
│   └── alembic.ini                    # Alembic configuration
│
├── test/                               # Flutter unit tests
│   ├── models/
│   │   ├── scan_model_test.dart
│   │   └── user_model_test.dart
│   └── services/
│       ├── api_response_test.dart
│       └── auth_validation_test.dart
│
├── Dockerfile                          # Multi-stage Python build
├── docker-compose.yml                  # PostgreSQL 17 service
├── pyproject.toml                      # Python dependencies (uv)
├── pubspec.yaml                        # Flutter dependencies
└── .env                                # Environment variables (not committed)
```

## License

This project is licensed under the MIT License.
