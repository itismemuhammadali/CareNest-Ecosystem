#!/usr/bin/env bash
# Install Supabase CLI binary (Linux amd64) — no npm required.
# Default install dir: ~/.local/bin (add to PATH in your shell RC).
set -euo pipefail
VER="${SUPABASE_CLI_VERSION:-v2.98.2}"
INSTALL_DIR="${SUPABASE_CLI_INSTALL_DIR:-$HOME/.local/bin}"
mkdir -p "$INSTALL_DIR"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"
curl -fsSL -o supabase.tgz "https://github.com/supabase/cli/releases/download/${VER}/supabase_linux_amd64.tar.gz"
tar -xzf supabase.tgz
install -m 0755 supabase "$INSTALL_DIR/supabase"
echo "Installed: $INSTALL_DIR/supabase"
"$INSTALL_DIR/supabase" --version
