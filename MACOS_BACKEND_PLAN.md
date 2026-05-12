# macOS Wallpaper Backend Implementation Plan

## Overview

This document outlines the implementation of cross-platform wallpaper support for todo-wallpaper, adding macOS as a target platform alongside the existing Linux backend.

## Current State

- **Linux**: Uses GNOME `gsettings` (primary) and `feh` (fallback) via subprocess calls in `todo.py`
- **macOS**: Not supported; wallpaper setting will fail
- **Render.py**: Already cross-platform (Pillow works on all OSes)

## Target State

- **Linux**: Unchanged (GNOME + feh)
- **macOS**: Use AppleScript via `osascript` to set wallpaper
- **Cross-platform CLI**: `todo add`, `todo remove`, `todo list`, `todo init` work identically on both OSes

## Implementation Steps

### Step 1: Add macOS wallpaper setter to `todo.py`

Add a new function `set_macos_wallpaper(image_path: Path) -> bool`:

```python
def set_macos_wallpaper(image_path: Path) -> bool:
    """Set wallpaper using macOS AppleScript via osascript."""
    try:
        absolute_path = image_path.resolve()
        script = f'''tell application "Finder"
    set desktop picture to POSIX file "{absolute_path}"
end tell'''

        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
            check=True,
        )
        return True
    except (FileNotFoundError, subprocess.CalledProcessError):
        return False
```

### Step 2: Update `render()` function in `todo.py`

Modify the `render()` function to detect the platform and use the appropriate setter:

```python
def render() -> None:
    """Render wallpaper and set it on desktop (platform-aware)."""
    # ... existing render call ...

    # Platform detection
    import platform
    system = platform.system()

    if system == "Darwin":  # macOS
        if set_macos_wallpaper(WALLPAPER_FILE):
            print("✓ Wallpaper set (macOS)")
        else:
            print("✗ Failed to set wallpaper on macOS")
            exit(1)
    else:  # Linux and others
        if set_gnome_wallpaper(WALLPAPER_FILE):
            print("✓ Wallpaper set (GNOME)")
        elif set_feh_wallpaper(WALLPAPER_FILE):
            print("✓ Wallpaper set (feh)")
        else:
            print("✗ Failed to set wallpaper")
            exit(1)
```

### Step 3: Add `get_current_wallpaper()` macOS support (optional for v0.1.0)

For now, `save_wallpaper_path()` can store `None` on macOS since restoring the original wallpaper on task completion is less critical. This can be enhanced later using AppleScript to query current wallpaper (more complex).

### Step 4: Update `init.py` for cross-platform setup

Modify `init.py` to skip systemd setup on macOS:

```python
import platform

def main() -> int:
    print("=== Todo-Wallpaper Initialization ===\n")

    # ... existing setup steps ...

    # Step 3: Create systemd user service (Linux only)
    system = platform.system()
    if system == "Linux":
        print("\nStep 3: Setting up autostart...")
        SYSTEMD_DIR.mkdir(parents=True, exist_ok=True)
        # ... existing systemd setup ...
    elif system == "Darwin":
        print("\nStep 3: Setting up autostart (macOS launch agent)...")
        # For v0.1.0, we can skip launch agent setup
        # Users can manually add todo-wallpaper render to login items
        print("✓ Manual setup: Add ~/projects/random/todo-wallpaper to Login Items in System Preferences > General > Login Items")
        print("  Or run: todo init periodically from cron/launchd")

    # ... rest of setup ...
```

### Step 5: Update `pyproject.toml` for macOS support

Update the classifiers and description to advertise macOS support:

```toml
classifiers = [
  "Programming Language :: Python :: 3",
  "Programming Language :: Python :: 3.10",
  "Programming Language :: Python :: 3.11",
  "Programming Language :: Python :: 3.12",
  "Programming Language :: Python :: 3.13",
  "Operating System :: POSIX :: Linux",
  "Operating System :: MacOS",
  "Environment :: Console",
]
```

Update the description to mention macOS:

```toml
description = "A CLI todo list that renders as your desktop wallpaper (Linux & macOS)"
```

### Step 6: Test cross-platform

**On Linux:**

```bash
pip install todo-wallpaper
todo init
todo add "Test task"
todo list
```

**On macOS:**

```bash
pip install todo-wallpaper
todo init
todo add "Test task"
todo list
```

Verify:

- Wallpaper renders and updates on both platforms
- `todo init` skips systemd on macOS
- CLI commands work identically

## Known Limitations & Future Work

1. **macOS wallpaper restore**: Currently not implemented (stores `None` for wallpaper path). Can be added later using AppleScript `tell application "System Events" to get every picture`

2. **macOS launch agent**: In v0.1.0, we skip automatic startup. Users can:
   - Add to cron: `0 * * * * python3 <path>/render.py`
   - Create a LaunchAgent in ~/Library/LaunchAgents (v0.2.0+)
   - Or manually set in System Preferences

3. **Python 3.10+ requirement**: Ensure both platforms run Python 3.10+ (already specified in `pyproject.toml`)

## Files to Modify

1. **todo.py**: Add `set_macos_wallpaper()`, update `render()` with platform detection
2. **init.py**: Add platform detection to skip systemd on macOS
3. **pyproject.toml**: Update classifiers and description
4. **README.md**: Update installation/usage docs to mention macOS support

## Files to Create

- None; all changes are additive to existing files

## Acceptance Criteria

- [ ] `todo add "task"` works on macOS and Linux
- [ ] `todo list` works on macOS and Linux
- [ ] `todo remove N` works on macOS and Linux
- [ ] Wallpaper updates on task add/remove on both platforms
- [ ] `todo init` runs without errors on both platforms
- [ ] No breaking changes to Linux functionality
- [ ] All CLI commands produce identical output on both platforms

## Estimated Effort

- ~2-3 hours for coding, testing, and documentation
- Platform testing required on actual macOS machine

## Notes

- Use `osascript` for macOS wallpaper (no extra dependencies)
- Pillow (already required) handles cross-platform image rendering
- Keep Linux and macOS code paths separate but clean
- Test on macOS 12+ (Big Sur or later)
