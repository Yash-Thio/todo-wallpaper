#!/usr/bin/env bash
set -euo pipefail

ME="$(basename "$0")"

print_help() {
  cat <<EOF
Usage: $ME [--dry-run] [--user] [--system]

Installer for todo-wallpaper (convenience wrapper around pip/homebrew).

Options:
  --dry-run   Show what would be done, but don't install
  --user      Install into the user site (default when available)
  --system    Install system-wide (may require sudo)
  -h,--help   Show this help
EOF
}

DRY_RUN=0
INSTALL_USER=1

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --user) INSTALL_USER=1; shift ;;
    --system) INSTALL_USER=0; shift ;;
    -h|--help) print_help; exit 0 ;;
    *) echo "Unknown arg: $1"; print_help; exit 2 ;;
  esac
done

echo "todo-wallpaper installer"

# Prefer python3 from PATH
PY=python3
if ! command -v "$PY" >/dev/null 2>&1; then
  echo "Error: python3 not found in PATH"
  exit 1
fi

PIP_CMD="$PY -m pip"

# Choose install target
if [ "$INSTALL_USER" -eq 1 ]; then
  INSTALL_ARGS=(--user)
else
  INSTALL_ARGS=()
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY-RUN: Would run: $PIP_CMD install ${INSTALL_ARGS[*]} todo-wallpaper"
  exit 0
fi

echo "Installing todo-wallpaper via pip..."
exec $PIP_CMD install "${INSTALL_ARGS[@]}" todo-wallpaper
