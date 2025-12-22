#!/usr/bin/env bash

set -euo pipefail

BOLD='\033[0;1m'
RESET='\033[0m'

printf "%sInstalling filebrowser%s\n\n" "${BOLD}" "${RESET}"

# Check if filebrowser is installed.
if ! command -v filebrowser &>/dev/null; then
	VERSION="v2.31.2"

	# Detect architecture
	ARCH=$(uname -m)
	case "${ARCH}" in
		x86_64)
			ARCH_NAME="amd64"
			;;
		aarch64|arm64)
			ARCH_NAME="arm64"
			;;
		armv7l)
			ARCH_NAME="armv7"
			;;
		*)
			echo "Unsupported architecture: ${ARCH}"
			exit 1
			;;
	esac

	DOWNLOAD_URL="https://github.com/filebrowser/filebrowser/releases/download/${VERSION}/linux-${ARCH_NAME}-filebrowser.tar.gz"

	echo "Downloading filebrowser for ${ARCH_NAME}..."
	curl -fsSL "${DOWNLOAD_URL}" -o /tmp/filebrowser.tar.gz
	tar -xzf /tmp/filebrowser.tar.gz -C /tmp
	sudo mv /tmp/filebrowser /usr/local/bin/
	sudo chmod +x /usr/local/bin/filebrowser
	rm /tmp/filebrowser.tar.gz
	echo "filebrowser binary installed successfully"
fi

# Create entrypoint script
sudo tee /usr/local/bin/filebrowser-entrypoint > /dev/null <<'ENTRYPOINT'
#!/usr/bin/env bash

# Get port from environment or use default
FB_PORT="${PORT:-13339}"
FB_FOLDER="${FOLDER:-}"
FB_FOLDER="${FB_FOLDER:-$(pwd)}"
FB_BASEURL="${BASEURL:-}"
LOG_PATH="/tmp/filebrowser.log"
export FB_DATABASE="${HOME}/.filebrowser.db"

printf "Configuring filebrowser...\n"
printf "Port: %s\n" "${FB_PORT}"
printf "Folder: %s\n" "${FB_FOLDER}"

# Initialize database if it doesn't exist
if [[ ! -f "${FB_DATABASE}" ]]; then
	printf "Initializing filebrowser database...\n"
	filebrowser config init >> "${LOG_PATH}" 2>&1 || true
	filebrowser users add admin "" --perm.admin=true --viewMode=mosaic >> "${LOG_PATH}" 2>&1 || true
fi

# Configure filebrowser
filebrowser config set --baseurl="${FB_BASEURL}" --port="${FB_PORT}" --auth.method=noauth --root="${FB_FOLDER}" >> "${LOG_PATH}" 2>&1

printf "Starting filebrowser...\n"
printf "Serving %s at http://localhost:%s\n" "${FB_FOLDER}" "${FB_PORT}"

# Start filebrowser in foreground first to ensure it works, then background
nohup filebrowser >> "${LOG_PATH}" 2>&1 &

printf "Filebrowser started. Logs at %s\n\n" "${LOG_PATH}"
ENTRYPOINT

sudo chmod +x /usr/local/bin/filebrowser-entrypoint

printf "%sInstallation complete!%s\n\n" "${BOLD}" "${RESET}"
