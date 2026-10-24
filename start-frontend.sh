#!/bin/sh
cd "$(dirname "$0")" && pnpm install && cd artifacts/medshift-guard && pnpm dev
