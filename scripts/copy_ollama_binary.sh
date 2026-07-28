#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_ROOT="$PROJECT_DIR"

ASSETS_DIR="$SOURCE_ROOT/assets"
BINARY_NAME="ollama-darwin-arm64"
BINARY_SOURCE="$ASSETS_DIR/$BINARY_NAME"
BINARY_DEST="$CONFIGURATION_BUILD_DIR/$CONTENTS_FOLDER_PATH/MacOS/ollama"

LLAMA_SERVER_NAME="llama-server"
LLAMA_QUANTIZE_NAME="llama-quantize"

SYSTEM_OLLAMA_PATH=""
if [ -f "/opt/homebrew/Cellar/ollama/0.31.1/libexec/lib/ollama/llama-server" ]; then
    SYSTEM_OLLAMA_PATH="/opt/homebrew/Cellar/ollama/0.31.1/libexec/lib/ollama"
elif command -v ollama &>/dev/null; then
    OLLAMA_BIN="$(which ollama)"
    OLLAMA_DIR="$(dirname "$OLLAMA_BIN")"
    if [ -f "$OLLAMA_DIR/lib/ollama/llama-server" ]; then
        SYSTEM_OLLAMA_PATH="$OLLAMA_DIR/lib/ollama"
    fi
fi

if [ ! -f "$BINARY_SOURCE" ]; then
    echo "warning: Ollama binary not found at $BINARY_SOURCE"
    echo "warning: Download it from https://github.com/ollama/ollama/releases/download/v0.31.1/Ollama-darwin.zip"
    exit 0
fi

echo "Copying Ollama binary to app bundle..."
cp -f "$BINARY_SOURCE" "$BINARY_DEST"
chmod +x "$BINARY_DEST"
echo "Ollama binary copied to $BINARY_DEST"

MACOS_DIR="$(dirname "$BINARY_DEST")"
LIB_OLLAMA_DIR="$MACOS_DIR/lib/ollama"

mkdir -p "$LIB_OLLAMA_DIR"

if [ -n "$SYSTEM_OLLAMA_PATH" ] && [ -d "$SYSTEM_OLLAMA_PATH" ]; then
    if [ -f "$SYSTEM_OLLAMA_PATH/$LLAMA_SERVER_NAME" ]; then
        cp -f "$SYSTEM_OLLAMA_PATH/$LLAMA_SERVER_NAME" "$LIB_OLLAMA_DIR/$LLAMA_SERVER_NAME"
        chmod +x "$LIB_OLLAMA_DIR/$LLAMA_SERVER_NAME"
        echo "llama-server copied to $LIB_OLLAMA_DIR/$LLAMA_SERVER_NAME"
    fi
    if [ -f "$SYSTEM_OLLAMA_PATH/$LLAMA_QUANTIZE_NAME" ]; then
        cp -f "$SYSTEM_OLLAMA_PATH/$LLAMA_QUANTIZE_NAME" "$LIB_OLLAMA_DIR/$LLAMA_QUANTIZE_NAME"
        chmod +x "$LIB_OLLAMA_DIR/$LLAMA_QUANTIZE_NAME"
        echo "llama-quantize copied to $LIB_OLLAMA_DIR/$LLAMA_QUANTIZE_NAME"
    fi
else
    echo "warning: Could not find system Ollama llama-server/llama-quantize binaries"
fi