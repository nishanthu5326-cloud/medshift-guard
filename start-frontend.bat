@echo off
cd /d "%~dp0"
call pnpm install
cd artifacts\medshift-guard
pnpm dev
pause
