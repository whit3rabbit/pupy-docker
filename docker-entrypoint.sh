#!/bin/bash
set -e

# Configuration paths
CONFIG_SOURCE="/opt/pupy/config/pupy.conf"
CONFIG_DEST="/home/pupy/.config/pupy/pupy.conf"
CONFIG_DEFAULT="/opt/pupy/pupy/conf/pupy.conf.default"

# Function to copy default config if custom one doesn't exist
setup_config() {
    echo "=== Configuration Setup ==="
    
    # Ensure destination directory exists
    mkdir -p $(dirname "$CONFIG_DEST")
    
    if [ -f "$CONFIG_SOURCE" ]; then
        echo "✓ Using custom configuration from $CONFIG_SOURCE"
        cp "$CONFIG_SOURCE" "$CONFIG_DEST"
        echo "  Copied to $CONFIG_DEST"
    else
        echo "! No custom configuration found at $CONFIG_SOURCE"
        echo "  Using default configuration from $CONFIG_DEFAULT"
        
        # Copy default config to both locations
        cp "$CONFIG_DEFAULT" "$CONFIG_DEST"
        
        # Also copy to mounted volume for user to modify
        if [ -w "$(dirname "$CONFIG_SOURCE")" ]; then
            cp "$CONFIG_DEFAULT" "$CONFIG_SOURCE"
            echo "  Default configuration copied to $CONFIG_SOURCE"
            echo "  You can modify this file and restart the container to apply changes"
        fi
    fi
    
    # Verify config is in place
    if [ -f "$CONFIG_DEST" ]; then
        echo "✓ Configuration ready at $CONFIG_DEST"
    else
        echo "✗ ERROR: Failed to setup configuration!"
        exit 1
    fi
    echo "==========================="
}

# Setup configuration
setup_config

# Handle different commands
case "$1" in
    "pupysh")
        echo "Starting Pupy Server (pupysh)..."
        shift
        exec python -m pupy.cli "$@"
        ;;
    "pupygen")
        echo "Starting Pupy Payload Generator (pupygen)..."
        shift
        # Change to output directory for payload generation
        cd /opt/pupy/output
        # Ensure the subdirectory specified in common pupygen commands (e.g., -o ./output/file) exists
        mkdir -p ./output
        # Use the proper module path for pupygen
        exec python -m pupy.cli.pupygen "$@"
        ;;
    "bash"|"sh")
        echo "Starting shell..."
        exec "$@"
        ;;
    *)
        # If no recognized command, assume it's pupysh with arguments
        echo "Starting Pupy Server with custom arguments..."
        exec python -m pupy.cli "$@"
        ;;
esac