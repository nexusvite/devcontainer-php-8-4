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

# Create entrypoint.
cat >/usr/local/bin/filebrowser-entrypoint <<EOF
#!/usr/bin/env bash

PORT="${PORT:-13339}"
FOLDER="${FOLDER:-}"
FOLDER="\${FOLDER:-\$(pwd)}"
BASEURL="${BASEURL:-}"
LOG_PATH=/tmp/filebrowser.log
export FB_DATABASE="\${HOME}/.filebrowser.db"

# Ensure log file is writable
touch "\${LOG_PATH}" 2>/dev/null || sudo touch "\${LOG_PATH}"
chmod 666 "\${LOG_PATH}" 2>/dev/null || sudo chmod 666 "\${LOG_PATH}"

printf "Configuring filebrowser\n\n"

# Remove old database to ensure clean config
rm -f "\${FB_DATABASE}" 2>/dev/null || true

# Initialize fresh database
filebrowser config init >>\${LOG_PATH} 2>&1
filebrowser users add admin "" --perm.admin=true --viewMode=mosaic >>\${LOG_PATH} 2>&1

# Configure filebrowser - bind to all interfaces
filebrowser config set --address=0.0.0.0 --port=\${PORT} --baseurl="\${BASEURL}" --auth.method=noauth --root=\${FOLDER} >>\${LOG_PATH} 2>&1

printf "Starting filebrowser...\n\n"
printf "Serving \${FOLDER} at http://0.0.0.0:\${PORT}\n\n"

# Start filebrowser
filebrowser >>\${LOG_PATH} 2>&1 &

printf "Logs at \${LOG_PATH}\n\n"
EOF

chmod +x /usr/local/bin/filebrowser-entrypoint

printf "Installation complete!\n\n"
