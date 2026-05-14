# Ollama Management Scripts

Scripts for managing Ollama on **Fedora Linux** with **AMD GPU** (ROCm) support.

## Prerequisites

- **Fedora Linux** — scripts tested on Fedora; adjust for other distributions
- **`jq`** — required for `overwrite_gpu_restriction_to_modelfiles.sh` (JSON parsing)
- **`curl`** — required for `update.sh` (GitHub API queries)
- **`sudo`** privileges — required for system-level changes (systemd service modification)

---

## Scripts Overview

### `update.sh` — System + Ollama Update

Updates system packages, Ollama binary, and configures GPU environment variables.

**What it does:**

1. **System Package Updates**
   - Runs `dnf upgrade -y` and `dnf update -y`
   - Updates **opencode** if installed (`sudo opencode upgrade`)

2. **Ollama Version Management**
   - Queries GitHub API for latest Ollama release
   - Compares with local version (`ollama --version`)
   - Installs via `curl -fsSL https://ollama.com/install.sh | sh` if outdated

3. **GPU Configuration** — injects environment variables into `/etc/systemd/system/ollama.service` via `sed`:
   - `OLLAMA_VULKAN=1` — Enable Vulkan API for iGPU support (remove if your GPU is ROCm-native)
   - `OLLAMA_KV_CACHE_TYPE=q8_0` — Optimized KV cache type (4-bit quantized models)
   - `OLLAMA_NUM_PARALLEL=3` — Maximum parallel requests
   - `OLLAMA_MAX_LOADED_MODELS=3` — Maximum concurrently loaded models
   - `OLLAMA_KEEP_ALIVE=6h` — Keep models loaded for 6 hours after last use

4. **Service File Backup** — creates `/etc/systemd/system/ollama.service.bak` before modification

5. **Model Updates** — pulls latest versions of all installed models (skips `my*` prefixed models)

**Logging:** Timestamped logs written to `../logs/ollama_update_<YYYYMMDD_HHMMSS>.log`

**Usage:**
```bash
chmod +x update.sh
./update.sh
```

---

### `overwrite_gpu_restriction_to_modelfiles.sh` — GPU-Optimized Modelfiles

Creates modified modelfiles with `num_gpu` parameter for full GPU memory utilization (vRAM + GTT).

**What it does:**

1. Queries `http://localhost:11434/api/show` for each model's `block_count` from `model_info`
2. Falls back to `num_layers` from `details` if `block_count` unavailable
3. Adds `+1` to layer count for complete GPU offload
4. Creates modelfiles in `./models/` directory with sanitized filenames (`/` and `:` replaced with `_`)
5. Creates new models prefixed with `my` (e.g., `myllama3.1`)

**Options:**

| Flag | Behavior |
|------|----------|
| `--dry-run` | Preview changes without creating modelfiles or models |

**Usage:**
```bash
chmod +x overwrite_gpu_restriction_to_modelfiles.sh
./overwrite_gpu_restriction_to_modelfiles.sh          # Apply changes
./overwrite_gpu_restriction_to_modelfiles.sh --dry-run # Preview only
```

---

### `unload_models.sh` — Stop Loaded Models

Stops all currently loaded Ollama models to free GPU memory.

**What it does:**

1. Lists loaded models via `ollama ps` (skips header row with `tail -n +2`)
2. Extracts model names and stops each with `ollama stop <model>`

**Use case:** Testing multiple models sequentially; prevents GPU memory exhaustion.

**Usage:**
```bash
chmod +x unload_models.sh
./unload_models.sh
```

---

## Important Notes

- **AMD GPU compatibility** — `HSA_OVERRIDE_GFX_VERSION=11.0.0` may be needed if you encounter issues (llama-server handles this better via Docker Compose)
- **Service file backup** — `update.sh` creates `/etc/systemd/system/ollama.service.bak` before modifications
- **Logging directory** — all scripts write logs to `../logs/` relative to the script location
- **Environment variable injection** — env vars are injected directly into `/etc/systemd/system/ollama.service` via `sed`, not via environment files
- **`my*` prefixed models** — skipped during automatic model updates in `update.sh`
- **Usage at your own risk** — these scripts modify system configuration