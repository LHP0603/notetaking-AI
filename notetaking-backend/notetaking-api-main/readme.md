# Meeting Summary API

This is a minimal FastAPI example project that implements a small meeting-summary endpoint to get you started.

Quick start (Windows PowerShell)

1. Create & activate virtual environment

```powershell
python -m venv .venv
# PowerShell activation
.\.venv\Scripts\Activate.ps1
```

2. Install dependencies

```powershell
pip install -r requirements.txt
```

3. Run the app (development server)

```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

4. Open docs

Visit http://127.0.0.1:8000/docs for interactive OpenAPI docs.

Run tests

```powershell
pip install pytest
pytest -q
```

Files added by this scaffold

- `app/main.py` — FastAPI app and example endpoints
- `requirements.txt` — pinned-ish dependency list
- `tests/test_main.py` — basic tests using FastAPI's TestClient
- `.gitignore` — ignores venv and pycache

