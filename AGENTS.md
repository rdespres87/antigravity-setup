# AGENTS.md — Antigravity Setup Workspace & Domain Guide

Welcome to the **antigravity-setup** workspace.

> **Global Engineering Standards Apply Automatically**:  
> All engineering methodology (strict TDD, 5-phase continuous execution tracking, zero-panic/unwrap prohibition, mandatory merciless local audit via LM Studio, Headroom context compression, and atomic Git commit gates) are **enforced globally** by Antigravity rules (`idiomatic-craft`, `tiered-router`, `efficiency-router`).

---

## 1. Domain & Workspace Architecture

Before working on the codebase, review the domain-specific documentation:
1. [`docs/agent/SESSION_STATE.md`](file:///Users/rdespres/Projets/antigravity-setup/docs/agent/SESSION_STATE.md) — Current verified state of the workspace and toolchain status.
2. [`docs/agent/HANDOFF.md`](file:///Users/rdespres/Projets/antigravity-setup/docs/agent/HANDOFF.md) — Next tasks and context left by previous sessions.
3. [`docs/agent/TASKS.md`](file:///Users/rdespres/Projets/antigravity-setup/docs/agent/TASKS.md) — Milestone roadmap and backlog.

---

## 2. Project-Specific Constraints (antigravity-setup Only)

- **Language Mandate**: 100% English repository (scripts, comments, commit messages, and documentation).
- **Core Purpose**: Meta-repository orchestrating the turnkey installation, update, healthcheck, and synchronization of the Antigravity agentic environment (submodules, configuration symlinks, MCP fusion).
- **Idempotency & Non-Destructive Invariant**: All installation and update scripts (`install.sh`, `update.sh`, `healthcheck.sh`) MUST be strictly idempotent, non-destructive, and resilient against broken symlinks or existing configurations.
