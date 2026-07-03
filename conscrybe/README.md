# ConScrybe
> A contextual dictation transcriber.

*   **Transcription:** The literal conversion of audio signals into text. It focuses on phonetic accuracy—capturing *what* was said (e.g., "call one eighthundred five eight eight two threehundred" -> `call 1 (800) 588-2300`).
*   **Dictation:** The process of conveying instructions or structured information via speech. It focuses on **intent** and **formatting** (e.g., "the name of the file is quote name underscore text unquote" -> `the name of the file is "name_text"`).

ConScrybe is a pipeline-oriented tool 'intelligent' dictation. It enhances transcription by inferring semantic meaning from user-supplied context, such as clipboard contents, files, history, or explicit direction.

ConScrybe performs a two-stage process: it first performs high-fidelity *transcription* using Whisper, and then uses an LLM to perform intelligent *dictation refinement*.

## 🏗️ Architecture

ConScrybe uses composable components orchestrated by a GUI and tries leverage (rather than reinvent) existing tools.

### Components

1.  **`orchestrator` (The GUI)**: The control center and user interface (including keybinds). It manages state, holds configuration profiles, and moves data through the pipeline.
2.  **`recorder`**: A lightweight utility to capture audio from the system microphone and save it to a buffer or file.
3.  **`transcriber`**: A wrapper around Whisper that converts raw audio into unformatted text.
4.  **`fetchers`**: things used to add context.
4.  **`refiner`**: The brain: using an LLM to process the transcription, applying semantic rules and formatting based on provided context.
5.  **`exporter`**: The final step of the pipeline that serves as the output. Typically this is something like a clipboard manager, but it could also be anything else such as a file, a typer like [ydotools](https://github.com/ReimuNotMoe/ydotool), or a trigger for some [agentic workflow](https://hermes-agent.nousresearch.com/docs/reference/cli-commands#hermes--z-prompt--scripted-one-shot).

### Default Component Selection

| --- | --- |
| recorder | TBD |
| transcriber | TBD |
| refiner | in-house |

Default fetchers: TBD

The design aims to be simple and minimal enough that these components can be easily changed out and adapted as needed.

## 🛠️ Development & Deployment

ConScrybe is mostly hallucinated by local models.

The project uses a dendritic **[Nix Flake](https://nix.dev/concepts/flakes.html)** for distribution and dependency management.
