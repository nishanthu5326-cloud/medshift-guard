#!/bin/sh
cd "$(dirname "$0")/artifacts/medshift-guard/backend" && uv run uvicorn main:app --host 127.0.0.1 --port 8000
