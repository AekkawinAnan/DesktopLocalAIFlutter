# Ollama Sidecar macOS App

A Flutter macOS application that bundles the Ollama binary as an embedded sidecar for local AI chat. The app manages the Ollama server lifecycle internally and communicates with it via the local HTTP API, providing a self-contained local AI chat experience with no external Ollama installation required.

## Features

- **Embedded Ollama Binary**: Ollama v0.31.1 (arm64) bundled in the app bundle
- **Server Lifecycle Management**: Start/stop Ollama server from within the app
- **Chat UI**: Streaming chat interface with message bubbles
- **Model Management**: List available models and pull new models
- **Settings**: Server status, paths, and server control

## Architecture

```
Flutter UI (Dart)
    ↕ Platform Channels (com.example.ollama_sidecar)
Native Swift (Process Manager)
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
│   │   ├── OllamaMethodChannel.swift
│   │   └── ollama              # Embedded Ollama binary
│   ├── Runner.xcodeproj/
│   ├── Flutter/
│   └── Podfile
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
│   │   ├── chat_screen.dart
│   │   ├── model_selector.dart
│   │   └── settings_screen.dart
│   └── widgets/
│       ├── message_bubble.dart
│       ├── streaming_text.dart
│       └── status_indicator.dart
├── assets/
│   └── ollama-darwin-arm64
├── scripts/
│   └── copy_ollama_binary.sh
├── pubspec.yaml
└── README.md
```

## Key Conventions

- **Method channel**: `com.example.ollama_sidecar`
- **Ollama API base URL**: `http://127.0.0.1:11434`
- **Model storage**: `~/Library/Application Support/OllamaSidecar/models`
- **Ollama binary in bundle**: `Contents/MacOS/ollama`
- **Ollama binary runtime path**: `~/Library/Application Support/OllamaSidecar/ollama`

## Dependencies

- `http` — Ollama REST API calls
- `provider` — state management
- `uuid` — message/session IDs

## Build Notes

- Ollama binary is included in the Xcode project and copied to the app bundle during build
- Code signing required for macOS distribution
- Entitlements include `com.apple.security.cs.allow-unsigned-executable-memory` for running the embedded Ollama binary
- Minimum macOS deployment target: 14.0
- App sandbox is disabled to allow subprocess spawning and localhost network access

## Usage

1. Build the app: `flutter build macos`
2. Run the app: `flutter run -d macos`
3. On first launch, the app copies the Ollama binary to the writable support directory and starts the server
4. Use the UI to select models, pull models, and chat

## Risks

- The Ollama binary is ~31MB, increasing the app bundle size
- Code signing the embedded Ollama binary may be required for distribution
- Sandboxing restrictions may affect subprocess spawning in production builds
- The embedded binary matches the host architecture (arm64); universal binary support would require additional work