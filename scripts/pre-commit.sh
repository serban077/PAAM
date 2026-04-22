#!/usr/bin/env bash
set -e

echo "→ flutter analyze lib/ ..."
flutter analyze lib/ --no-fatal-infos

echo "→ dart format check ..."
dart format --set-exit-if-changed lib/

echo "✓ Pre-commit checks passed."
