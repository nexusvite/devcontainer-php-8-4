#!/bin/bash

set -e

echo "Running post-create setup..."

# Ensure filebrowser entrypoint is executable
if [ -f /usr/local/bin/filebrowser-entrypoint ]; then
    chmod +x /usr/local/bin/filebrowser-entrypoint
fi

# Copy SSH keys from host if available
if [ -d "/mnt/home/${USER}/.ssh" ]; then
    echo "Copying SSH keys..."
    cp -r /mnt/home/${USER}/.ssh ~/. 2>/dev/null || true
    chmod 700 ~/.ssh 2>/dev/null || true
    chmod 600 ~/.ssh/* 2>/dev/null || true
fi

# Copy git config if available
if [ -f "/mnt/home/${USER}/.gitconfig" ]; then
    echo "Copying git config..."
    cp /mnt/home/${USER}/.gitconfig ~/. 2>/dev/null || true
fi

echo "Post-create setup complete!"
