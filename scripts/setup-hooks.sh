#!/usr/bin/env bash
set -e

HOOKS_DIR="$(git rev-parse --show-toplevel)/.git/hooks"
cp scripts/pre-commit.sh "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-commit"
echo "✓ Pre-commit hook installed at $HOOKS_DIR/pre-commit"
echo "  It runs: flutter analyze lib/ + dart format check on every commit."
