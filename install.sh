#!/usr/bin/env bash
# Install the FedaPay skill into ~/.claude/skills/fedapay
set -euo pipefail

REPO="https://github.com/Perempty/fedapay-skill.git"
DEST="${1:-$HOME/.claude/skills/fedapay}"
TMP="$(mktemp -d)"

echo "Cloning $REPO ..."
git clone --depth 1 "$REPO" "$TMP"

echo "Installing into $DEST ..."
mkdir -p "$DEST/references"
cp "$TMP/SKILL.md" "$DEST/"
cp -r "$TMP/references/." "$DEST/references/"
rm -rf "$TMP"

echo "Done. Skill 'fedapay' installed at $DEST"
