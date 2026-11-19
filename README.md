# Antigravity Setup — Turnkey Agentic Environment

Turnkey meta-repository to bootstrap, synchronize, and health-check the full **Google Antigravity** agentic development environment across any macOS / Linux workstation.

It orchestrates:
- **Tiered Model Routing**: 3-tier hierarchy offloading mechanical work to local offline models (LM Studio) at **0 cloud tokens**.
- **Efficiency & Token Hygiene**: Real-time quota tracking, telegraphic French protocol, and background token ledgers.
- **Persistent Context Compression**: Automated upstream compression via **Headroom** (>80 lines / >800 tokens).
- **Zero-Compromise Engineering Craft**: Strict TDD, non-optional 5-phase continuous execution, 8-axis merciless local audit (Qwen 35B), and atomic two-stage Git commit gates (`ask_question`).

---

## Architecture Overview

```
antigravity-setup/
├── install.sh                  # Idempotent 1-command installer & symlink manager
├── update.sh                   # Recursive submodule updater & sync runner
├── healthcheck.sh              # Live environment diagnostic (LM Studio, Headroom, MCPs)
├── config/
│   └── mcp_template.json       # MCP configuration reference
├── submodules/
│   ├── antigravity-plugins/    # Plugins (idiomatic-craft, etc.)
│   ├── antigravity-skills/     # Skills (grill-orchestrator, merciless-local-audit, project-scaffold)
│   ├── antigravity-tiered-router/      # Tiered router plugin & MCP server
│   └── antigravity-efficiency-router/  # Token efficiency router & PreInvocation hooks
├── AGENTS.md                   # Workspace agent guide & invariants
└── docs/agent/                 # Persistent state (SESSION_STATE, TASKS, HANDOFF)
```

---

## 1-Command Bootstrap (Fresh Machine)

To clone and install the complete environment on a new machine:

```bash
git clone --recurse-submodules git@github.com:rdespres87/antigravity-setup.git ~/Projets/antigravity-setup
cd ~/Projets/antigravity-setup
./install.sh
```

### What `install.sh` Does:
1. **Verifies Prerequisites**: Validates `git`, `python3`, and `curl`.
2. **Initializes Submodules**: Fetches and locks all 4 core submodules.
3. **Deploys Idempotent Symlinks**:
   - `~/.gemini/config/plugins/idiomatic-craft`
   - `~/.gemini/config/plugins/tiered-router`
   - `~/.gemini/config/plugins/efficiency-router`
   - `~/.gemini/config/skills/grill-orchestrator`
   - `~/.gemini/config/skills/merciless-local-audit`
   - `~/.gemini/config/skills/project-scaffold`
   *(Existing physical folders are automatically backed up to `~/.gemini/config/backups/`).*
4. **Configures MCP Servers**: Safely merges `tiered-router` and `headroom` into `~/.gemini/config/mcp_config.json`.
5. **Runs Healthcheck**: Validates live socket connectivity, loaded models, and file paths.

---

## Updating the Environment

To pull the latest changes across all submodules and refresh configuration:

```bash
./update.sh
```

Preview changes without pulling:
```bash
./update.sh --dry-run
```

---

## Diagnostic & Healthcheck

Run the diagnostic at any time to verify your agentic stack:

```bash
./healthcheck.sh
```

Checks performed:
- [x] Submodule tree integrity and commit revisions
- [x] Antigravity plugin and skill symlinks validity
- [x] `~/.gemini/config/mcp_config.json` JSON schema and server registrations
- [x] LM Studio connectivity (`http://127.0.0.1:1234`) and active model detection
- [x] Headroom upstream proxy (`http://127.0.0.1:8787`) and CLI binary in `PATH`

---

## Prerequisites

| Component | Required For | Recommended Setup |
| :--- | :--- | :--- |
| **Git & Python 3.10+** | Base orchestration | Standard system packages |
| **LM Studio** | Tier 1 local offloading (0 cloud tokens) | Listening on port `1234`, model: `qwen/qwen3.6-35b-a3b` |
| **Headroom** | Upstream context compression | Listening on port `8787`, CLI in `PATH` or `~/.local/bin/headroom` |
| **Google Antigravity** | Agentic IDE & execution harness | Configuration directory at `~/.gemini/` |

---

## License & Credits

Maintained by **rdespres87**. Distributed under the MIT License.
EOF
