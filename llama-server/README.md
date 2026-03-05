# Llama-Server

A Docker-based setup for running local LLM services using llama.cpp with ROCm support for AMD GPUs.

## Overview

This directory contains configuration files to run a local LLM server environment with three main services:

1. **roo-brain** - The main LLM inference service (Devstral-Small-2-24B-Instruct)
2. **roo-embedder** - Embedding service (Qwen3-Embedding-0.6B)
3. **qdrant** - Vector database for storing and retrieving embeddings

## Components

### [`docker-compose.yml`](llama-server/docker-compose.yml:1)

The main configuration file that defines all services:

- **roo-brain**: Runs the Devstral-Small-2-24B-Instruct model for coding assistance
  - Uses ROCm for AMD GPU acceleration
  - Port: 11435
  - Custom chat template from [`devstral_template.jinja`](llama-server/devstral_template.jinja:1)
  
- **roo-embedder**: Runs the Qwen3-Embedding-0.6B model for text embeddings
  - Uses ROCm for AMD GPU acceleration  
  - Port: 11436
  - Optimized for embedding tasks
  
- **qdrant**: Vector database for storing embeddings
  - Persistent storage in `${HOME}/Dokumente/Coding-AI/qdrant`
  - Port: 6333

### [`run.sh`](llama-server/run.sh:1)

Simple bash script to start all services:
- Changes to the project directory
- Executes `docker compose up`

### [`Llama-Server.desktop`](llama-server/Llama-Server.desktop:1)

Desktop entry file for launching the server from the application menu:
- Opens a terminal window
- Executes the run script
- Includes custom icon

### [`devstral_template.jinja`](llama-server/devstral_template.jinja:1)

Custom chat template for the Devstral model, defining the prompt format and conversation structure.

## Usage

### Starting the Server

1. **From terminal**:
   ```bash
   cd llama-server
   ./run.sh
   ```

2. **From desktop**: Click the "Llama-Server" application icon

### Stopping the Server

Press `Ctrl+C` in the terminal where the services are running, or close the terminal window.

## Requirements

- Docker and Docker Compose
- AMD GPU with ROCm support
- Sufficient VRAM and system memory for the models
- Models downloaded to `${HOME}/Dokumente/Coding-AI/models`

## Notes

- The services are configured to use AMD ROCm for GPU acceleration
- HSA_OVERRIDE_GFX_VERSION is set to 11.0.0 for compatibility
- Models are loaded from a shared volume for persistence
- The qdrant service persists data to avoid losing embeddings on restart