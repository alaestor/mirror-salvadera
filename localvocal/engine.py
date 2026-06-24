import os
from pathlib import Path

import numpy as np
import sounddevice as sd
from pocket_tts import TTSModel, export_model_state
from paths import VOICE_CACHE_DIR


class TTSEngine:
    """
    Encapsulates the TTS model loading, voice state management, and audio playback.
    """

    def __init__(self, config_path: str, voice_prompt_path: str):
        self.config_path = config_path
        self.voice_prompt_path = voice_prompt_path

        # Load model
        self.model = TTSModel.load_model(config=config_path, quantize=True)
        # Load voice state (with caching)
        self.voice_state = self._load_voice_state()
        self.sample_rate = self.model.sample_rate

    def _load_voice_state(self):
        """
        Loads the voice state, using a cache of safetensors if available and valid.
        """
        # Only cache local files
        if not os.path.exists(self.voice_prompt_path):
            return self.model.get_state_for_audio_prompt(self.voice_prompt_path)

        # Create cache directory
        os.makedirs(VOICE_CACHE_DIR, exist_ok=True)

        # Use modified timestamp for cache validity
        mtime = int(os.path.getmtime(self.voice_prompt_path))
        filename = os.path.basename(self.voice_prompt_path)
        cache_path = str(VOICE_CACHE_DIR / f"{mtime}_{filename}.safetensors")

        if os.path.exists(cache_path):
            return self.model.get_state_for_audio_prompt(cache_path)

        # Cache miss: extract state and export to safetensors
        voice_state = self.model.get_state_for_audio_prompt(self.voice_prompt_path)
        export_model_state(voice_state, cache_path)
        return voice_state

    def stream(self, text: str):
        """
        Generates audio chunks from text.
        Yields:
            np.ndarray: Audio chunk as a numpy array.
        """
        for chunk in self.model.generate_audio_stream(self.voice_state, text):
            yield chunk.numpy() if hasattr(chunk, "numpy") else np.array(chunk)

    def speak(self, text: str):
        """
        Streams audio to the default output device in real-time.
        """
        with sd.OutputStream(
            samplerate=self.sample_rate, channels=1, dtype="float32"
        ) as stream:
            for chunk in self.stream(text):
                stream.write(chunk.astype("float32"))
