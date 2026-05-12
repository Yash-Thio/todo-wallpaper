# Todo Wallpaper Repo Guide

This repository renders a Linux desktop wallpaper from a JSON todo list and exposes a `todo` command for day-to-day use.

## What Matters

- The main source files are [todo.py](todo.py), [render.py](render.py), and [init.py](init.py).
- The user-facing command is `todo`, implemented by the wrapper script in [todo](todo).
- The wallpaper is updated through GNOME `gsettings` first, with `feh` as a fallback.
- The first `todo add` captures the current wallpaper path before the app overwrites it.
- When the todo list becomes empty, the app restores the saved wallpaper path if it exists; otherwise it uses a generated "All Tasks Done!" fallback image.
- Todo numbering is 1-based everywhere. `todo remove 1` removes the first item.

## Repository Layout

- [todo.py](todo.py): CLI for add/remove/list. It saves to `todos.json`, renders the wallpaper, and sets it on the desktop.
- [render.py](render.py): Renders `wallpaper.png` from `todos.json` using Pillow.
- [init.py](init.py): One-time setup. It runs setup, installs the wrapper into `~/.local/bin`, and enables the systemd user service.
- [todo](todo): Shell wrapper that resolves its own path and forwards to `python3 todo.py`.
- [setup.py](setup.py): Dependency and environment checker used during setup only.
- [watch.py](watch.py): Optional file-watcher mode. Not part of the normal workflow.
- [todo-wallpaper-init.service](todo-wallpaper-init.service): systemd user service template. `init.py` writes the active user service to `~/.config/systemd/user/`.
- [todos.json](todos.json): Persistent todo storage with metadata. It stores `tasks` plus `wallpaper_path` for wallpaper restoration.
- [wallpaper.png](wallpaper.png): Generated output. Safe to regenerate.

## Normal Workflow

1. Use `todo add "task"` from anywhere.
2. If the list was empty, `todo.py` captures the current wallpaper path from GNOME `gsettings` before saving the first task.
3. `todo.py` updates `todos.json`, then `render.py` regenerates `wallpaper.png`.
4. `todo.py` sets the desktop wallpaper with GNOME `gsettings`.
5. When the list becomes empty, `todo.py` restores the saved wallpaper path if it still exists; otherwise it renders and sets the fallback "All Tasks Done!" image.

## Setup Flow

- Run `python3 init.py` for a complete local setup.
- It installs the wrapper into `~/.local/bin/todo` and enables the `todo-wallpaper-init.service` user service.
- If `~/.local/bin` is not on PATH, the command will not be available globally until PATH is updated.

## Conventions

- Keep paths absolute inside the Python scripts when they are invoked from subprocesses.
- Prefer small, direct edits over broad refactors.
- Preserve the 1-based user-facing numbering.
- Only capture `wallpaper_path` on the 0->1 transition so the original wallpaper is not overwritten.
- Do not hand-edit generated artifacts unless you are intentionally resetting state.

## Things To Avoid

- Do not switch indexing back to 0-based in the CLI or docs.
- Do not remove the GNOME wallpaper path unless you are explicitly changing desktop integration.
- Do not overwrite `wallpaper_path` after the first capture.
- Do not treat `wallpaper.png` as source control state; it is generated output.

## Helpful Commands

- `todo add "Buy groceries"`
- `todo list`
- `todo remove 1`
- `python3 render.py`
- `python3 setup.py`
- `python3 init.py`

## Implementation Notes

- The wrapper script uses `readlink -f` so it still works when installed as a symlink in `~/.local/bin`.
- `todo.py` tries GNOME first and falls back to `feh` if needed.
- `todo.py` reads the current wallpaper URI from GNOME `gsettings` before the first task is added, and falls back to parsing `~/.fehbg` if needed.
- `render.py` supports a `--done` mode that generates the fallback "All Tasks Done!" image.
- `render.py` only renders the image; wallpaper selection is handled elsewhere.
