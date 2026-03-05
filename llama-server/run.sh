#!/bin/bash
PROJECT_DIR="/home/user/path/to/repo/handy-fedora-scripts-for-ollama/llama-server"

# Move to that directory or exit if it fails
cd "$PROJECT_DIR" || { echo "Directory not found"; exit 1; }

# Start services
docker compose up