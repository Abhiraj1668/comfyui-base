#!/bin/bash

# ==========================================
# ComfyUI Auto-Setup & Downloader Script
# ==========================================

# Define directories
COMFY_DIR="/workspace/runpod-slim/ComfyUI"
CUSTOM_NODES_DIR="$COMFY_DIR/custom_nodes"
MODELS_DIR="$COMFY_DIR/models"
CHECKPOINTS_DIR="$MODELS_DIR/checkpoints"
LORAS_DIR="$MODELS_DIR/loras"
# Add more model types as needed (e.g., embeddings, hypernetworks)

# Define config files
API_KEY_FILE="civitai_key.txt"
NODES_LIST="links_nodes.txt"
CHECKPOINTS_LIST="links_checkpoints.txt"
LORAS_LIST="links_loras.txt"

# 1. Load API Key
if [ -f "$API_KEY_FILE" ]; then
    # Read the first line of the key file and remove any Windows carriage returns
    CIVITAI_KEY=$(head -n 1 "$API_KEY_FILE" | tr -d '\r')
    echo "? Loaded CivitAI API Key."
else
    echo "??  Warning: '$API_KEY_FILE' not found. Downloads requiring authentication will fail."
    CIVITAI_KEY=""
fi

# Function to read a file line by line, ignoring comments and empty lines
read_links() {
    local file="$1"
    if [ -f "$file" ]; then
        # Remove carriage returns, filter out empty lines, and filter out lines starting with #
        cat "$file" | tr -d '\r' | grep -v '^\s*$' | grep -v '^\s*#'
    fi
}

# 2. Install Custom Nodes
echo "----------------------------------------"
echo "?? Installing Custom Nodes..."
echo "----------------------------------------"
if [ -f "$NODES_LIST" ]; then
    mkdir -p "$CUSTOM_NODES_DIR"
    cd "$CUSTOM_NODES_DIR" || exit
    
    for url in $(read_links "../$NODES_LIST"); do
        # Extract folder name from git URL (e.g., https://.../ComfyUI-Manager.git -> ComfyUI-Manager)
        repo_name=$(basename "$url" .git)
        
        if [ -d "$repo_name" ]; then
            echo "??  Skipping $repo_name (Already exists)"
        else
            echo "??  Cloning $repo_name..."
            git clone "$url"
        fi
    done
    cd ..
else
    echo "No '$NODES_LIST' file found. Skipping."
fi

# 3. Download Function for Models (Handles CivitAI Auth and Filenames)
download_model() {
    local list_file="$1"
    local dest_dir="$2"
    local model_type="$3"

    echo "----------------------------------------"
    echo "?? Downloading $model_type..."
    echo "----------------------------------------"

    if [ -f "$list_file" ]; then
        mkdir -p "$dest_dir"
        
        for url in $(read_links "$list_file"); do
            echo "??  Downloading: $url"
            
            # Use wget with --content-disposition to get the real filename from CivitAI headers.
            # We pass the token via the Authorization header to avoid messing up URL query parameters.
            if [ -n "$CIVITAI_KEY" ]; then
                wget --content-disposition --header="Authorization: Bearer $CIVITAI_KEY" -P "$dest_dir" "$url"
            else
                wget --content-disposition -P "$dest_dir" "$url"
            fi
        done
    else
        echo "No '$list_file' file found. Skipping."
    fi
}

# Execute Model Downloads
download_model "$CHECKPOINTS_LIST" "$CHECKPOINTS_DIR" "Checkpoints"
download_model "$LORAS_LIST" "$LORAS_DIR" "LoRAs"

echo "----------------------------------------"
echo "?? Setup Complete!"
echo "----------------------------------------"