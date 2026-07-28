# Ollama Sidecar macOS App

A Flutter macOS application that detects an installed Ollama server, or auto-downloads and installs Ollama on demand, then communicates with it via the local HTTP API for local AI chat.

## Project Structure

```
ollama_sidecar_app/
├── macos/
│   ├── Runner/
│   │   ├── AppDelegate.swift
│   │   ├── MainFlutterWindow.swift
│   │   ├── OllamaProcessManager.swift
│   │   └── OllamaMethodChannel.swift
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

- Method channel name: `com.example.ollama_sidecar`
- Ollama API base URL: `http://127.0.0.1:11434`
- Model storage: `~/Library/Application Support/OllamaSidecar/models`
- Ollama binary runtime path (after install): `~/Library/Application Support/OllamaSidecar/ollama-bin/ollama`

## Dependencies

- `http` — Ollama REST API calls
- `provider` — state management
- `uuid` — message/session IDs

## Build Notes

- Ollama binary is NOT bundled; it is auto-downloaded on first launch when missing
- Code signing required for macOS distribution
- Entitlements include `com.apple.security.cs.allow-unsigned-executable-memory` and `com.apple.security.network.client`
- Minimum macOS deployment target: 14.0
