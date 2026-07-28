# Ollama Sidecar macOS App

A Flutter macOS application that auto-detects Ollama on the local machine. If no Ollama server is found, the app silently downloads and installs Ollama in the background, then starts it for local AI chat.

## Features

- **Auto-Detect**: Checks `http://localhost:11434` on launch.
- **Auto-Install**: Downloads the Ollama release and installs it into `~/Library/Application Support/OllamaSidecar/ollama-bin` without embedding a binary in the app bundle.
- **Chat UI**: Streaming chat interface with message bubbles.
- **Model Management**: List available models and pull new models.
- **Settings**: Server status, paths, and server control.

## Architecture

```
Flutter UI (Dart)
    ↕ Method Channel (com.example.ollama_sidecar)
Native Swift (Process Manager + Installer)
    ↕ HTTP
Ollama API (localhost:11434)
```

## Project Structure

```
ollama_sidecar_app/
├── macos/
│   ├── Runner/
│   │   ├── AppDelegate.swift
│   │   ├── MainFlutterWindow.swift
│   │   ├── OllamaProcessManager.swift
│   │   └── OllamaMethodChannel.swift
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── services/
│   │   ├── ollama_api.dart
│   │   ├── ollama_process.dart
│   │   └── chat_service.dart
│   ├── models/
│   │   ├── message.dart
│   │   ├── ollama_model.dart
│   │   └── chat_session.dart
│   ├── screens/
│   │   ├── initialization_screen.dart
│   │   ├── engine_setup_screen.dart
│   │   ├── chat_screen.dart
│   │   ├── model_selector.dart
│   │   └── settings_screen.dart
│   └── widgets/
│       ├── message_bubble.dart
│       ├── streaming_text.dart
│       └── status_indicator.dart
├── pubspec.yaml
└── README.md
```

## Key Conventions

- **Method channel**: `com.example.ollama_sidecar`
- **Ollama API base URL**: `http://127.0.0.1:11434`
- **Model storage**: `~/Library/Application Support/OllamaSidecar/models`
- **Installed Ollama binary path**: `~/Library/Application Support/OllamaSidecar/ollama-bin/ollama`

## Dependencies

- `http` — Ollama REST API calls
- `provider` — state management
- `uuid` — message/session IDs

## Build Notes

- No embedded Ollama binary; the first launch triggers an auto-download if needed.
- Code signing required for macOS distribution.
- Entitlements include `com.apple.security.cs.allow-unsigned-executable-memory`, `com.apple.security.network.client`, `com.apple.security.network.server`.
- Minimum macOS deployment target: 14.0
- App sandbox is disabled to allow subprocess spawning and localhost network access

## Usage

1. Build the app: `flutter build macos`
2. Run the app: `flutter run -d macos`
3. On first launch, the app checks `localhost:11434`.
4. If no server is found, tap "ติดตั้ง Ollama อัตโนมัติ" to download and install Ollama in the background.
5. Use the UI to select models, pull models, and chat.

## Auto-Install Mechanism

- Source: `https://github.com/ollama/ollama/releases/latest/download/Ollama-darwin.zip`
- Destination: `~/Library/Application Support/OllamaSidecar/ollama-bin/ollama`
- Permissions: `0o755` set automatically
- After install, the app launches `ollama serve` pointing to `OLLAMA_MODELS` under the same support folder.

## Risks

- Download size: The Ollama darwin release is large (~50MB+); ensure network access is available.
- Network access: Requires network access on first install (entitlements allow it).
- Version drift: The downloaded binary follows the latest GitHub release, which may change without the app changing.
