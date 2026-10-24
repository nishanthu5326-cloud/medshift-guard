@echo off
cd /d "%~dp0artifacts\medshift-guard\backend"
uv run uvicorn main:app --host 127.0.0.1 --port 8000
pause
