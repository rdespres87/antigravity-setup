#!/usr/bin/env bash
# ==============================================================================
# Antigravity Environment Diagnostic & Healthcheck
# Verifies submodules, symlinks, MCP configurations, LM Studio, and Headroom.
# ==============================================================================

set -euo pipefail

# ANSI Color Codes
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.gemini/config"
MCP_CONFIG="${CONFIG_DIR}/mcp_config.json"

TOTAL_CHECKS=0
PASSED_CHECKS=0
WARNINGS=0
ERRORS=0

log_header() {
    echo -e "\n${BOLD}${CYAN}=== $1 ===${RESET}"
}

check_ok() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    echo -e "  [${GREEN}OK${RESET}] $1"
}

check_warn() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    WARNINGS=$((WARNINGS + 1))
    echo -e "  [${YELLOW}WARN${RESET}] $1"
}

check_fail() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    ERRORS=$((ERRORS + 1))
    echo -e "  [${RED}FAIL${RESET}] $1"
}

echo -e "${BOLD}Antigravity Environment Diagnostic & Healthcheck${RESET}"
echo "Repository: ${REPO_DIR}"
echo "Config Dir: ${CONFIG_DIR}"

# 1. Submodules Check
log_header "1. Git Submodules Integrity"
submodules=(
    "submodules/antigravity-plugins"
    "submodules/antigravity-skills"
    "submodules/antigravity-tiered-router"
    "submodules/antigravity-efficiency-router"
)

for sm in "${submodules[@]}"; do
    target="${REPO_DIR}/${sm}"
    if [ -d "${target}" ] && [ "$(ls -A "${target}")" ]; then
        rev=$(git -C "${target}" rev-parse --short HEAD 2>/dev/null || echo "unknown")
        check_ok "${sm} present (rev: ${rev})"
    else
        check_fail "${sm} is missing or empty (run: git submodule update --init --recursive)"
    fi
done

# 2. Symlinks Check
log_header "2. Antigravity Symlinks (~/.gemini/config)"
links=(
    "${CONFIG_DIR}/plugins/idiomatic-craft:${REPO_DIR}/submodules/antigravity-plugins/plugins/idiomatic-craft"
    "${CONFIG_DIR}/plugins/tiered-router:${REPO_DIR}/submodules/antigravity-tiered-router"
    "${CONFIG_DIR}/plugins/efficiency-router:${REPO_DIR}/submodules/antigravity-efficiency-router"
    "${CONFIG_DIR}/skills/grill-orchestrator:${REPO_DIR}/submodules/antigravity-skills/skills/grill-orchestrator"
    "${CONFIG_DIR}/skills/merciless-local-audit:${REPO_DIR}/submodules/antigravity-skills/skills/merciless-local-audit"
    "${CONFIG_DIR}/skills/project-scaffold:${REPO_DIR}/submodules/antigravity-skills/skills/project-scaffold"
)

