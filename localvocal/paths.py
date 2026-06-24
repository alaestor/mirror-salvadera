import os
from pathlib import Path

def get_xdg_directory(env_var: str, default_path: str) -> Path:
    """
    Returns the directory specified by the environment variable,
    falling back to the default path if not set.
    """
    path = os.environ.get(env_var)
    if path:
        return Path(path)
    return Path(default_path).expanduser()

# XDG Base Directory Specification defaults
XDG_DATA_HOME = get_xdg_directory("XDG_DATA_HOME", "~/.local/share")
XDG_CACHE_HOME = get_xdg_directory("XDG_CACHE_HOME", "~/.cache")
XDG_CONFIG_HOME = get_xdg_directory("XDG_CONFIG_HOME", "~/.config")

# App specific directories
APP_NAME = "localvocal"
DATA_DIR = XDG_DATA_HOME / APP_NAME
CACHE_DIR = XDG_CACHE_HOME / APP_NAME

# Specific sub-paths
MODEL_DIR = DATA_DIR / "pocket-tts-full"
SAMPLES_DIR = DATA_DIR / "samples"
VOICE_CACHE_DIR = CACHE_DIR / "voices"
OUTPUT_DIR = DATA_DIR / "outputs"

def ensure_dirs():
    """Creates necessary XDG directories if they don't exist."""
    for d in [DATA_DIR, CACHE_DIR, MODEL_DIR, SAMPLES_DIR, VOICE_CACHE_DIR, OUTPUT_DIR]:
        d.mkdir(parents=True, exist_ok=True)
