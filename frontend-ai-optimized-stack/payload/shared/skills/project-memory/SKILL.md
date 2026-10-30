---
name: project-memory
description: Use TinyContext for small, durable, project-scoped memory available in Claude Code, Codex and OMP with Working/Private isolation without dumping full history into context.
---
# Project memory via TinyContext

TinyContext is the shared durable memory layer for this repository in Claude Code, Codex CLI and YOLO-Auto/OMP.

Use `recall_memories` when prior decisions, preferences, implementation constraints, or recent project work are materially relevant. Prefer a focused semantic query. Do not recall on every turn just because the tool exists.

Use recent recall (`query` omitted, normally `top_k=5`) only when chronological continuity matters.

Use `save_memories` for concise durable facts: architectural decisions, stable project constraints, important implementation outcomes, or user preferences that should survive switching agent CLIs. Do not store secrets, transient logs, full transcripts, generated code, or facts already obvious from the repository.

When correcting a stored fact, use `update_memory`; use `delete_memory` only when a memory should truly be removed. Use `list_memories`/`get_memory` for deterministic browsing instead of asking semantic recall to behave like a history dump.

The runtime intentionally keeps recall small: top 5 memories, roughly 600 recall tokens, and roughly 120 profile tokens. Respect those limits rather than compensating with broad repeated recalls.

The MCP server name managed by this stack is `mm-tinycontext`. Within one profile (Working or Private), Claude, Codex and OMP MUST use the same project-specific SQLite store. All three agents launch `mm-tinycontext-mcp`, which resolves the same repository identity for Git's primary worktree and its linked worktrees. Working and Private use distinct database directories; never mix data across profiles.

When handing work between agents, save a short checkpoint containing the completed step, unresolved issue, important paths, and next suggested action, then the receiving agent should recall it. This is shared **curated project memory**, not automatic conversation synchronization. Use episodic memories for project decisions; reserve `profile` memories for genuine all-project preferences within that profile. Run `mm-project-memory-doctor` in the repository to verify all three agents use the same store. Start CLIs from inside the intended repository using the named profile wrappers; avoid changing projects via CLI `-C` without restarting the wrapper from the target directory.
