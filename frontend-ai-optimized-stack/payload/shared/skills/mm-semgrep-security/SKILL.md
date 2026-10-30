---
name: mm-semgrep-security
description: Uses Semgrep as a deterministic security validation lane after code changes.
---
# Semgrep security lane

Use Semgrep after security-relevant changes and before declaring a substantial implementation complete. Treat findings as evidence to investigate, not as automatic truth. Fix findings that are valid and in scope; document false positives briefly. Prefer repository-specific Semgrep configuration when present.
