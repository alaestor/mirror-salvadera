import os
import re
import sys
import zlib
from datetime import datetime

import numpy as np
import requests
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

# Configuration
LMSTUDIO_URL = "http://127.0.0.1:1234/v1/chat/completions"
VOICE_PROMPT_PATH = str(SAMPLES_DIR / "zone.wav")
CONFIG_PATH = str(MODEL_DIR / "pocket-tts.config.yaml")
DEBUG = False
AUDIO_ONLY = True
OUTPUT_PATH = str(OUTPUT_DIR)


def stream_llm_response(messages):
    """Streams a response from the LMStudio API."""
    payload = {
        "messages": messages,
        "temperature": 0.7,
        "max_tokens": -1,
        "stream": True,
    }
    try:
        response = requests.post(LMSTUDIO_URL, json=payload, timeout=30, stream=True)
        response.raise_for_status()

        for line in response.iter_lines():
            if line:
                line_text = line.decode("utf-8")
                if line_text.startswith("data: "):
                    data_content = line_text[6:]
                    if data_content == "[DONE]":
                        break

                    import json

                    try:
                        chunk = json.loads(data_content)
                        content = chunk["choices"][0]["delta"].get("content", "")
                        if content:
                            yield content
                    except json.JSONDecodeError:
                        continue
    except Exception as e:
        print(f"Error communicating with LLM: {e}", file=sys.stderr)
        yield f"Error: {e}"


def main():
    print("Initializing TTS Engine...")
    try:
        engine = TTSEngine(CONFIG_PATH, VOICE_PROMPT_PATH)
        print("TTS Engine loaded successfully.")
    except Exception as e:
        print(f"Failed to load TTS engine: {e}")
        return

    messages = [
        {
            "role": "system",
            "content": "You are a helpful, concise voice assistant. Keep your responses brief for better flow in voice communication.",
        }
    ]

    print("\n--- Verbal Query System Initialized ---")
    print("Type your message and press Enter. Press Ctrl+C to exit.\n")

    if OUTPUT_PATH:
        os.makedirs(OUTPUT_PATH, exist_ok=True)

    try:
        while True:
            user_input = input(" > ")
            if not user_input.strip():
                continue

            messages.append({"role": "user", "content": user_input})

            # Generate and play audio in real-time while streaming LLM response
            if DEBUG:
                print("Verbalizing response...")
            try:
                all_audio_data = []
                full_response_text = ""
                current_sentence = ""

                with sd.OutputStream(
                    samplerate=engine.sample_rate, channels=1, dtype="float32"
                ) as stream:
                    for text_chunk in stream_llm_response(messages):
                        full_response_text += text_chunk
                        current_sentence += text_chunk

                        # Split the accumulated buffer into speakable chunks based on major punctuation
                        # This regex finds sequences of characters ending with a major punctuation mark
                        # or a newline.
                        while True:
                            match = re.search(r"[^.!?\n]*[.!?\n]", current_sentence)
                            if not match:
                                break

                            sentence = match.group(0)
                            current_sentence = current_sentence[len(sentence) :]

                            if sentence.strip():
                                chunk_audio = list(engine.stream(sentence))
                                if chunk_audio:
                                    flat_chunk = np.concatenate(chunk_audio)
                                    float_data = flat_chunk.astype("float32")
                                    stream.write(float_data)
                                    all_audio_data.append(float_data)

                    # Handle remaining text in the buffer
                    if current_sentence.strip():
                        chunk_audio = list(engine.stream(current_sentence))
                        if chunk_audio:
                            flat_chunk = np.concatenate(chunk_audio)
                            float_data = flat_chunk.astype("float32")
                            stream.write(float_data)
                            all_audio_data.append(float_data)

                messages.append({"role": "assistant", "content": full_response_text})

                # Combine all chunks for saving to file
                if all_audio_data:
                    audio_data = np.concatenate(all_audio_data)
                    if OUTPUT_PATH:
                        timestamp = datetime.now().strftime("%Y%m%dT%H%M%S")
                        text_hash = f"{zlib.crc32(full_response_text.encode()):08x}"
                        base_name = f"{timestamp}-{text_hash}"

                        prompt_file = os.path.join(
                            OUTPUT_PATH, f"{base_name}-prompt.txt"
                        )
                        with open(prompt_file, "w", encoding="utf-8") as f:
                            f.write(full_response_text)

                        audio_file = os.path.join(OUTPUT_PATH, f"{base_name}-audio.wav")
                        wavfile.write(audio_file, engine.sample_rate, audio_data)
            except Exception as e:
                print(f"TTS Error: {e}")

    except KeyboardInterrupt:
        print("\nExiting Voice Chat.")


if __name__ == "__main__":
    main()
