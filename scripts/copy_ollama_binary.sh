#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_ROOT="$PROJECT_DIR"

ASSETS_DIR="$SOURCE_ROOT/assets"
BINARY_NAME="ollama-darwin-arm64"
BINARY_SOURCE="$ASSETS_DIR/$BINARY_NAME"
BINARY_DEST="$CONFIGURATION_BUILD_DIR/$CONTENTS_FOLDER_PATH/MacOS/ollama"

if [ ! -f "$BINARY_SOURCE" ]; then
    echo "warning: Ollama binary not found at $BINARY_SOURCE"
    echo "warning: Download it from https://github.com/ollama/ollama/releases/download/v0.31.1/Ollama-darwin.zip"
    exit 0
fi

echo "Copying Ollama binary to app bundle..."
cp -f "$BINARY_SOURCE" "$BINARY_DEST"
chmod +x "$BINARY_DEST"
echo "Ollama binary copied to $BINARY_DEST"