#!/bin/bash
set -e

# Base directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

setup_venv() {
    local dir=$1
    echo "--- Setting up venv in $dir ---"
    cd "$dir"
    
    if [ ! -d ".venv" ]; then
        python3 -m venv .venv
        echo "Created .venv"
    else
        echo ".venv already exists"
    fi
    
    source .venv/bin/activate
    pip install --upgrade pip -q
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt -q
        echo "Installed dependencies from requirements.txt"
    else
        echo "No requirements.txt found"
    fi
    deactivate
    echo "Done."
    echo
}

setup_venv "$BASE_DIR/servers/socket"
setup_venv "$BASE_DIR/servers/http"

echo "All environments set up successfully!"
