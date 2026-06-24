import asyncio
import logging
import os
import sys

from mcp.server.fastmcp import FastMCP

from engine import TTSEngine

from paths import MODEL_DIR, SAMPLES_DIR, ensure_dirs
import os
from engine import TTSEngine

# Ensure XDG directories exist
ensure_dirs()

# Setup logging to stderr so it doesn't interfere with MCP stdio
logging.basicConfig(level=logging.INFO, stream=sys.stderr)

logger = logging.getLogger("LocalVocal")

# Configuration mirrored from speak.py
VOICE_PROMPT_PATH = str(SAMPLES_DIR / "hal9000.wav")
CONFIG_PATH = str(MODEL_DIR / "pocket-tts.config.yaml")

# Initialize FastMCP server
mcp = FastMCP("LocalVocal")

# Initialize TTS Engine globally
logger.info("Loading TTS Engine...")
try:
    engine = TTSEngine(CONFIG_PATH, VOICE_PROMPT_PATH)
    logger.info("TTS Engine loaded successfully.")
except Exception as e:
    logger.error(f"Failed to load TTS engine: {e}")
    engine = None


@mcp.tool()
async def speak(text: str) -> str:
    """
    Reads text aloud to the user. Input must be unformatted natural
    language comprised of pronouncable words or phonetic approximations
    such as: "the T T S engine loads the model dot safe tensors file."
    """
    if engine is None:
        return "Error: TTS Engine was not loaded on server startup."
    try:
        await asyncio.to_thread(engine.speak, text)
        return f"Successfully spoke: {text}"
    except Exception as e:
        return f"TTS Error: {str(e)}"


if __name__ == "__main__":
    mcp.run()
