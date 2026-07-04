import sys
import os
import json
import socket
import threading
from PySide6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QPushButton, QLabel, QTextEdit, QPlainTextEdit, QDialog,
    QFormLayout, QLineEdit, QMessageBox
)
from PySide6.QtCore import Qt, QThread, Signal, Slot
from PySide6.QtGui import QDragEnterEvent, QDropEvent

from pipeline import Pipeline, State

CONFIG_PATH = os.path.expanduser("~/.config/conscrybe/config.json")
SOCKET_PATH = "/tmp/conscrybe.sock"

DEFAULT_CONFIG = {
    "pipeline": {
        "recorder": "sox -d -r 16000 -c 1 {output_file}",
        "transcriber": "whisper-cpp -m ~/.cache/conscrybe/models/ggml-base.en.bin -f {input_file} --no-timestamps",
        "refiner": "llm -s \"{system_prompt}\" \"{input_text}\\n\\nContext: {context}\"",
        "exporter": "wl-copy"
    },
    "default_system_prompt": "You are a dictation refiner. Clean up the transcription for clarity and formatting based on context."
}

class PipelineWorker(QThread):
    statusChanged = Signal(str)
    logMessage = Signal(str)
    pipelineFinished = Signal()

    def __init__(self, pipeline, system_prompt, context):
        super().__init__()
        self.pipeline = pipeline
        self.system_prompt = system_prompt
        self.context = context
        self._stop_requested = False

    def run(self):
        try:
            self.pipeline.logger = self.logMessage.emit
            self.statusChanged.emit("RECORDING")

            # Start recording
            import tempfile
            self.pipeline.temp_audio = tempfile.NamedTemporaryFile(delete=False, suffix=".wav").name
            self.pipeline.run_recorder(self.pipeline.temp_audio)

            # The worker thread will now wait until the GUI tells the pipeline to stop recording
            # We loop here to keep the thread alive during recording
            while self.pipeline.state == State.RECORDING:
                if self._stop_requested:
                    # This case is for the 'Cancel' button
                    self.pipeline.stop_recorder()
                    self.pipelineFinished.emit()
                    return
                self.msleep(100)

            # Now process the recorded audio
            self.pipeline.process_after_recording(self.system_prompt, self.context)

        except Exception as e:
            self.logMessage.emit(f"Error: {str(e)}")
        finally:
            self.statusChanged.emit("IDLE")
            self.pipelineFinished.emit()

    def request_stop(self):
        self._stop_requested = True

class SettingsDialog(QDialog):
    def __init__(self, parent, config):
        super().__init__(parent)
        self.setWindowTitle("Settings")
        self.config = config

        layout = QFormLayout(self)
        self.inputs = {}

        for key, cmd in config['pipeline'].items():
            edit = QLineEdit(cmd)
            layout.addRow(f"{key}:", edit)
            self.inputs[key] = edit

        save_btn = QPushButton("Save")
        save_btn.clicked.connect(self.accept)
        layout.addRow(save_btn)

    def get_config(self):
        new_pipeline = {key: edit.text() for key, edit in self.inputs.items()}
        return {**self.config, "pipeline": new_pipeline}

