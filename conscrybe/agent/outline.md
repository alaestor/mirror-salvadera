# ConScrybe Orchestrator - Project Outline

## Vision
ConScrybe is a pipeline-oriented contextual dictation tool. Instead of just transcribing audio, it uses existing CLI tools and LLMs to refine the output based on provided context (clipboard, files, prompts), effectively turning "speech-to-text" into "speech-to-intent".

## Architecture: The Pluggable Pipeline
The orchestrator acts as a state machine and glue layer. To avoid hardcoding and maximize flexibility, each stage of the pipeline is defined as a shell command template.

### Pipeline Stages
1. **Recorder**: (e.g., `sox -d -r 16000 -c 1 {output_file}`)
   - Input: System Microphone
   - Output: Audio File
2. **Transcriber**: (e.g., `whisper-cpp -m models/ggml-base.en.bin -f {input_file}`)
   - Input: Audio File
   - Output: Raw Text
3. **Refiner**: (e.g., `llm -s {system_prompt} "{input_text}\n\nContext: {context}"`)
   - Input: Raw Text + System Prompt + Context
   - Output: Refined Text
4. **Exporter**: (e.g., `wl-copy`)
   - Input: Refined Text
   - Output: System Clipboard / Typer

## GUI Requirements
The GUI (Python + PySide6) serves as the control center.

### Main Interface
- **State Control**:
    - Toggle Button: `Record` $\leftrightarrow$ `Stop/Commit`.
    - Abort Button: `Cancel` (stops current pipeline stage).
    - Status Indicator: Visual feedback on current state (Idle $\to$ Recording $\to$ Transcribing $\to$ Refining $\to$ Done).
- **Context Management**:
    - **System Prompt**: An editable text area to define the LLM's persona/rules for refinement.
    - **Working Context**: A chat-like area for active context. Supports text input and file drag-and-drop (which reads file contents into the context).
- **Log View**: A read-only area showing the raw output of the CLI tools for debugging.

### Settings Menu
- **Command Templates**: A list of text boxes for each pipeline stage.
- **Variables**: Templates use placeholders (e.g., `{input_file}`, `{context}`) that the orchestrator replaces at runtime.
- **Persistence**: Settings are saved to a config file (e.g., `~/.config/conscrybe/config.json`).

## Technical Implementation

### Orchestrator Core
- **State Machine**: Manages transitions between pipeline stages.
- **Process Management**: Uses `subprocess` with timeouts and signal handling (SIGINT) to control CLI tools.
- **Async Execution**: All pipeline steps run in a separate thread to keep the GUI responsive.

### Global Hotkeys (Wayland)
- **CLI Bridge**: Since Wayland prevents global key-listening in the GUI, a small CLI utility (`conscrybe-cli`) will communicate with the main GUI via a Unix Domain Socket.
- **User Setup**: Users bind `conscrybe-cli toggle` and `conscrybe-cli cancel` in their compositor settings (e.g., Hyprland/Sway).

### Packaging (Nix)
- **Python Package**: Bundles the orchestrator source and PySide6.
- **Meta-Package**: A default Nix flake output that ensures all required CLI tools (`sox`, `wl-clipboard`, `llm`, `whisper-cpp`) are installed and available in the environment.
