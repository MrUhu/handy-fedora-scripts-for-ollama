#!/bin/bash
set -e

# Load environment variables from .env file if it exists
if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

# Get the directory where the script is located
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Change the working directory to that folder
cd "$SCRIPT_DIR"

# Use PROJECT_DIR from .env or default to current directory
PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"

# Move to that directory or exit if it fails
cd "$PROJECT_DIR" || { echo "Error: Directory not found"; exit 1; }

echo "=== Pulling newest Docker images ==="
docker compose pull

echo "=== Starting services ==="
docker compose up