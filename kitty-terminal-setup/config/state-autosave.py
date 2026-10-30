# Kitty Workspace Pack v1.6.0 — guarded automatic session persistence
# Uses the officially documented global Kitty watcher callbacks and the
# `kitten @ action` remote-control bridge. No foreground process replay.
# This module executes inside Kitty, not in the normal Python interpreter.
from __future__ import annotations

import os
import shlex
import shutil
import time
from pathlib import Path
from typing import Any

from kitty.boss import Boss
from kitty.fast_data_types import add_timer
from kitty.window import Window

AUTOSAVE_SECONDS = 10.0
MIN_EVENT_GAP = 1.0
BACKUP_GAP = 15 * 60
MAX_BACKUPS = 12

_config_dir = Path(
    os.environ.get('KITTY_CONFIG_DIRECTORY')
    or Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config'))) / 'kitty'
)
_state_dir = Path(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state'))) / 'kitty-workspace-pack'
STATE_FILE = _config_dir / 'last-state.kitty-session'
STAGING_FILE = _config_dir / 'last-state.kitty-session.autosave-tmp'
BACKUP_DIR = _state_dir / 'autosave-backups'
ERROR_FILE = _state_dir / 'autosave-error.log'

_last_save = 0.0
_last_backup = 0.0
_saving = False


def _report_error(message: str) -> None:
    """Only report generic errors. Never write session contents/commands."""
    try:
        ERROR_FILE.parent.mkdir(parents=True, exist_ok=True)
        with ERROR_FILE.open('a', encoding='utf-8') as f:
            f.write(f'{time.strftime("%Y-%m-%d %H:%M:%S")} {message}\n')
        ERROR_FILE.chmod(0o600)
        if ERROR_FILE.stat().st_size > 40_000:
            ERROR_FILE.write_text('Old autosave errors rotated.\n', encoding='utf-8')
    except OSError:
        pass


def _has_regular_window(boss: Boss) -> bool:
    # Quick-access terminals are separate Kitty instances. Do not allow a
    # quick-access instance to replace the main workspace's snapshot.
    try:
        windows = list(boss.list_os_windows())
        if not windows:
            return False
        return any(
            'kitty-quick-access' not in str(item.get('wm_class', '')).lower()
            and 'kitty-quick-access' not in str(item.get('wm_name', '')).lower()
            and 'kitty-quick-access' not in str(item.get('app_id', '')).lower()
            for item in windows
        )
    except Exception:
        # Some Kitty builds expose different window metadata; do not break
        # normal session saving just because this optional guard is unknown.
        return True


def _valid_snapshot(path: Path) -> bool:
    try:
        if not path.is_file() or path.stat().st_size < 12:
            return False
        if path.stat().st_size > 10 * 1024 * 1024:
            return False
        lines = path.read_text(encoding='utf-8').splitlines()
        commands = [line.strip().split(' ', 1)[0] for line in lines if line.strip() and not line.lstrip().startswith('#')]
        return 'new_tab' in commands and 'launch' in commands
    except (OSError, UnicodeError):
        return False


def _backup_current(now: float) -> None:
    global _last_backup
    if (_last_backup and now - _last_backup < BACKUP_GAP) or not _valid_snapshot(STATE_FILE):
        return
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    target = BACKUP_DIR / f'session-{time.strftime("%Y%m%d-%H%M%S")}.kitty-session'
    shutil.copy2(STATE_FILE, target)
    target.chmod(0o600)
    for old in sorted(BACKUP_DIR.glob('session-*.kitty-session'))[:-MAX_BACKUPS]:
        old.unlink(missing_ok=True)
    _last_backup = now


def _save(boss: Boss, window: Window | None = None, force: bool = False) -> None:
    global _saving, _last_save
    if _saving or not _has_regular_window(boss):
        return
    now = time.monotonic()
    if not force and now - _last_save < MIN_EVENT_GAP:
        return
    w = window or boss.active_window
    if w is None:
        return
    _saving = True
    try:
        STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
        # Never save directly over the last known-good state.
        STAGING_FILE.unlink(missing_ok=True)
        remote_action = f'save_as_session --save-only {shlex.quote(str(STAGING_FILE))}'
        result = boss.call_remote_control(w, ('action', remote_action))
        if isinstance(result, dict) and result.get('ok') is False:
            raise RuntimeError('Kitty reported a failed save action')
        if not _valid_snapshot(STAGING_FILE):
            raise ValueError('Generated session did not pass validation')
        _backup_current(now)
        STAGING_FILE.chmod(0o600)
        STAGING_FILE.replace(STATE_FILE)
        _last_save = now
    except Exception as e:
        _report_error(type(e).__name__ + ' while saving session (previous state retained)')
    finally:
        STAGING_FILE.unlink(missing_ok=True)
        _saving = False


def on_load(boss: Boss, data: dict[str, Any]) -> None:
    def periodic(timer_id: int | None) -> None:
        _save(boss)
    add_timer(periodic, AUTOSAVE_SECONDS, True)


def on_focus_change(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    if data.get('focused'):
        _save(boss, window)


def on_title_change(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    _save(boss, window)


def on_tab_bar_dirty(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    _save(boss, window)


def on_set_user_var(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    _save(boss, window)


def on_resize(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    old = data.get('old_geometry')
    if old is not None and getattr(old, 'xnum', 0) == 0 and getattr(old, 'ynum', 0) == 0:
        return
    _save(boss, window)


def on_close(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    # Let Kitty finish removing the closed tab before taking a snapshot.
    def after_close(timer_id: int | None) -> None:
        _save(boss, force=True)
    add_timer(after_close, 0.15, False)


def on_quit(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    if data.get('confirmed'):
        _save(boss, window, force=True)
