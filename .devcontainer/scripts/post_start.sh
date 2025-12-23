#!/bin/sh

echo "Running post-start setup..."

# Start filebrowser if not already running
if ! pgrep -f "filebrowser" > /dev/null; then
    echo "Starting filebrowser..."
    if [ -f /usr/local/bin/filebrowser-entrypoint ]; then
        /usr/local/bin/filebrowser-entrypoint || true
    fi
fi

# Start phpMyAdmin if not already running
if ! pgrep -f "php.*phpmyadmin" > /dev/null; then
    echo "Starting phpMyAdmin..."
    if [ -f /usr/local/bin/phpmyadmin-entrypoint ]; then
        /usr/local/bin/phpmyadmin-entrypoint || true
    fi
fi

echo "Post-start setup complete!"
