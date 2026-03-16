#!/bin/bash
set -e

PROJECT_DIR="/home/mruhu/Projekte/handy-fedora-scripts-for-ollama/llama-server"

# Move to that directory or exit if it fails
cd "$PROJECT_DIR" || { echo "Error: Directory not found"; exit 1; }

echo "=== Pulling newest Docker images ==="
docker compose pull

echo "=== Starting services ==="
docker compose up