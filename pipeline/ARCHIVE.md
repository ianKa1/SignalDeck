# Feature Archive

Two user-directed cleanups have cleared finished-feature records from the
working tree:

- **2026-07-21 (first)**: finished queue entries collapsed here; their
  specs, plans, and stage logs removed.
- **2026-07-25 (second)**: EVERYTHING prior cleared at the start of the
  natal_integrated work — all QUEUE.md entries, all DECISIONS.md entries,
  this file's feature list, and every file under specs/, plans/, logs/.

NOTHING is lost — full retrieval from git history (the parent of the
2026-07-25 cleanup commit holds the complete pre-cleanup state):

    git log --oneline --all -- pipeline/QUEUE.md
    git show <commit>:pipeline/QUEUE.md
    git show <commit>:pipeline/DECISIONS.md
    git show <commit>:pipeline/specs/<slug>.md
    git log --oneline --all -- 'pipeline/logs/<slug>/'

(slugs = kebab-case of the queue heading; docs/features/<slug>.md remain
the living per-feature docs where they exist.)
