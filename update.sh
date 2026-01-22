#!/bin/bash
#!/bin/bash

# Function to backup service file before modification - just in case
backup_service_file() {
    if [ -f /etc/systemd/system/ollama.service ]; then
        sudo cp /etc/systemd/system/ollama.service /etc/systemd/system/ollama.service.bak
        echo "Backup created: /etc/systemd/system/ollama.service.bak"
    fi
}

# Function to add environment variables to ollama service
add_ollama_env_vars() {
    if [ -f /etc/systemd/system/ollama.service ]; then
        # Check if variables already exist
        # Most models are quantized to 4 Bits in the Ollama library - so the KV cache will also be quantized to 4 Bits
        # Feel free to change this, if you need a more precise KV cache
        if ! grep -q 'OLLAMA_KV_CACHE_TYPE' /etc/systemd/system/ollama.service; then
            # Backup before modifying
            backup_service_file

            # Add the environment variable lines after [Service] section
            # If your GPU is officially supported by ROCm remove the OLLAMA_VULKAN line
            # Otherwise keep it in for reliability reasons
            sudo sed -i '/\[Service\]/a Environment="OLLAMA_VULKAN=1"' /etc/systemd/system/ollama.service
            sudo sed -i '/\[Service\]/a Environment="OLLAMA_KV_CACHE_TYPE=q4_0"' /etc/systemd/system/ollama.service
            sudo sed -i '/\[Service\]/a Environment="OLLAMA_NUM_PARALLEL=3"' /etc/systemd/system/ollama.service
            sudo sed -i '/\[Service\]/a Environment="OLLAMA_MAX_LOADED_MODELS=3"' /etc/systemd/system/ollama.service
            echo "Environment variables added"

            # Restart Ollama with GPU enabled
            echo "Restarting Ollama with GPU enabled"
            sudo systemctl daemon-reload || { echo "Failed to reload systemd"; exit 1; }
            sudo systemctl restart ollama.service || { echo "Failed to restart ollama"; exit 1; }

            echo "Waiting 10 seconds for Ollama to restart"
            sleep 10
        else
            echo "Environment variables already exist"
        fi
    else
        echo "Ollama service file not found"
    fi
}

echo "Upgrade the packages"
sudo dnf upgrade -y || { echo "Package upgrade failed"; exit 1; }

echo "Updating all system packages"
sudo dnf update -y || { echo "Package update failed"; exit 1; }

# Get latest version from GitHub API
latest_version=$(curl -fsSL https://api.github.com/repos/ollama/ollama/releases/latest | grep -Po '"tag_name": "\K[^"]*') || { echo "Failed to get latest version"; exit 1; }

echo "Latest version from GitHub: $latest_version"

# Get current local version
if command -v ollama &> /dev/null; then
    current_version=$(ollama --version 2>&1 | grep -Po 'ollama version is \K.*') || { echo "Failed to get current version"; exit 1; }
    echo "Current version: $current_version"
else
    echo "Ollama not found, setting to empty"
    current_version=""
fi

# Remove 'v' prefix from latest version for comparison
clean_latest=$(echo "$latest_version" | sed 's/^v//')

echo "Clean latest version: $clean_latest"

# Compare versions
if [ "$clean_latest" = "$current_version" ]; then
    echo "Versions match: $current_version"
    echo "Skipping Ollama Update"
else
    echo "Versions don't match - GitHub: $latest_version, Local: $current_version"
    echo "Starting the Ollama Update script"

    curl -fsSL https://ollama.com/install.sh | sh || { echo "Ollama installation failed"; exit 1; }

    echo "Waiting 3 seconds for Ollama to start"
    sleep 3

    updated_version=$(ollama --version 2>&1 | grep -Po 'ollama version is \K.*') || { echo "Failed to get updated version"; exit 1; }

    if [ "$clean_latest" = "$updated_version" ]; then
        # Add Environment variable to ollama service
        add_ollama_env_vars
    else
        echo "Something went wrong during the update process of ollama"
        #exit 1
    fi
fi

# After updating check for Ollama Environment Variable and restart
echo "Post-update environment variable check..."
add_ollama_env_vars

# Update Ollama models if needed
echo "Updating Ollama models where possible"
# First check if there are any models to update
model_count=$(ollama ls | grep -v "NAME" | wc -l)
if [ "$model_count" -gt 0 ]; then
    for i in $(ollama ls | awk '{ print $1}' | grep -v NAME); do
        if [[ "$i" == my* ]]; then
            echo "Skipping model: $i"
            continue
        fi
        echo "Updating model: $i"
        ollama pull "$i"
    done
else
    echo "No models found or failed to list models"
fi