class WorkingContextEdit(QTextEdit):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setAcceptDrops(True)

    def dragEnterEvent(self, event: QDragEnterEvent):
        if event.mimeData().hasUrls():
            event.acceptProposedAction()

    def dropEvent(self, event: QDropEvent):
        for url in event.mimeData().urls():
            file_path = url.toLocalFile()
            if os.path.isfile(file_path):
                try:
                    with open(file_path, 'r') as f:
                        content = f.read()
                    self.insertPlainText(f"\n--- File: {file_path} ---\n{content}\n")
                except Exception as e:
                    self.insertPlainText(f"\nError reading {file_path}: {e}\n")
        event.acceptProposedAction()

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("ConScrybe")
        self.setMinimumSize(600, 800)

        self.load_config()
        self.pipeline = Pipeline(self.config, logger=self.log_to_gui)
        self.worker = None

        self.setup_ui()
        self.start_ipc_server()

    def load_config(self):
        if os.path.exists(CONFIG_PATH):
            try:
                with open(CONFIG_PATH, 'r') as f:
                    self.config = json.load(f)
            except:
                self.config = DEFAULT_CONFIG
        else:
            self.config = DEFAULT_CONFIG

    def save_config(self):
        os.makedirs(os.path.dirname(CONFIG_PATH), exist_ok=True)
        with open(CONFIG_PATH, 'w') as f:
            json.dump(self.config, f, indent=2)

    def setup_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)

        # Top bar
        top_bar = QHBoxLayout()
        self.toggle_btn = QPushButton("Record")
        self.toggle_btn.clicked.connect(self.toggle_recording)

        self.cancel_btn = QPushButton("Cancel")
        self.cancel_btn.setEnabled(False)
        self.cancel_btn.clicked.connect(self.cancel_pipeline)

        self.status_lbl = QLabel("IDLE")

        top_bar.addWidget(self.toggle_btn)
        top_bar.addWidget(self.cancel_btn)
        top_bar.addWidget(self.status_lbl)
        layout.addLayout(top_bar)

        # System Prompt
        layout.addWidget(QLabel("System Prompt:"))
        self.prompt_edit = QTextEdit()
        self.prompt_edit.setPlainText(self.config.get("default_system_prompt", ""))
        layout.addWidget(self.prompt_edit)

        # Working Context
        layout.addWidget(QLabel("Working Context:"))
        self.context_edit = WorkingContextEdit()
        layout.addWidget(self.context_edit)

        # Log
        layout.addWidget(QLabel("Log:"))
        self.log_view = QPlainTextEdit()
        self.log_view.setReadOnly(True)
        layout.addWidget(self.log_view)

        # Menu
        menu = self.menuBar().addMenu("&Settings")
        settings_action = menu.addAction("Edit Pipeline")
        settings_action.triggered.connect(self.open_settings)

    def log_to_gui(self, message):
        self.log_view.appendPlainText(message)
        # Auto-scroll
        self.log_view.verticalScrollBar().setValue(self.log_view.verticalScrollBar().maximum())

    def open_settings(self):
        dlg = SettingsDialog(self, self.config)
        if dlg.exec():
            self.config = dlg.get_config()
            self.pipeline.config = self.config
            self.save_config()

    def toggle_recording(self):
        if self.pipeline.state == State.IDLE:
            self.start_pipeline()
        elif self.pipeline.state == State.RECORDING:
            self.stop_recording()

    def start_pipeline(self):
        self.toggle_btn.setText("Stop/Commit")
        self.cancel_btn.setEnabled(True)

        self.worker = PipelineWorker(
            self.pipeline,
            self.prompt_edit.toPlainText(),
            self.context_edit.toPlainText()
        )
        self.worker.statusChanged.connect(self.update_status)
        self.worker.logMessage.connect(self.log_to_gui)
        self.worker.pipelineFinished.connect(self.on_pipeline_finished)
        self.worker.start()

    def stop_recording(self):
        if self.pipeline.state == State.RECORDING:
            self.pipeline.stop_recorder()

    def cancel_pipeline(self):
        if self.worker:
            self.worker.request_stop()

    def update_status(self, state):
        self.status_lbl.setText(state)

    def on_pipeline_finished(self):
        self.toggle_btn.setText("Record")
        self.cancel_btn.setEnabled(False)
        self.status_lbl.setText("IDLE")

    def start_ipc_server(self):
        if os.path.exists(SOCKET_PATH):
            os.remove(SOCKET_PATH)

        def server_loop():
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.bind(SOCKET_PATH)
                s.listen(1)
                while True:
                    conn, _ = s.accept()
                    with conn:
                        data = conn.recv(1024)
                        if not data:
                            continue
                        cmd = data.decode('utf-8').strip().lower()
                        if cmd == "toggle":
                            self.toggle_recording()
                        elif cmd == "cancel":
                            self.cancel_pipeline()

        threading.Thread(target=server_loop, daemon=True).start()

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())
