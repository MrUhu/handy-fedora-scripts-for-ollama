# Llama-Server

A Docker Compose setup for running llama.cpp local LLM servers on **Fedora Linux** with **AMD GPU (ROCm)** support.

## Overview

This directory contains configuration files to run a local LLM server environment with three services:

| Service | Purpose | Image | Model |
|---------|---------|-------|-------|
| **code-brain** | Main LLM inference service | `ghcr.io/ggml-org/llama.cpp:server-rocm` | `unsloth/Qwen3.6-35B-A3B-GGUF:UD-Q4_K_XL` |
| **code-embedder** | Text embedding service | `ghcr.io/ggml-org/llama.cpp:server-rocm` | `Qwen/Qwen3-Embedding-0.6B-GGUF:Q8_0` |
| **code-archive** | Vector database for embeddings | `qdrant/qdrant:latest` | — |

## Prerequisites

- **Fedora Linux** with AMD GPU
- **Docker** and **Docker Compose** v2 installed
- **AMD GPU** with ROCm drivers (`/dev/kfd` and `/dev/dri` available)
- Sufficient VRAM and system memory for the models
- `curl` installed (required for health checks inside containers)

## Setup Instructions

### 1. Create `.env` file

Create a `.env` file in this directory based on the [`.env.example`](.env.example) template:

```bash
cp .env.example .env
```

Edit `.env` to set your paths:

```bash
# Base directory for volumes (models and qdrant)
VOLUME_DIR=/path/to/your/volumes
```

### 2. Run the server

```bash
chmod +x *.sh
./run.sh
```

The [`run.sh`](run.sh) script:
- Loads environment variables from `.env` using `set -a` / `set +a` to auto-export all variables
- Pulls the latest Docker images with `docker compose pull`
- Starts all services with `docker compose up`

## Essential Commands

```bash
cd llama-server && chmod +x *.sh

./run.sh                             # Pull latest images && start all services (foreground)
./update.sh                          # System upgrade + update Docker images (pull only)
```

### Update Script

The [`update.sh`](update.sh) script performs:
1. System package upgrade via `sudo dnf upgrade -y`
2. System package update via `sudo dnf update -y`
3. OpenCode upgrade (if installed)
4. Docker image update via `docker compose pull`

## Docker Compose Configuration

### Services

#### code-brain (roo-brain)

Main LLM inference service with the following configuration:

| Parameter | Value | Description |
|-----------|-------|-------------|
| Image | `ghcr.io/ggml-org/llama.cpp:server-rocm` | llama.cpp server with ROCm support |
| Internal Port | `11434` | Port inside container |
| Host Port | `11435` | Mapped to host via `11435:11434` |
| Context Size | `196608` | Token context window - `65546` per slot |
| Cache Type K | `q8_0` | Key cache precision |
| Cache Type V | `q4_0` | Value cache precision |
| GPU Layers | `99` | Maximize GPU offload (`-ngl 99`) |
| Batch Size | `128` | Regular batch (`-b 128`) |
| Unbatch Size | `512` | Unbatched size (`-ub 512`) |
| Threads | `8` | CPU threads (`--threads 8`) |
| Parallel | `3` | Request parallelism (`--parallel 3`) |
| Continuous Batching | `on` | Handles cache more dynamically between slots |
| Temperature | `0.6` | Sampling temperature (`--temp 0.6`) |
| Top-P | `0.95` | Nucleus sampling (`--top-p 0.95`) |
| Top-K | `20` | Top-K sampling (`--top-k 20`) |
| Min-P | `0.0` | Min-P filtering (`--min-p 0.0`) |
| Presence Penalty | `0.0` | Presence penalty (`--presence-penalty 0.0`) |
| Repeat Penalty | `1.0` | Repeat penalty (`--repeat-penalty 1.0`) |
| Flash Attention | `on` | Enabled (`--flash-attn on`) |
| Memory Limit | `32G` | Max container memory |
| CPU Limit | `8` | Max CPU cores |
| Memory Reservation | `16G` | Guaranteed minimum memory |
| CPU Reservation | `4` | Guaranteed minimum CPU cores |

#### code-embedder (roo-embedder)

Text embedding service optimized for embedding tasks:

