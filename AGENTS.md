## Project Overview

Bash scripts and Docker configurations for running Ollama and llama.cpp local LLM servers on **Fedora Linux** with **AMD GPU** (ROCm) support.

## Directory Structure

- **Root** — [`change_grubby_args_for_amd_igpu.sh`](change_grubby_args_for_amd_igpu.sh:1) configures AMD iGPU GTT memory via `grubby` kernel parameters
- **[`ollama/`](ollama/)** — Ollama management scripts (update, GPU-restricted modelfiles, model unloading)
- **[`llama-server/`](llama-server/)** — Docker Compose setup for llama.cpp server with ROCm

## Essential Commands

### Ollama Scripts
```bash
cd ollama && chmod +x *.sh
./update.sh                          # System update + Ollama upgrade + env var injection into /etc/systemd/system/ollama.service
./overwrite_gpu_restriction_to_modelfiles.sh [--dry-run]   # Creates "my"-prefixed modelfiles with num_gpu param
./unload_models.sh                   # Stops all loaded Ollama models
```

### Llama Server
```bash
cd llama-server
# Create .env from .env.example first
./run.sh                             # docker compose pull && docker compose up
```

### AMD iGPU Configuration
```bash
chmod +x ../change_grubby_args_for_amd_igpu.sh && ./change_grubby_args_for_amd_igpu.sh
# Requires reboot after execution
```

## Non-Obvious Conventions

- **All scripts require `bash`** — tested with `BASH_VERSION` check in root script
- **Logs directory**: All scripts write logs to `../logs/` relative to script location (e.g., `ollama/../logs/` = project root `logs/`)
- **Ollama env vars** are injected directly into `/etc/systemd/system/ollama.service` via `sed` — not via environment files
- **`ollama/update.sh`** uses `set -e` and pipes stdout/stderr to timestamped log files via `exec > >(tee -a "$LOG_FILE") 2>&1`
- **`.env` loading** in `llama-server/run.sh` uses `set -a` / `set +a` to auto-export all variables
- **Docker ports**: code-brain maps `11435:11434`, code-embedder maps `11436:11434` (internal port always 11434)
- **`HSA_OVERRIDE_GFX_VERSION=11.0.0`** is set in docker-compose.yml for AMD GPU compatibility
- **`overwrite_gpu_restriction_to_modelfiles.sh`** requires `jq` for JSON parsing and queries `http://localhost:11434/api/show` for block_count
- **All scripts requiring system changes need `sudo`/root privileges**

## Code Style (Bash)

- Use `set -e` for error exit in scripts that modify system state
- Log function pattern: `log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }`
- Directory resolution: `SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)`
- Input validation with regex: `[[ "$var" =~ ^[0-9]+$ ]]`
- Error handling with fallback: `command || { echo "Error message"; exit 1; }`
