#!/bin/bash
set -euo pipefail

# Build the Zellij Pane Sync plugin

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Ensure wasm32-wasi target is installed
rustup target add wasm32-wasip1 2>/dev/null || rustup target add wasm32-wasi 2>/dev/null || true

# Build the plugin
echo "Building zellij-pane-sync plugin..."
cargo build --release --target wasm32-wasip1 2>/dev/null || \
cargo build --release --target wasm32-wasi

# Find the built wasm file
WASM_FILE=""
if [ -f "target/wasm32-wasip1/release/zellij_pane_sync.wasm" ]; then
    WASM_FILE="target/wasm32-wasip1/release/zellij_pane_sync.wasm"
elif [ -f "target/wasm32-wasi/release/zellij_pane_sync.wasm" ]; then
    WASM_FILE="target/wasm32-wasi/release/zellij_pane_sync.wasm"
fi

if [ -z "$WASM_FILE" ]; then
    echo "Error: Could not find built wasm file"
    exit 1
fi

# Create plugins directory if needed
PLUGIN_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zellij/plugins"
mkdir -p "$PLUGIN_DIR"

# Copy the plugin
cp "$WASM_FILE" "$PLUGIN_DIR/zellij-pane-sync.wasm"

echo "Plugin installed to: $PLUGIN_DIR/zellij-pane-sync.wasm"
echo ""
echo "To use the plugin, start Zellij with the synced-workspace layout:"
echo "  zellij --layout synced-workspace"
