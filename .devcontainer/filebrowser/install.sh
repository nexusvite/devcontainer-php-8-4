#!/usr/bin/env bash

set -euo pipefail

BOLD='\033[0;1m'

printf "%sInstalling filebrowser\n\n" "${BOLD}"

# Check if filebrowser is installed.
if ! command -v filebrowser &>/dev/null; then
	VERSION="v2.42.1"
	EXPECTED_HASH="7d83c0f077df10a8ec9bfd9bf6e745da5d172c3c768a322b0e50583a6bc1d3cc"

	curl -fsSL "https://github.com/filebrowser/filebrowser/releases/download/${VERSION}/linux-amd64-filebrowser.tar.gz" -o /tmp/filebrowser.tar.gz
	echo "${EXPECTED_HASH} /tmp/filebrowser.tar.gz" | sha256sum -c
	tar -xzf /tmp/filebrowser.tar.gz -C /tmp
	sudo mv /tmp/filebrowser /usr/local/bin/
	sudo chmod +x /usr/local/bin/filebrowser
	rm /tmp/filebrowser.tar.gz
fi

# Create entrypoint - Using noauth with explicit database
cat >/usr/local/bin/filebrowser-entrypoint <<EOF
#!/usr/bin/env bash

PORT="${PORT}"
FOLDER="${FOLDER:-}"
FOLDER="\${FOLDER:-\$(pwd)}"
LOG_PATH=/tmp/filebrowser.log
DB_PATH="/tmp/filebrowser.db"

echo "=== Filebrowser Entrypoint ===" > \${LOG_PATH}
echo "PORT: \${PORT}" >> \${LOG_PATH}
echo "FOLDER: \${FOLDER}" >> \${LOG_PATH}
echo "DB_PATH: \${DB_PATH}" >> \${LOG_PATH}

printf "Configuring filebrowser\n"
printf "Database: \${DB_PATH}\n"
printf "Port: \${PORT}\n"
printf "Folder: \${FOLDER}\n"

# Kill any existing filebrowser process
pkill -f filebrowser 2>/dev/null || true
sleep 1

# Remove existing database for clean start
rm -f "\${DB_PATH}"

# Initialize database
echo "Initializing database..." >> \${LOG_PATH}
filebrowser config init --database="\${DB_PATH}" 2>>\${LOG_PATH}

# Add user with ID 1
echo "Adding admin user..." >> \${LOG_PATH}
filebrowser --database="\${DB_PATH}" users add admin "" --perm.admin=true 2>>\${LOG_PATH}

# Set noauth
echo "Setting noauth..." >> \${LOG_PATH}
filebrowser --database="\${DB_PATH}" config set --auth.method=noauth 2>>\${LOG_PATH}

# Set other config
echo "Setting port and root..." >> \${LOG_PATH}
filebrowser --database="\${DB_PATH}" config set --port=\${PORT} --root="\${FOLDER}" --address=0.0.0.0 2>>\${LOG_PATH}

# Verify config
echo "Current config:" >> \${LOG_PATH}
filebrowser --database="\${DB_PATH}" config cat 2>>\${LOG_PATH}

printf "Starting filebrowser...\n"
printf "Serving \${FOLDER} at http://localhost:\${PORT}\n"

# Start filebrowser
echo "Starting filebrowser..." >> \${LOG_PATH}
filebrowser --database="\${DB_PATH}" 2>>\${LOG_PATH} &

echo "Filebrowser PID: \$!" >> \${LOG_PATH}
printf "Logs at \${LOG_PATH}\n"
EOF

chmod +x /usr/local/bin/filebrowser-entrypoint

printf "Installation complete!\n\n"
