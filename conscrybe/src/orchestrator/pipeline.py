import subprocess
import os
import tempfile
import json
import signal
import logging
from enum import Enum, auto
from typing import Dict, Optional

class State(Enum):
    IDLE = auto()
    RECORDING = auto()
    TRANSCRIBING = auto()
    REFINING = auto()
    EXPORTING = auto()

class PipelineError(Exception):
    pass

class Pipeline:
    def __init__(self, config: Dict, logger=None):
        self.config = config
        self.logger = logger
        self.state = State.IDLE
        self.current_process: Optional[subprocess.Popen] = None
        self.temp_audio: Optional[str] = None

    def _log(self, message: str):
        if self.logger:
            self.logger(message)

    def _substitute(self, template: str, variables: Dict[str, str]) -> str:
        return template.format(**variables)

    def execute_command(self, template: str, variables: Dict[str, str], input_text: Optional[str] = None) -> str:
        cmd = self._substitute(template, variables)
        self._log(f"Executing: {cmd}")

        try:
            if input_text:
                result = subprocess.run(
                    cmd,
                    shell=True,
                    input=input_text.encode('utf-8'),
                    capture_output=True,
                    text=True,
                    check=True
                )
                return result.stdout.strip()
            else:
                result = subprocess.run(
                    cmd,
                    shell=True,
                    capture_output=True,
                    text=True,
                    check=True
                )
                return result.stdout.strip()
        except subprocess.CalledProcessError as e:
            error_msg = e.stderr or e.stdout or str(e)
            self._log(f"Error executing command: {error_msg}")
            raise PipelineError(error_msg)

    def run_recorder(self, output_file: str):
        self.state = State.RECORDING
        self._log("Recording...")

        template = self.config['pipeline']['recorder']
        cmd = self._substitute(template, {'output_file': output_file})

        self.current_process = subprocess.Popen(
            cmd,
            shell=True,
            preexec_fn=os.setsid
        )

    def stop_recorder(self):
        if self.current_process:
            self._log("Stopping recording...")
            os.killpg(os.getpgid(self.current_process.pid), signal.SIGINT)
            self.current_process.wait()
            self.current_process = None

    def run_pipeline(self, system_prompt: str, context: str, log_callback):
        self.logger = log_callback

        try:
            # 1. Recording
            self.temp_audio = tempfile.NamedTemporaryFile(delete=False, suffix=".wav").name
            self.run_recorder(self.temp_audio)

            # Wait until stopped (this will be called from GUI thread via stop_recorder)
            # The actual transition to TRANSCRIBING happens after stop_recorder is called.

        except Exception as e:
            self._log(f"Pipeline failed: {str(e)}")
            raise

    def process_after_recording(self, system_prompt: str, context: str):
        try:
            # 2. Transcribing
            self.state = State.TRANSCRIBING
            self._log("Transcribing...")
            transcriber_cmd = self.config['pipeline']['transcriber']
            text = self.execute_command(
                transcriber_cmd,
                {'input_file': self.temp_audio}
            )
            self._log(f"Transcription: {text}")

            # 3. Refining
            self.state = State.REFINING
            self._log("Refining...")
            refiner_cmd = self.config['pipeline']['refiner']
            refined_text = self.execute_command(
                refiner_cmd,
                {'system_prompt': system_prompt, 'context': context},
                input_text=text
            )
            self._log(f"Refined: {refined_text}")

            # 4. Exporting
            self.state = State.EXPORTING
            self._log("Exporting...")
            exporter_cmd = self.config['pipeline']['exporter']
            self.execute_command(
                exporter_cmd,
                {},
                input_text=refined_text
            )
            self._log("Exported successfully.")

        except Exception as e:
            self._log(f"Pipeline failed during processing: {str(e)}")
            raise
        finally:
            if self.temp_audio and os.path.exists(self.temp_audio):
                os.remove(self.temp_audio)
            self.state = State.IDLE
            self._log("Idle.")
