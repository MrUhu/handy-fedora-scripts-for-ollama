# Handy Fedora Scripts for Ollama

A collection of scripts and configurations to optimize Ollama and local LLM workflows on Fedora Linux with AMD GPU support.

## Directory Structure

### Root Directory

This directory contains scripts for system configuration and Ollama management:

- [`change_grubby_args_for_amd_igpu.sh`](change_grubby_args_for_amd_igpu.sh:1) - Configures AMD iGPU memory settings
- [`README.md`](README.md:1) - This file

### [`ollama/`](ollama/README.md:1)

Scripts for managing Ollama and AMD GPU memory configuration:

- [`update.sh`](ollama/update.sh:1) - Updates system packages and Ollama
- [`overwrite_gpu_restriction_to_modelfiles.sh`](ollama/overwrite_gpu_restriction_to_modelfiles.sh:1) - Modifies model files for better GPU memory usage
- [`unload_models.sh`](ollama/unload_models.sh:1) - Unloads all Ollama models to free GPU memory
- [`README.md`](ollama/README.md:1) - Detailed documentation for ollama scripts

### [`llama-server/`](llama-server/README.md:1)

Docker-based local LLM server setup:

- [`docker-compose.yml`](llama-server/docker-compose.yml:1) - Main service configuration
- [`run.sh`](llama-server/run.sh:1) - Script to start all services
- [`Llama-Server.desktop`](llama-server/Llama-Server.desktop:1) - Desktop shortcut
- [`devstral_template.jinja`](llama-server/devstral_template.jinja:1) - Custom chat template
- [`README.md`](llama-server/README.md:1) - Detailed documentation for llama-server

## Scripts Overview

### `change_grubby_args_for_amd_igpu.sh`

Configures AMD iGPU memory settings for better LLM performance:

- Calculates and sets GTT (Graphics Transfer Table) memory size
- Updates kernel parameters for AMD GPU memory management
- Sets `amdgpu.cwsr_enable=0` to reduce crashes
- Requires system reboot to take effect

**Use Case**: Improve memory availability for LLMs when using AMD integrated graphics

## Usage

### For Ollama Users

```bash
cd ollama
chmod +x update.sh overwrite_gpu_restriction_to_modelfiles.sh unload_models.sh
./update.sh
```

### For Local LLM Server

```bash
cd llama-server
./run.sh
```

## System Requirements

- Fedora Linux (tested on Fedora 42)
- AMD GPU with ROCm support
- Sufficient system memory and VRAM for LLM workloads
- Docker and Docker Compose for llama-server

## Notes

- These scripts are tested on Fedora Linux
- Requires root privileges for some operations
- Use at your own risk
- Some scripts may need adjustment for non-Fedora distributions