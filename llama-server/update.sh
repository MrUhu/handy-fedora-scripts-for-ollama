#!/bin/bash
set -e

# Upgrade system packages
echo "Upgrade the packages"
sudo dnf upgrade -y || { echo "Package upgrade failed"; exit 1; }

# Update all system packages
echo "Updating all system packages"
sudo dnf update -y || { echo "Package update failed"; exit 1; }

# Check if opencode is installed and executable before upgrading
if command -v opencode &> /dev/null; then
  echo "Updating OpenCode"
  sudo opencode upgrade
else
  echo "Warning: opencode is not installed or not in PATH, skipping upgrade"
fi

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

# Update Llama-Server and Qdrant Docker images
echo "Updating Llama-Server and Qdrant"
docker compose pull
