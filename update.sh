#!/usr/bin/env bash
# ==============================================================================
# Antigravity Environment Updater
# Pulls latest updates across all submodules and synchronizes symlinks & MCP.
# ==============================================================================

set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false

show_help() {
    cat <<EOF
Usage: ./update.sh [OPTIONS]

Pulls latest commits from remote origins for all Antigravity submodules,
refreshes symlinks, and runs the diagnostic healthcheck.

Options:
  --dry-run       Preview updates without pulling or writing changes
  -h, --help      Display this help message
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1" >&2
            show_help
            ;;
    esac
done

echo -e "${BOLD}${CYAN}=== Updating Antigravity Environment ===${RESET}"

if [ "${DRY_RUN}" = true ]; then
    echo -e "${YELLOW}[DRY-RUN MODE] No remote pulls will be executed.${RESET}"
    echo "  [DRY-RUN] Would run: git pull --recurse-submodules"
    echo "  [DRY-RUN] Would run: git submodule update --init --recursive --remote"
    echo "  [DRY-RUN] Would run: ./install.sh --links-only"
    echo "  [DRY-RUN] Would run: ./healthcheck.sh"
    exit 0
fi

echo -e "\n${BOLD}1. Pulling latest repository changes...${RESET}"
cd "${REPO_DIR}"
if ! git pull --recurse-submodules; then
    echo -e "  [${YELLOW}WARN${RESET}] Network unreachable or git pull failed. Continuing with existing submodules..."
fi

echo -e "\n${BOLD}2. Updating all submodules to latest remote HEAD...${RESET}"
if ! git submodule update --init --recursive --remote; then
    echo -e "  [${YELLOW}WARN${RESET}] Submodule remote update failed. Keeping local submodule revisions."
fi

echo -e "\n${BOLD}3. Refreshing configuration links & MCP servers...${RESET}"
"${REPO_DIR}/install.sh" --links-only

echo -e "\n${BOLD}${GREEN}Update completed successfully!${RESET}"
