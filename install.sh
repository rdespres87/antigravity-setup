#!/usr/bin/env bash
# ==============================================================================
# Antigravity Turnkey Environment Installer
# Idempotently bootstraps submodules, symlinks, MCP configurations, and checks health.
# ==============================================================================

set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.gemini/config"
PLUGINS_DIR="${CONFIG_DIR}/plugins"
SKILLS_DIR="${CONFIG_DIR}/skills"
MCP_CONFIG="${CONFIG_DIR}/mcp_config.json"
BACKUP_DIR="${CONFIG_DIR}/backups/$(date +%Y%m%d_%H%M%S)"

DRY_RUN=false
LINKS_ONLY=false

show_help() {
    cat <<EOF
Usage: ./install.sh [OPTIONS]

Turnkey installer for the Antigravity agentic environment.

Options:
  --dry-run       Preview actions without modifying any file or link
  --links-only    Skip git submodule operations and only update symlinks/MCP
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
        --links-only)
            LINKS_ONLY=true
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

echo -e "${BOLD}${CYAN}=== Bootstrapping Antigravity Environment ===${RESET}"
echo "Source: ${REPO_DIR}"
echo "Target: ${CONFIG_DIR}"
if [ "${DRY_RUN}" = true ]; then
    echo -e "${YELLOW}[DRY-RUN MODE] No changes will be applied.${RESET}"
fi

# 1. Verify Prerequisites
echo -e "\n${BOLD}1. Checking prerequisites...${RESET}"
for cmd in git python3 curl; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        echo -e "${YELLOW}Error: Required command '${cmd}' is not installed.${RESET}" >&2
        exit 1
    fi
done
echo -e "  [${GREEN}OK${RESET}] git, python3, and curl found."

# 2. Submodule Initialization
if [ "${LINKS_ONLY}" = false ]; then
    echo -e "\n${BOLD}2. Initializing & updating Git submodules...${RESET}"
    if [ "${DRY_RUN}" = false ]; then
        cd "${REPO_DIR}"
        git submodule update --init --recursive
    else
        echo "  [DRY-RUN] Would run: git submodule update --init --recursive"
    fi
fi

# 3. Create Target Config Directories
echo -e "\n${BOLD}3. Setting up directory structures...${RESET}"
if [ "${DRY_RUN}" = false ]; then
    mkdir -p "${PLUGINS_DIR}" "${SKILLS_DIR}" "${CONFIG_DIR}"
fi
echo -e "  [${GREEN}OK${RESET}] Directories ready."

# 4. Safe Symlink Deployment
echo -e "\n${BOLD}4. Deploying Antigravity symlinks...${RESET}"

create_symlink() {
    local target_source="$1"
    local symlink_path="$2"
    local name
    name="$(basename "$(dirname "${symlink_path}")")/$(basename "${symlink_path}")"

    if [ ! -e "${target_source}" ]; then
        echo -e "  [${YELLOW}WARN${RESET}] Target source does not exist: ${target_source}"
        return
    fi

    if [ -L "${symlink_path}" ]; then
        current_target="$(readlink "${symlink_path}")"
        if [ "${current_target}" = "${target_source}" ]; then
            echo -e "  [${GREEN}OK${RESET}] ${name} already points to target."
            return
        fi
    elif [ -d "${symlink_path}" ]; then
        echo -e "  [${YELLOW}NOTICE${RESET}] ${name} is a physical directory. Backing up to ${BACKUP_DIR}..."
        if [ "${DRY_RUN}" = false ]; then
            mkdir -p "${BACKUP_DIR}"
            mv "${symlink_path}" "${BACKUP_DIR}/"
        fi
    fi

    if [ "${DRY_RUN}" = false ]; then
        ln -sfn "${target_source}" "${symlink_path}"
        echo -e "  [${GREEN}LINKED${RESET}] ${name} -> ${target_source}"
    else
        echo "  [DRY-RUN] Would link ${symlink_path} -> ${target_source}"
    fi
}

# Plugins
create_symlink "${REPO_DIR}/submodules/antigravity-plugins/plugins/idiomatic-craft" "${PLUGINS_DIR}/idiomatic-craft"
create_symlink "${REPO_DIR}/submodules/antigravity-tiered-router" "${PLUGINS_DIR}/tiered-router"
create_symlink "${REPO_DIR}/submodules/antigravity-efficiency-router" "${PLUGINS_DIR}/efficiency-router"

# Skills
create_symlink "${REPO_DIR}/submodules/antigravity-skills/skills/grill-orchestrator" "${SKILLS_DIR}/grill-orchestrator"
create_symlink "${REPO_DIR}/submodules/antigravity-skills/skills/merciless-local-audit" "${SKILLS_DIR}/merciless-local-audit"
create_symlink "${REPO_DIR}/submodules/antigravity-skills/skills/project-scaffold" "${SKILLS_DIR}/project-scaffold"

# 5. MCP Configuration Merge
echo -e "\n${BOLD}5. Configuring MCP Servers in ${MCP_CONFIG}...${RESET}"

HEADROOM_BIN="$(command -v headroom || echo "${HOME}/.local/bin/headroom")"
TIERED_ROUTER_SCRIPT="${REPO_DIR}/submodules/antigravity-tiered-router/server/tiered_router_mcp.py"

if [ "${DRY_RUN}" = false ]; then
    python3 - <<EOF
import json
import os

mcp_path = "${MCP_CONFIG}"
tiered_script = "${TIERED_ROUTER_SCRIPT}"
headroom_bin = "${HEADROOM_BIN}"

data = {"mcpServers": {}}
if os.path.exists(mcp_path):
    try:
        with open(mcp_path, "r", encoding="utf-8") as f:
            data = json.load(f)
            if "mcpServers" not in data:
                data["mcpServers"] = {}
    except Exception as e:
        print(f"Warning: Could not parse existing {mcp_path}: {e}. Creating new configuration.")

# Configure tiered-router (always point to active setup submodule)
data["mcpServers"]["tiered-router"] = {
    "command": "python3",
    "args": [tiered_script],
    "env": {
        "LMSTUDIO_HOST": "http://127.0.0.1:1234",
        "LMSTUDIO_DECISION_MODEL": "qwen/qwen3.6-35b-a3b"
    }
}

# Configure headroom only if not already present or if pointing to missing binary
if "headroom" not in data["mcpServers"]:
    data["mcpServers"]["headroom"] = {
        "command": headroom_bin,
        "args": ["mcp", "serve"]
    }
else:
    # Ensure command points to a valid binary if current is empty or broken
    current_cmd = data["mcpServers"]["headroom"].get("command", "")
    if not current_cmd or not os.path.exists(current_cmd):
        data["mcpServers"]["headroom"]["command"] = headroom_bin

with open(mcp_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
print("  [OK] MCP configuration updated successfully.")
EOF
else
    echo "  [DRY-RUN] Would update ${MCP_CONFIG} with tiered-router and headroom entries."
fi

# 6. Post-Installation Diagnostic
echo -e "\n${BOLD}6. Running environment healthcheck...${RESET}"
if [ "${DRY_RUN}" = false ]; then
    "${REPO_DIR}/healthcheck.sh"
else
    echo "  [DRY-RUN] Would execute ${REPO_DIR}/healthcheck.sh"
fi

echo -e "\n${BOLD}${GREEN}Installation complete! Antigravity environment is ready.${RESET}"
