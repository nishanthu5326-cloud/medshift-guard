# Run MedShift Guard locally (no Replit)

One-time installs: Node 20+ (nodejs.org), pnpm (`npm i -g pnpm`), uv (https://docs.astral.sh/uv/).

1. Double-click `start-backend.bat` (Mac/Linux: `./start-backend.sh`). First run downloads Python 3.11 and packages. Wait for "Application startup complete".
2. Double-click `start-frontend.bat` (Mac/Linux: `./start-frontend.sh`). First run installs packages.
3. Open http://localhost:5173

Check the API directly at http://127.0.0.1:8000/docs.
Before presenting: Settings page -> Reset demo data.

Notes: the app makes no external API calls. The Inter font loads from Google Fonts and falls back to a system font offline.
