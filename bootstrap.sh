#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.local/share/chezmoi"

if [ "$REPO_DIR" != "$TARGET" ]; then
    if [ -e "$TARGET" ]; then
        echo "[!] $TARGET already exists." >&2
        echo "    Move or remove it manually before re-running bootstrap." >&2
        exit 1
    fi
    mkdir -p "$(dirname "$TARGET")"
    echo "[*] moving $REPO_DIR -> $TARGET"
    mv "$REPO_DIR" "$TARGET"
    REPO_DIR="$TARGET"
fi

if ! [ -x "$HOME/.local/bin/mise" ]; then
    command -v curl >/dev/null 2>&1 || { echo "[!] curl not found. Install curl first (distro-provided)." >&2; exit 1; }
    echo "[*] installing mise via mise.run..."
    curl -fsSL https://mise.run | MISE_INSTALL_PATH="$HOME/.local/bin/mise" MISE_INSTALL_MUSL=1 sh
fi
export PATH="$HOME/.local/bin:$PATH"

if ! [ -x "$HOME/.local/bin/mise" ]; then
    echo "[!] mise install appears to have failed: $HOME/.local/bin/mise not executable" >&2
    exit 1
fi
echo "[=] mise: $(mise --version)"

if ! [ -x "$HOME/.local/bin/chezmoi" ]; then
    echo "[*] installing chezmoi via get.chezmoi.io..."
    sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi

echo "[*] running chezmoi init --apply..."
"$HOME/.local/bin/chezmoi" init --apply

echo "[OK] bootstrap complete. Repo: $REPO_DIR"
echo "    Open a new shell or run: export PATH=\"\$HOME/.local/bin:\$PATH\" && exec bash"
