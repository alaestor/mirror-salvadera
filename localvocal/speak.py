import os
import sys
import zlib
from datetime import datetime

import numpy as np
import sounddevice as sd
from scipy.io import wavfile

from engine import TTSEngine
from paths import MODEL_DIR, SAMPLES_DIR, OUTPUT_DIR, ensure_dirs
import os
import zlib
import numpy as np
from datetime import datetime
from scipy.io.wavfile import write as wavwrite

# Ensure XDG directories exist
ensure_dirs()

# Configuration (mirrored from chat.py)
VOICE_PROMPT_PATH = str(SAMPLES_DIR / "hal9000.wav")
CONFIG_PATH = str(MODEL_DIR / "pocket-tts.config.yaml")
OUTPUT_PATH = "./outputs"


def speak(text, engine):
    try:
        audio_data = []
        for chunk in engine.stream(text):
            audio_data.append(chunk)

        if audio_data:
            full_audio = np.concatenate(audio_data)
            # Play the audio
            with sd.OutputStream(
                samplerate=engine.sample_rate, channels=1, dtype="float32"
            ) as stream:
                stream.write(full_audio.astype("float32"))

            # Save the result if OUTPUT_PATH is set
            if OUTPUT_PATH:
                os.makedirs(OUTPUT_PATH, exist_ok=True)
                timestamp = datetime.now().strftime("%Y%m%dT%H%M%S")
                text_hash = f"{zlib.crc32(text.encode()):08x}"
                base_name = f"{timestamp}-{text_hash}"

                prompt_file = os.path.join(OUTPUT_PATH, f"{base_name}-prompt.txt")
                with open(prompt_file, "w", encoding="utf-8") as f:
                    f.write(text)

                audio_file = os.path.join(OUTPUT_PATH, f"{base_name}-audio.wav")
                wavfile.write(audio_file, engine.sample_rate, full_audio)

    except Exception as e:
        print(f"Error speaking/saving: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    last_text = None

    try:
        engine = TTSEngine(CONFIG_PATH, VOICE_PROMPT_PATH)
    except Exception as e:
        print(f"Failed to load TTS engine: {e}")
        sys.exit(1)

    if len(sys.argv) > 1:
        text_to_speak = " ".join(sys.argv[1:])
        speak(text_to_speak, engine)
    else:
        print("\n--- Text-to-Speech Input Mode ---")
        print("Type your message and press Enter. Press Ctrl+C to exit.\n")
        try:
            while True:
                user_input = input(" > ").strip()

                if not user_input:
                    continue

                if user_input == "/r":
                    if last_text is not None:
                        user_input = last_text
                    else:
                        print("No previous prompt to repeat.")
                        continue

                last_text = user_input
                speak(user_input, engine)

        except KeyboardInterrupt:
            print("\nExiting TTS mode.")
            sys.exit(0)