for link_def in "${links[@]}"; do
    link_path="${link_def%%:*}"
    expected_target="${link_def##*:}"
    link_name="$(basename "$(dirname "${link_path}")")/$(basename "${link_path}")"

    if [ -L "${link_path}" ]; then
        actual_target="$(readlink "${link_path}")"
        # Resolve symlink to absolute path if relative
        if [[ "${actual_target}" != /* ]]; then
            actual_target="$(cd "$(dirname "${link_path}")" && cd "${actual_target}" && pwd)"
        fi
        if [ -e "${link_path}" ]; then
            check_ok "${link_name} -> ${actual_target}"
        else
            check_fail "${link_name} -> broken symlink pointing to ${actual_target}"
        fi
    elif [ -d "${link_path}" ]; then
        check_warn "${link_name} is a physical directory (not a symlink to setup repository)"
    else
        check_fail "${link_name} is missing (run ./install.sh)"
    fi
done

# 3. MCP Configuration Check
log_header "3. MCP Server Configuration"
if [ -f "${MCP_CONFIG}" ]; then
    if python3 -c "import json; json.load(open('${MCP_CONFIG}'))" 2>/dev/null; then
        has_tiered=$(python3 -c "import json; cfg=json.load(open('${MCP_CONFIG}')); print('tiered-router' in cfg.get('mcpServers', {}))" 2>/dev/null || echo "False")
        has_headroom=$(python3 -c "import json; cfg=json.load(open('${MCP_CONFIG}')); print('headroom' in cfg.get('mcpServers', {}))" 2>/dev/null || echo "False")

        if [ "${has_tiered}" = "True" ]; then
            check_ok "tiered-router MCP server registered in mcp_config.json"
        else
            check_warn "tiered-router MCP server missing from mcp_config.json"
        fi

        if [ "${has_headroom}" = "True" ]; then
            check_ok "headroom MCP server registered in mcp_config.json"
        else
            check_warn "headroom MCP server missing from mcp_config.json"
        fi
    else
        check_fail "mcp_config.json exists but is not valid JSON"
    fi
else
    check_warn "mcp_config.json not found at ${MCP_CONFIG}"
fi

# 4. LM Studio & Offline Model Connectivity
log_header "4. LM Studio & Offline Model Status (Tier 1 Local Router)"
LMSTUDIO_HOST="http://127.0.0.1:1234"
if curl -s -m 2 "${LMSTUDIO_HOST}/v1/models" >/dev/null 2>&1; then
    models=$(curl -s -m 2 "${LMSTUDIO_HOST}/v1/models" | python3 -c "import sys, json; data=json.load(sys.stdin); print(', '.join([m.get('id', '') for m in data.get('data', [])]))" 2>/dev/null || echo "running")
    check_ok "LM Studio active at ${LMSTUDIO_HOST} (Loaded: ${models})"
else
    check_warn "LM Studio offline or not listening on port 1234 (Local Tier 1 offline fallback inactive)"
fi

# 5. Headroom Daemon / Proxy Status
log_header "5. Headroom Compression Status"
HEADROOM_PROXY="http://127.0.0.1:8787"
if curl -s -m 2 "${HEADROOM_PROXY}" >/dev/null 2>&1 || curl -s -m 2 "${HEADROOM_PROXY}/health" >/dev/null 2>&1; then
    check_ok "Headroom upstream compression proxy running on port 8787"
else
    check_warn "Headroom proxy not responding on port 8787 (upstream compression daemon may need restart)"
fi

if command -v headroom >/dev/null 2>&1; then
    check_ok "headroom binary found in PATH ($(command -v headroom))"
elif [ -x "${HOME}/.local/bin/headroom" ]; then
    check_ok "headroom binary found at ${HOME}/.local/bin/headroom"
else
    check_warn "headroom CLI binary not found in standard PATH"
fi

# 6. Final Summary
log_header "Diagnostic Summary"
echo -e "Total checks : ${TOTAL_CHECKS}"
echo -e "Passed       : ${GREEN}${PASSED_CHECKS}${RESET}"
echo -e "Warnings     : ${YELLOW}${WARNINGS}${RESET}"
echo -e "Errors       : ${RED}${ERRORS}${RESET}"

if [ "${ERRORS}" -eq 0 ]; then
    if [ "${WARNINGS}" -eq 0 ]; then
        echo -e "\n${BOLD}${GREEN}==> STATUS: PERFECT HEALTH! All components, submodules, and daemons are fully operational.${RESET}\n"
    else
        echo -e "\n${BOLD}${YELLOW}==> STATUS: OPERATIONAL WITH NOTICES. Core Antigravity rules and plugins are active.${RESET}\n"
    fi
    exit 0
else
    echo -e "\n${BOLD}${RED}==> STATUS: ACTION REQUIRED. Resolve identified errors using ./install.sh.${RESET}\n"
    exit 1
fi
