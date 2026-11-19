# Tasks & Milestone Roadmap — antigravity-setup

## Phase 1: Foundational Setup & Architecture (In Progress)
- [x] Establish persistent agent tracking files (`AGENTS.md`, `SESSION_STATE.md`, `TASKS.md`, `HANDOFF.md`, `.gitignore`)
- [ ] Configure Git submodules for core Antigravity repositories
- [ ] Implement idempotent `install.sh` for turnkey bootstrapping
- [ ] Implement `update.sh` for submodule recursion and symlink refresh
- [ ] Implement `healthcheck.sh` for environment diagnostics (LM Studio, Headroom, MCPs)
- [ ] Author comprehensive `README.md` with 1-command bootstrap instructions

## Phase 2: Testing & Automated Validation
- [ ] Test `healthcheck.sh` locally against live services
- [ ] Validate non-destructive dry-run / rerun of `install.sh`
- [ ] Run merciless local audit on all scripts

## Phase 3: Release & Remote Sync
- [ ] Confirm local commit via Gate A
- [ ] Confirm remote push via Gate B
