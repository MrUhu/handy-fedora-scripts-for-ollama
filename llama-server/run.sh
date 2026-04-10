#!/bin/bash
set -e

# Logging configuration
LOG_FILE="llama-server_run_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Log function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "=== Script started ==="

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

log "=== Pulling newest Docker images ==="
docker compose pull

log "=== Starting services ==="
docker compose up

log "=== Script completed ==="