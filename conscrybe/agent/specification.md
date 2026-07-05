# ConScrybe Orchestrator - Technical Specification

## 1. Component Definitions

### 1.1 Pipeline State Machine
The orchestrator implements a linear state machine:
`IDLE` $\to$ `RECORDING` $\to$ `TRANSCRIBING` $\to$ `REFINING` $\to$ `EXPORTING` $\to$ `IDLE`.

- **IDLE**: Waiting for `toggle` or `cancel` signal.
- **RECORDING**: Executes the `recorder_cmd`. Process is terminated via `SIGINT` on `Stop/Commit`.
- **TRANSCRIBING**: Executes the `transcriber_cmd`.
- **REFINING**: Executes the `refiner_cmd`.
- **EXPORTING**: Executes the `exporter_cmd`.

### 1.2 Command Templating
Commands are stored as strings in `config.json`. The orchestrator performs variable substitution:
- `{input_file}`: Path to the temporary audio file.
- `{output_file}`: Path where the recorder should save.
- `{input_text}`: The raw text output from the transcriber.
- `{context}`: The accumulated content from the Working Context area and `wl-paste`.
- `{system_prompt}`: The current content of the System Prompt text area.

### 1.3 Configuration Schema
```json
{
  "pipeline": {
    "recorder": "sox -d -r 16000 -c 1 {output_file}",
    "transcriber": "whisper-cpp -m ~/.cache/conscrybe/models/ggml-base.en.bin -f {input_file} --no-timestamps",
    "refiner": "llm -s \"{system_prompt}\" \"{input_text}\\n\\nContext: {context}\"",
    "exporter": "wl-copy"
  },
  "default_system_prompt": "You are a dictation refiner. Clean up the transcription for clarity and formatting based on context."
}
```

## 2. GUI Implementation Details

### 2.1 PySide6 Layout
- **Main Window**: `QMainWindow`
- **Central Widget**: `QVBoxLayout`
    - `QHBoxLayout` (Top): `QPushButton` (Toggle), `QPushButton` (Cancel), `QLabel` (Status).
    - `QTextEdit` (System Prompt): Multi-line editable.
    - `QTextEdit` (Working Context): Multi-line, supports `dropEvent` for files.
    - `QPlainTextEdit` (Log): Read-only, auto-scrolls to bottom.
- **Settings Dialog**: `QDialog` with a `QFormLayout` containing `QLineEdit` for each pipeline command.

### 2.2 Threading Model
- **Worker Thread**: A `QThread` or `QRunnable` manages the `subprocess` calls.
- **Signals**:
    - `statusChanged(str)` $\to$ Updates Status Label.
    - `logMessage(str)` $\to$ Appends to Log View.
    - `pipelineFinished()` $\to$ Returns UI to IDLE state.

## 3. IPC and CLI Bridge

### 3.1 Unix Socket
- **Server**: The GUI app creates a socket at `/tmp/conscrybe.sock`.
- **Protocol**: Simple text-based commands: `toggle\n`, `cancel\n`.
- **CLI Client**: A small Python script `conscrybe-cli` that connects to the socket, sends the command, and exits.

## 4. File System and Environment

### 4.1 Temporary Files
- Audio files are stored in `std.os.tempdir()` or `/tmp/conscrybe/`.
- Files are deleted immediately after the `transcriber` stage completes.

### 4.2 Nix Integration
- **`orchestrator` package**:
    - Build-time dependencies: `pyside6`.
    - Runtime dependencies: `python3`.
- **`conscrybe-default` package**:
    - Wraps `orchestrator` and adds `sox`, `wl-clipboard`, `llm`, `whisper-cpp` to the environment.
