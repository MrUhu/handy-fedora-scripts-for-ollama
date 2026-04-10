#!/bin/bash
set -e

# Logging configuration
LOG_FILE="llama-server_update_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Log function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "=== Script started ==="

# Upgrade system packages
log "Upgrading system packages"
sudo dnf upgrade -y || { log "Error: Package upgrade failed"; exit 1; }

# Update all system packages
log "Updating all system packages"
sudo dnf update -y || { log "Error: Package update failed"; exit 1; }

# Check if opencode is installed and executable before upgrading
if command -v opencode &> /dev/null; then
  log "Updating OpenCode"
  sudo opencode upgrade || { log "Error: OpenCode upgrade failed"; exit 1; }
else
  log "Warning: opencode is not installed or not in PATH, skipping upgrade"
fi

# Load environment variables from .env file if it exists
if [ -f .env ]; then
  set -a
  source .env
  set +a
  log "Loaded environment variables from .env"
else
  log "No .env file found, using default variables"
fi

# Get the directory where the script is located
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
log "Script directory: $SCRIPT_DIR"

# Change the working directory to that folder
cd "$SCRIPT_DIR"

# Use PROJECT_DIR from .env or default to current directory
PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
log "Project directory: $PROJECT_DIR"

# Move to that directory or exit if it fails
cd "$PROJECT_DIR" || { log "Error: Directory not found: $PROJECT_DIR"; exit 1; }
log "Successfully changed to project directory"

# Update Llama-Server and Qdrant Docker images
log "Updating Llama-Server and Qdrant"
docker compose pull

log "=== Script completed ==="
