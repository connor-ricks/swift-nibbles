#!/bin/sh

echo "Setting up local git hooks..."
PROJECT_DIR="$(git rev-parse --show-toplevel)"
git config --local core.hooksPath "${PROJECT_DIR}/scripts/hooks/"
chmod u+x "${PROJECT_DIR}/scripts/hooks/commit-msg"
echo "Local git hooks setup."