| Parameter | Value | Description |
|-----------|-------|-------------|
| Image | `ghcr.io/ggml-org/llama.cpp:server-rocm` | llama.cpp server with ROCm support |
| Internal Port | `11434` | Port inside container |
| Host Port | `11436` | Mapped to host via `11436:11434` |
| Context Size | `4096` | Token context window (`-c 4096`) |
| GPU Layers | `99` | Maximize GPU offload (`-ngl 99`) |
| Embedding Mode | Enabled | Activated via `--embedding` flag |
| Memory Limit | `4G` | Max container memory |
| CPU Limit | `4` | Max CPU cores |
| Memory Reservation | `2G` | Guaranteed minimum memory |
| CPU Reservation | `2` | Guaranteed minimum CPU cores |

#### code-archive (qdrant)

Vector database for storing and persisting embeddings:

| Parameter | Value | Description |
|-----------|-------|-------------|
| Image | `qdrant/qdrant:latest` | Qdrant vector database |
| Host Port | `6333` | Mapped to `6333:6333` |
| Storage | `${VOLUME_DIR}/qdrant` | Persistent volume for embeddings |
| Memory Limit | `8G` | Max container memory |
| CPU Limit | `4` | Max CPU cores |
| Memory Reservation | `4G` | Guaranteed minimum memory |
| CPU Reservation | `2` | Guaranteed minimum CPU cores |

### Port Summary

| Service | Host Port | Internal Port | Purpose |
|---------|-----------|---------------|---------|
| code-brain | `11435` | `11434` | LLM inference API |
| code-embedder | `11436` | `11434` | Embedding API |
| code-archive | `6333` | `6333` | Qdrant vector DB API |

> **Note:** Both `code-brain` and `code-embedder` use internal port `11434` but are mapped to different host ports to avoid conflicts.

### GPU Configuration

Both llama.cpp services are configured with:

```yaml
devices:
  - "/dev/kfd:/dev/kfd"
  - "/dev/dri:/dev/dri"
```

This grants the containers direct access to the AMD GPU devices required for ROCm acceleration.

## Environment Variables

The [`.env`](.env.example) file supports the following variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PROJECT_DIR` | Current directory | Base directory for the project |
| `VOLUME_DIR` | — | Base directory for model and data volumes (`${VOLUME_DIR}/models` for HuggingFace cache, `${VOLUME_DIR}/qdrant` for vector DB storage) |

## AMD GPU Configuration

### HSA_OVERRIDE_GFX_VERSION

Both llama.cpp services set:

```yaml
environment:
  - HSA_OVERRIDE_GFX_VERSION=11.0.0
```

This environment variable overrides the GPU architecture detection to version `11.0.0`, ensuring compatibility with your AMD GPU. This is a common workaround for ROCm compatibility issues on newer AMD hardware.

### GGML_HIP_VISIBLE_DEVICES

The `code-brain` service additionally sets:

```yaml
environment:
  - GGML_HIP_VISIBLE_DEVICES=0
```

This restricts the model to use GPU device 0 (the first AMD GPU).

## Non-Obvious Conventions

- **All scripts require `bash`** — uses `BASH_VERSION` resolution via `BASH_SOURCE`
- **Logging**: All scripts write logs to `../logs/` relative to script location (e.g., `llama-server/../logs/` = project root `logs/`)
- **Log file naming**: Timestamped format — `llama-server_run_YYYYMMDD_HHMMSS.log` and `llama-server_update_YYYYMMDD_HHMMSS.log`
- **Log format**: `[YYYY-MM-DD HH:MM:SS] message`
- **`.env` loading**: Scripts use `set -a` / `set +a` to auto-export all variables from `.env` into the environment
- **Health checks**: All services have health checks using `curl -f` against their host-mapped ports
- **Restart policy**: All services use `restart: unless-stopped`
- **Logging driver**: All services use `json-file` driver with `max-size: 100m` and `max-file: 3` rotation
- **Network**: All services share a bridge network named `llama-network`

## Usage

### Starting the Server

```bash
cd llama-server
./run.sh
```

### Stopping the Server

Press `Ctrl+C` in the terminal where the services are running, or run:

```bash
docker compose down
```

### Updating Images

```bash
./update.sh    # Full system + image update
# Or just pull images:
docker compose pull
```

## Directory Structure

```
llama-server/
├── .env.example              # Environment variable template
├── docker-compose.yml        # Docker Compose configuration
├── run.sh                    # Start services script
├── update.sh                 # Update system and images script
├── Llama-Server.desktop      # Desktop entry for application menu
├── devstral_template.jinja   # Custom chat template (unused)
└── README.md                 # This file
```
