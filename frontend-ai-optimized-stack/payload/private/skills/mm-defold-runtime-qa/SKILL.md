---
name: mm-defold-runtime-qa
description: Defold build and runtime verification loop using official automation, logs, engine state, input, screenshots, and deterministic tests.
---
# Defold runtime QA

Use an inspect -> change -> build -> run -> observe -> repair -> verify loop. Prefer official Defold automation surfaces: editor HTTP API for the open project, engine service/runtime automation for a running debug engine, and Bob for command-line builds and bundles.

When a visual or gameplay requirement is involved, verify the running result rather than relying only on source inspection. Check relevant logs, runtime state, screenshots, input/controller behavior, and deterministic tests. A screenshot proves appearance only; combine it with interaction or state evidence when behavior matters.

Do not stop because a build, scene investigation, gameplay reproduction, or validation pass takes a long time. Do not use fixed retry counts. Escalate only when a concrete blocker persists after reasonable evidence-backed attempts.
