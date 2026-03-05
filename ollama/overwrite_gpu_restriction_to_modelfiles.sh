#!/bin/bash

# Configuration
model_dir="models"
prefix="my"  # Prefix for new model names
create_new_models=true  # Set to false to only create modelfiles
dry_run=false # Initialize dry_run

# Parse command line arguments
for arg in "$@"; do
  case $arg in
    --dry-run)
      dry_run=true
      echo "Running in DRY-RUN mode."
      create_new_models=false # Dry run should not create models
      ;;
    *)
      # Unknown option, ignore for now or add error handling if desired
      ;;
  esac
done

# Create the model directory if it doesn't exist (only if not dry run)
if [[ "$dry_run" == false && ! -d "$model_dir" ]]; then
  mkdir -p "$model_dir"
fi

# Check for jq, essential for parsing Ollama API responses
if ! command -v jq &> /dev/null
then
    echo "jq could not be found. Please install it to parse JSON output (e.g., sudo apt-get install jq or brew install jq)."
    exit 1
fi

# Get the output of "ollama list" and process each model
ollama list | tail -n +2 | while read -r line; do
  # Extract the model name (first column)
  model_name=$(echo "$line" | awk '{print $1}')
  mymodel_name="${prefix}${model_name}"

  # Sanitize the model name for filesystem compatibility
  # Replace slashes and colons with underscores for file system compatibility
  # This variable will be used for the *actual file path* of the modelfile
  sanitized_model_filename=$(echo "${mymodel_name}" | sed 's/[\/:]/_/g')
  modelfile_path="${model_dir}/${sanitized_model_filename}.modelfile"

  # Skip if model already has our prefix (applies to dry-run too, per request to exclude "my" models from dry-run output)
  if [[ "$model_name" == "$prefix"* ]]; then
    if [[ "$dry_run" == true ]]; then
      echo "DRY-RUN: Skipping $model_name (already has prefix, not a base model to process)"
    else
      echo "Skipping $model_name (already has prefix)"
    fi
    continue
  fi

  # Check if our version of the model already exists (skipped in dry-run mode)
  if [[ "$dry_run" == false ]]; then
    if ollama list | grep -q "$mymodel_name"; then
      echo "Skipping $model_name (custom version already exists)"
      continue
    fi
  fi

  # The previous "Skip Hugging Face models" block has been removed,
  # allowing hf.co models to be processed.

  echo "Processing $model_name"

  # In dry-run mode, we do not create modelfiles
  if [[ "$dry_run" == false ]]; then
    echo "Creating modelfile: $modelfile_path"
    if ! ollama show "$model_name" --modelfile > "$modelfile_path"; then
      echo "Error creating modelfile for $model_name"
      continue
    fi
  fi

  # --- Logic to get block_count from Ollama API ---
  echo "Getting block count from Ollama API for $model_name"
  api_response=$(curl -s http://localhost:11434/api/show -d "{\"model\": \"$model_name\"}")

  if [[ $? -ne 0 ]]; then
    echo "Error calling Ollama API for $model_name. Is Ollama server running on port 11434?"
    if [[ "$dry_run" == true ]]; then
        echo "DRY-RUN: Model: $model_name, Layer count could not be retrieved due to API error."
    fi
    continue
  fi

  # Extract the block_count using jq from 'model_info'
  # This looks for any key containing "block_count" within the 'model_info' object.
  block_count=$(echo "$api_response" | jq -r '."model_info" | to_entries[] | select(.key | contains("block_count")) | .value' 2>/dev/null)

  # Clean up block_count to make sure it's all digits
  block_count=$(echo "$block_count" | tr -cd '[:digit:]')

  # Validate block_count and provide fallback to 'num_layers'
  if [[ -z "$block_count" || "$block_count" -eq 0 ]]; then
    echo "Could not find a valid 'block_count' from Ollama API 'model_info' for $model_name. Attempting 'num_layers' as fallback."
    block_count=$(echo "$api_response" | jq -r '."details"."num_layers"' 2>/dev/null)
    block_count=$(echo "$block_count" | tr -cd '[:digit:]') # Sanitize again

    if [[ -z "$block_count" || "$block_count" -eq 0 ]]; then
        echo "Could not find a valid layer count ('block_count' or 'num_layers'). Skipping $model_name."
        continue
    else
        echo "Using 'num_layers' as fallback for layer count: $block_count"
    fi
  fi
  # --- End of block_count determination logic ---

  # Re-add the +1 adjustment to block_count as requested
  block_count=$((block_count + 1))
  echo "Adjusted Layer count (block_count + 1) for $model_name: $block_count"

  # If in dry-run mode, just print the info and move to the next model
  if [[ "$dry_run" == true ]]; then
    echo "DRY-RUN: Model: $model_name, Estimated num_gpu: $block_count (This model would be processed)"
    echo "----------------------------------------"
    continue # Skip further processing in dry-run
  fi

  # Edit modelfile (only if not dry run)
  echo "Editing modelfile: $modelfile_path"
  # Remove existing FROM statement
  sed -i '/^FROM [^a-zA-Z0-9]/d' "$modelfile_path"
  # Uncomment the FROM statement
  sed -i 's/^# FROM/FROM/' "$modelfile_path"
  # Remove any existing PARAMETER num_gpu line to avoid duplicates
  sed -i '/^PARAMETER num_gpu/d' "$modelfile_path"
  # Add the num_gpu parameter with the adjusted block count
  echo "PARAMETER num_gpu $block_count" >> "$modelfile_path"

  if [[ "$create_new_models" == true ]]; then
    echo "Creating new model '$mymodel_name' from modelfile '$modelfile_path' with custom num_gpu parameter"
    # Create new model with modelfile
    if ! ollama create "$mymodel_name" --file "$modelfile_path"; then
      echo "Error creating model $mymodel_name"
    fi
  else
    echo "Skipping model creation (create_new_models=false)"
  fi

  echo "----------------------------------------"
done