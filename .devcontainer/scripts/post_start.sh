#!/bin/bash

set -e

echo "Running post-start setup..."

# Start filebrowser if not already running
if ! pgrep -x "filebrowser" > /dev/null; then
    echo "Starting filebrowser..."
    if [ -f /usr/local/bin/filebrowser-entrypoint ]; then
        /usr/local/bin/filebrowser-entrypoint
    fi
fi

echo "Post-start setup complete!"
