#!/usr/bin/env bash
pgrep -f "show-layers-kde.py" > /dev/null 2>&1 && exit 0
REPO="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$REPO/tools/show-layers-kde.py"
