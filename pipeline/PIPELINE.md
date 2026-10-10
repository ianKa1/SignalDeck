# Feature Pipeline Rules (v2)

This file defines how the development loop processes `QUEUE.md`. The loop reads
both files at the start of every iteration and follows these rules exactly.

## Layout

```
pipeline/
  PIPELINE.md               # this file — the rules
  QUEUE.md                  # single source of truth for feature statuses
  DECISIONS.md              # append-only decision journal — the human audit trail
  epics/<epic>.md           # shared architecture for a group of entries (surveyed once, kept true at docs-sync)
  specs/<feature>.md        # design docs (agent writes, fresh-context agent reviews)
  plans/<feature>.md        # implementation plans with checkable steps
  logs/<feature>/           # append-only audit trail, one file per stage-run
docs/
  ARCHITECTURE.md           # living architecture doc, updated every feature
  features/<feature>.md     # per-feature doc — the human's final-review artifact
```

## State machine

```
backlog → designing → spec-review → planning → implementing
        → validating ⇄ implementing (bounded) → docs-sync → accepting
        → done
        (accepting fail ↩ implementing; `blocked` = the only halt state)
```

The loop is fully autonomous: NO stage waits for a human. The review gates
that used to be human (spec review, final review) are performed by
fresh-context subagents, and every consequential verdict is recorded in
`pipeline/DECISIONS.md` (see Decision journal) for asynchronous human audit.

## THE LOOP DOES NOT STOP (the one rule that overrides everything else)

Once started, the loop runs until `LOOP-IDLE` — the state where EVERY entry
in QUEUE.md is `done` or `blocked`. Nothing else ends it. In particular:

- **Finishing a feature is not an ending.** The moment a feature reaches
  `done`, immediately begin the next actionable entry's next stage in the
  SAME reply. `done` is a transition, not a destination.
- **Do not stop to report.** Progress reports, summaries, and "say the word
  and I'll continue" are FORBIDDEN as terminal actions. The user started the
  loop; that IS the standing instruction to keep going. Report only in the
  final reply that carries `LOOP-IDLE`, or when genuinely blocked per
  Blocked discipline.
- **Do not stop to ask.** A question for the user — an open doctrine call, a
  design fork, a "which do you prefer" — is recorded in DECISIONS.md and in
  the affected QUEUE.md entry's notes, and the loop DECIDES a default and
  keeps moving (autonomous mode: the spec must decide, not ask). If a
  decision later proves wrong, the user sets `rework` + `feedback:`. The one
  exception is Blocked discipline, which requires a specific missing input
  that no default can substitute for. The loop's OWN earlier decisions
  are never such an input: it revises them (Decision precedence).
- **Context exhaustion is not a stopping condition.** The harness
  auto-compacts; the write-back discipline (Context hygiene rule 1) makes
  every stage resumable from repo files alone. Keep working through
  compaction, do not wind down as context fills.
- **A failing stage is not a stopping condition either.** Fix and re-run
  within the cycle budget; at `cycles: 3` set `blocked` and MOVE ON to the
  next actionable entry — a blocked feature parks, the loop does not.

The only two legal final states for a loop session: the reply contains
`LOOP-IDLE`, or the user interrupts.

### Watchdog (the harness that catches a stalled loop)

Because a stalled loop is silent, an interactive loop session installs a
recurring check (`CronCreate`, every ~17 minutes — an off-minute on purpose)
that: reads QUEUE.md, lists every entry's status, and if ANY entry is
actionable (anything but `done`/`blocked`), restarts the loop on the topmost
ready one (a live parallel wave is left alone; a `worktree:` entry with no
live worker is resumed in its worktree — see Parallel waves rule 8) — resuming from repo state alone (the entry's `last:` line, the plan's
checkboxes, `logs/<slug>/`) and chaining stages onward. If nothing is
actionable it answers `LOOP-IDLE (watchdog: nothing pending)` and does
nothing.

Two properties make this safe to fire at any moment: every stage is
resumable from files (Context hygiene rule 1), and re-entering a stage that
is already complete is a no-op because the checkboxes and `last:` line say
so. The job is session-only and expires after 7 days; a headless run uses
`pipeline/loop.sh` instead, which needs no watchdog because the runner
supplies each iteration. Re-install the watchdog whenever a fresh
interactive loop session starts.

Human intervention point (by design, exactly one):
1. **Intake** — only the user adds features to QUEUE.md (rough notes are
   enough), reorders them, or drops them.

Optional user overrides — honored when seen, never waited on: setting
`rework` + `feedback:` on any feature, or editing a `blocked` entry to
unblock it.

Legacy statuses from the gated era map as follows when the loop sees them:
`awaiting-spec-review` → run the auto spec review; `awaiting-final-review`
→ run auto-finalization (see status table).

## Status meanings and loop actions

| Status                 | Who sets it | Loop action when it sees this status |
|------------------------|-------------|--------------------------------------|
| `backlog`              | user        | Write `specs/<feature>.md`: /feature-spec writes the WHAT, then /architecture-designer writes its Architecture section (frontend-facing → also /frontend-design; see Skills per stage and its pipeline-mode overrides). Then set `spec-review`. |
| `spec-review`          | loop        | Auto spec review by fresh-context subagent (see below). PASS → decision entry + `spec-approved`. FAIL → revise the spec per the critique and re-review; after 2 failed revision rounds → `blocked`. |
| `awaiting-spec-review` | legacy      | Same as `spec-review`. |
| `spec-approved`        | loop        | Write `plans/<feature>.md` with /imple-plan (pipeline mode: steps with done-when checks plus the acceptance map; no architecture re-run), then set `implementing`. See Skills per stage. |
| `implementing`         | loop        | Do the next unchecked step(s) of the plan; tick them off; commit via /git-commit after each completed step/milestone. When all steps done, set `validating`. |
| `validating`           | loop        | Run tests and /verify (exercise the real app, not just tests). Log results. Pass → `docs-sync`. Fail → fix and stay in `validating`/`implementing` (see cycle budget). |
| `docs-sync`            | loop        | Update `docs/ARCHITECTURE.md` via /update-architecture-doc (diff-driven, see Skills per stage) and write `docs/features/<feature>.md` to reflect what was ACTUALLY built (not the spec's intent). If the feature belongs to an epic, update `epics/<epic>.md` (see Epic files). Then set `accepting`. |
| `accepting`            | loop        | Fresh-context acceptance check (see below). All criteria pass → auto-finalize: write `logs/<feature>/NN-final-review.md` (what was built, deviations from spec, known limitations — for the human audit) + decision entry, squash-land the feature branch onto `main` (see Git granularity), then set `done`. Any fail → back to `implementing` (counts toward cycle budget). |
| `awaiting-final-review`| legacy      | Treat as accepting-passed: auto-finalize as above → `done`. |
| `done`                 | loop        | Nothing. Feature is finished. |
| `rework`               | user (override) | Read the `feedback:` line, apply it, then set `validating`. |
| `blocked`              | loop        | Do nothing. Last resort only — see Blocked discipline. |

## Skills per stage (mandatory — never by intuition)

The loop MUST invoke these skills (Skill tool) at the stated moments; do not
substitute ad-hoc equivalents.

| Moment | Skill(s) |
|---|---|
| `designing` (spec writing) | `/feature-spec` writes the WHAT sections, then `/architecture-designer` writes the Architecture section of the SAME spec file, so the spec review checks the structure too. Frontend-facing feature → load `/frontend-design` first, so the visual/UX bar is concrete. Both skills run under the pipeline-mode overrides below. |
| `planning` | `/imple-plan` alone writes `plans/<feature>.md`, under the pipeline-mode overrides below. `/architecture-designer` is NOT re-run: the structure was decided and reviewed at designing. A step that needs a structural decision the spec did not make is a spec gap. Journal it as a deviation, or send the spec back to `spec-review`; never decide it silently in the plan. |
| `implementing` (frontend-facing) | Load `/frontend-design` before writing any UI code. |
| `docs-sync` | `/update-architecture-doc` — sync `docs/ARCHITECTURE.md` from the git diff since the doc's last update (surgical edits, no changelog narration; escalate to full re-reading only on the skill's triggers). `docs/features/<feature>.md` is written directly per the status table — it is a frozen per-feature snapshot, not the living doc. |
| Every commit, all stages | `/git-commit` — after each completed plan step or coherent milestone, and for stage-bookkeeping commits. Replaces hand-rolled `git commit` invocations. **Autonomous-mode overrides** (the pipeline has no human to ask): skip the skill's "wait for user approval" step — QUEUE.md intake is the standing approval; and use the message format `(<type>): <feature> — <summary>`, i.e. the skill's `(type):` prefix (choose the type from the skill's list by the nature of the change — `feat`/`fix`/`test`/`docs`/`refactor`/…) followed by the feature slug so the log stays scannable per feature. Everything else in the skill (analyze the diff first, choose the type by the change, stage specific files, never `git add -A`, verify with `git log -1`) applies as written. Feature work commits land on the feature's branch, never directly on `main` — see Git granularity. |

"Frontend-facing" = the feature touches `app-native/src/` or
`web-divination/src/` screens, components or theme, or any other
user-visible rendering. (`frontend/` was deleted 2026-08-15. The installed
skill is named `frontend-design`; older queue notes saying
"frontend-designer" mean this skill.)

### Pipeline-mode overrides for the design and plan skills (user ruling 2026-09-28)

**One home per fact.** The spec says WHAT must be true. Its Architecture
section says the STRUCTURE. The plan says the ORDER. None of them restates
another, or the queue notes, or the epic file; they cite them. These
overrides replace the skills' generic templates wherever the two conflict.
The skills themselves are global and stay unchanged for interactive use.

*`/feature-spec` in pipeline mode* writes exactly four sections, in about
1,500 words or fewer excluding the acceptance criteria:

1. **Goal**: at most three lines, citing the QUEUE entry. No Overview, no
   Problem Statement, no Proposed Solution narrative.
2. **Non-goals.**
3. **Decided defaults**: every open point settled. There is no "Open
   Questions" section.
4. **Acceptance Criteria**: as in Spec requirements, unchanged and never
   trimmed to meet the budget.

It asks no clarifying questions; anything unclear becomes a decided
default. It also writes no internal component design, because that is the
implementer's job.

*`/architecture-designer` in pipeline mode* writes the spec's
**Architecture** section, about 1,500 words or fewer:

- It covers only the modules this feature creates or changes: what gets
  reused (file:line), the module map, module contracts, dependency rules
  and forbidden edges, wire shapes, and any CLAUDE.md or guard-test
  amendment.
- It SKIPS the skill's Migration Steps section, because order belongs to
  the plan.
- When the feature belongs to an epic with a file in `pipeline/epics/`, it
  READS that file instead of re-surveying the codebase, cites it, and writes
  only this feature's delta. It confirms with a targeted read of just the
  modules it changes.

*`/imple-plan` in pipeline mode* writes, in about 2,000 words or fewer:

1. **Steps**: ordered and checkable. Each step names its files, its intent
   in one or two lines, and a **done-when** check (a command or a test), in
   about 60 words. It must not describe code in prose, because the
   implementer reads the real code.
2. **Acceptance map**: a table saying which step makes each acceptance
   criterion pass. Every criterion appears; this replaces a separate test
   plan.
3. **Risks for the implementer**: short, and only non-obvious ones.

It drops the skill's Code Structure, Calling Sequence, Data Flow and Test
Plan sections (the Architecture section and the criteria already hold
them), and it asks nothing.

### Epic files (`pipeline/epics/<epic>.md`)

A group of related queue entries may share one epic file. It holds the
product intent, the user rulings, what has been built, the verified reuse
map, the target modules and the dependency rules. Queue entries point to it
from their epic comment. It exists so `/architecture-designer` surveys the
codebase ONCE per epic, not once per feature. The loop keeps it true:
- each epic feature's `docs-sync` updates the "Built so far" and "Target
  modules" parts to match what actually landed;
- when the file is wrong about the code, the code wins, and the file is
  fixed in that same docs-sync.

## Context hygiene (automatic — never ask the human)

Verified against Claude Code docs (2026-07-19): the model and hooks CANNOT
invoke `/compact`/`/clear` (user-typed only), but the harness
**auto-compacts by itself** as context fills, and each headless
`claude -p` invocation starts with a **brand-new context** (the strong
form of /clear). Therefore:

1. **Compaction is automatic.** The loop never asks the user to run
   /compact and never pauses for context reasons. What makes auto-compact
   always safe is the write-back discipline: BEFORE every commit, the plan
   checkboxes, QUEUE.md `last:`, and the stage log fully describe where
   work stands — anything the harness summarizes away is recoverable from
   files. This discipline is mandatory precisely because compaction can
   happen at any moment.
2. **Fresh context per stage/feature is structural, not requested.**
   (a) Every stage-run must be resumable from repo files alone;
   (b) spec-review and accepting always run in fresh-context subagents;
   (c) for fully-unattended runs, `pipeline/loop.sh` drives one iteration
   per fresh `claude -p` session — automatic clean context every
   iteration, no human involvement. In interactive sessions the operator
   MAY type /clear between features, but the loop never requires,
   requests, or waits for it.
3. **Idle sentinel:** when nothing in QUEUE.md is actionable, the loop's
   final reply must contain the exact line `LOOP-IDLE` (loop.sh's exit
   condition).

## Spec requirements

Every spec has the sections set by the pipeline-mode overrides (Skills per
stage): Goal, Non-goals, Decided defaults, Architecture, and Acceptance
Criteria. Every spec MUST end with an **Acceptance Criteria** section where each
criterion is a concrete, checkable behavior ("entering 1990-06-15 08:30
Beijing shows Sun in Gemini") — never a wish ("chart looks good"). If a
criterion cannot be verified by running the app or a test, rewrite it until
it can. The acceptance stage checks exactly this list, nothing else.

## Acceptance check (maker never grades its own work)

The `accepting` stage MUST be run by a fresh-context subagent (Agent tool,
Explore or general-purpose) that is given ONLY: the spec's acceptance
criteria, how to run the app/tests, and write access to the log. It has not
seen the implementation conversation. It returns a per-criterion verdict
(pass/fail + evidence). The main loop records the verdict verbatim in the
log — it must not soften or reinterpret failures.

## Auto spec review (replaces the human design gate)

Run by a fresh-context subagent (Agent tool) that has NOT seen the design
conversation. Its inputs, exactly: the feature's QUEUE.md entry (the user's
rough notes), the spec (including its Architecture section), the epic file
if the entry belongs to one, `CLAUDE.md` (architecture contract), and this
file's Spec requirements section. It returns PASS/FAIL plus critique
against this checklist:

1. The spec serves the user's notes (intent, not wording) and is
   right-sized — no invented scope.
2. Every acceptance criterion is concretely checkable by running the app
   or a test.
3. Nothing violates the Architecture Contract in CLAUDE.md, and the
   spec's Architecture section is consistent with the epic file (or states
   and justifies the change).
4. Non-goals are stated, and every open question carries a decided default
   (autonomous mode: the spec must decide, not ask).

The verdict is recorded verbatim in the stage log; the approval and any
notable spec decisions go to the decision journal.

## Decision precedence (user ruling 2026-09-29)

Not everything in DECISIONS.md binds equally. Highest first:

1. **User rulings** — only the **What** of a DECISIONS.md entry whose
   heading says `user ruling`, or a CLAUDE.md / PIPELINE.md rule marked
   user-directed / user ruling. A constraint written in such an entry's
   Why, Risk or Alternatives lines is NOT a user ruling; it is the loop's
   own derivation.
2. **The current QUEUE.md entry** — the feature the user queued.
3. **Loop decisions** — everything else in DECISIONS.md (spec approvals,
   plan choices, derived constraints), and the code, tests and CLAUDE.md
   text they produced.

A higher tier overrides a lower one. When a queued feature conflicts with a
tier-3 decision, the loop REVISES that decision itself: `designing` lists
each conflicting earlier decision in the spec, the feature changes the code,
tests and docs that encode it, and the journal entry names it under
**Supersedes**. That is never a reason to block. Only a conflict with a
tier-1 ruling blocks (see Blocked discipline).

## Decision journal (pipeline/DECISIONS.md — the human audit trail)

Append-only, newest entry last. This is the file the user reads to find
where the loop went wrong — write every entry for a skeptical reader
catching up long after the fact.

An entry MUST be appended for: every auto spec approval, every
auto-finalization, every architecture-affecting choice, every deviation
from spec or plan, every open question the loop decided on its own, every
cycle-budget exhaustion, and every `blocked`.

Entry format:

```markdown
### YYYY-MM-DD · <feature> · <stage> — <one-line decision>
- **What**: the decision taken
- **Why**: rationale, with evidence (test output, reference values, verdicts)
- **Alternatives**: what was rejected, and why
- **Risk**: what could be wrong; what a reviewer should double-check
- **Evidence**: logs/<feature>/NN-*.md, commit hash(es)
- **Supersedes**: (only when it replaces an earlier decision) the earlier
  entry's heading, verbatim
```

The journal stays append-only: an outdated entry is never edited or
deleted. A later entry with **Supersedes** retires it, so a reader who meets
the old entry must search for its heading before treating it as current.

## Cycle budget (loops must halt)

Each trip back to `implementing` from `validating` or `accepting` increments
`cycles:` in the feature's QUEUE.md entry. At `cycles: 3`, stop retrying:
set `blocked` with a decision entry stating honestly what still fails and
why the loop could not fix it. Never grind past the budget, and never mark
a feature with failing criteria `done`.

## Blocked discipline

Before setting `blocked`, the loop MUST first attempt to decompose the
obstacle into smaller steps and try at least one. Only if that fails, set
`blocked` with a `blocked-on:` line stating the specific missing input —
"blocked-on: need an ephemeris data source decision (options logged in
logs/<feature>/…)" — never vague ("blocked-on: it doesn't work").

Blocking on a RULING CONFLICT has a stricter bar (see Decision precedence):
the `blocked-on:` line must quote the tier-1 user ruling's text and cite its
source (the DECISIONS.md entry heading, or the CLAUDE.md / PIPELINE.md
rule). If the loop cannot quote a tier-1 source, the constraint is its own
decision: revise it and keep going.

## Logging (append-only audit trail)

Every stage-run appends a file `logs/<feature>/NN-<stage>.md` (NN =
two-digit sequence: `01-designing.md`, `02-validating.md`,
`03-accepting.md`, …). Never edit or delete earlier log files. Each log
records: what was attempted, commands run, actual output/results (including
failures, verbatim), and the resulting status transition. Test/validation/
acceptance logs are the user's evidence at audit time — write them for a
skeptical reader.

## Git granularity (one feature = one commit on main)

`main`'s history is one commit per feature. Stage-by-stage commits still
happen — they remain the crash/compaction safety net and the diffable audit
trail — but on a feature branch, and they are squashed away when the
feature lands.

0. **The working branch.** The working branch is the branch checked out in
   the primary checkout when the loop session starts. Usually it is `main`.
   For an epic developed on its own branch (e.g. `feature/divination_web`),
   it is that branch. Features branch FROM the working branch and land
   BACK ON it. Every "`main`" in rules 1 and 3 below means the working
   branch. Landing the working branch itself onto `main` is the user's
   call, never the loop's.
1. **Branch on first touch.** The first stage-run that takes a feature out
   of `backlog` creates `feature/<slug>` from the working branch. Every later
   stage-run for that feature starts by switching to that branch if not
   already on it (this is what makes interleaved features safe).
2. **WIP commits as before.** On the branch, commit via /git-commit per the
   iteration rules, same `(<type>): <feature> — <summary>` format. These
   commits exist for resumability and audit; they never reach `main`.
3. **Land at `done`.** Auto-finalization ends with: switch to `main`,
   `git merge --squash feature/<slug>`, commit ONCE via /git-commit as
   `(feat): <feature> — <one-line summary of what the feature does>`,
   verify with `git log -1`, then delete the branch. If the squash
   conflicts because `main` moved, first merge `main` into the branch,
   resolve there, re-run the test suites, then squash.
4. **Exceptions — allowed direct-to-main commits:** repo-wide chores not
   tied to a queue feature (gitignore, pipeline rule edits, user-directed
   one-offs), and post-`done` `rework`, which lands as its own single
   `(fix): <feature> — …` commit (use a short-lived branch if the rework
   spans multiple iterations). A `blocked` feature keeps its branch parked
   until unblocked or the user drops it.
5. **Nothing under `pipeline/` is ever committed** except this rules file
   (PIPELINE.md) and the runner (loop.sh) — user decision 2026-07-21,
   enforced by .gitignore. All bookkeeping — QUEUE.md, DECISIONS.md,
   ARCHIVE.md, specs/, plans/, logs/ — lives on disk only. Consequently,
   an iteration whose only changes are pipeline bookkeeping has nothing
   to commit: skip the /git-commit call, never force-add ignored files.

## Parallel waves (independent features run side by side)

User ruling 2026-09-28: features that do not depend on each other are
implemented in parallel. Each gets its own git worktree and branch and
merges back into the working branch.

A **wave** is every feature that is ready at the same moment (see Iteration
rules 1). A wave of one is simply the serial flow above. For a wave of two
or more, the loop becomes a COORDINATOR:

1. **Gates stay with the coordinator, one feature at a time.** The
   coordinator runs `designing` → `spec-review` → `planning` for each
   feature in the wave, in queue order, in the primary checkout. These
   stages only write `pipeline/` files, are cheap, and the review stages
   need a fresh-context subagent that the coordinator dispatches.
2. **One worktree and one branch per feature.** For each feature, run
   `git worktree add ../astrology-wt/<slug> -b feature/<slug> <working-branch>`.
   Worktrees live OUTSIDE the repo so no tool walks into them. Then prepare
   the worktree:
   - Run `npm install` at its root.
   - Symlink the gitignored runtime inputs from the primary checkout:
     `.env`, and the three ephemeris files `server/data/*.se1` (each file,
     never the `server/data/` directory).
   - Do NOT share `server/data/*.db`. Each worktree gets its own SQLite
     files, so parallel suites cannot see each other's rows.

   Write `worktree: ../astrology-wt/<slug>` into the entry and set
   `status: implementing`.
3. **One worker per worktree, all dispatched in ONE message** (Agent tool,
   general-purpose, `run_in_background`). A worker's inputs are the
   worktree's absolute path, the spec, the plan and CLAUDE.md. A worker:
   - works ONLY inside its worktree;
   - commits WIP there via /git-commit, as in Git granularity rule 2;
   - runs `implementing` → `validating` → `docs-sync` for its one feature;
   - then returns a short report: status reached, the decision entries it
     wants journaled, and the log files it wrote.

   Its budget is the same Cycle budget. At `cycles: 3` it reports `blocked`
   with the reason, and the coordinator records it.
4. **Single writers for shared bookkeeping.** `pipeline/` is gitignored,
   so it exists ONLY in the primary checkout. Workers read and write it by
   absolute path, and ONLY their own files: `specs/<slug>.md`,
   `plans/<slug>.md` checkboxes and `logs/<slug>/`. `QUEUE.md` and
   `DECISIONS.md` have ONE writer, the coordinator. It updates an entry's
   `status:`/`last:` and appends the worker's decision entries when that
   worker reports. The plan checkboxes and logs are what make a worker
   resumable, so the write-back discipline (Context hygiene rule 1) applies
   inside the worktree exactly as it does outside.
5. **Shared machine resources.**
   - Unit and integration suites (pytest, jest, tsc) run freely in
     parallel.
   - Anything that binds a port gets a per-worktree offset: worker N (from
     1) uses port 8000+N for the backend and 5173+N for the web dev server.
     The primary checkout keeps the default ports.
   - The iOS simulator is ONE device. /verify on it is serialized: a worker
     that needs it reports `validating — needs device`, and the coordinator
     runs those device checks one at a time.
6. **Accept and land serially, in queue order.** When a worker reports
   `docs-sync` done, the coordinator runs `accepting`. That is the same
   fresh-context acceptance check, run against the worktree. On PASS the
   coordinator lands the feature from the primary checkout:
   `git merge --squash feature/<slug>` onto the working branch, ONE
   /git-commit, then verify. If the squash conflicts because an earlier
   wave member already landed:
   - merge the working branch into `feature/<slug>` INSIDE its worktree;
   - resolve the conflicts there;
   - re-run the suites there;
   - then squash.

   After landing, run `git worktree remove ../astrology-wt/<slug>`, delete
   the branch, remove the `worktree:` line, and set `done`. An acceptance
   FAIL sends the feature back to its worker, which is resumed via
   SendMessage when possible and otherwise re-dispatched on the same
   worktree. The trip counts toward the cycle budget.
7. **A wave does not block the queue.** Whenever a feature lands, re-check
   readiness. A feature whose `depends:` just became satisfied joins the
   running wave: the coordinator gates it and dispatches its worker without
   waiting for the rest of the wave to finish.
8. **Crash and compaction recovery.** An entry that carries a `worktree:`
   line but has no live worker this session (for example after a new
   session, the watchdog, or loop.sh) is resumed IN that worktree. The
   coordinator re-dispatches a worker on the same path; the worker reads
   the plan checkboxes and `logs/<slug>/` and continues. The coordinator
   never recreates or resets an existing worktree. A `blocked` wave member
   keeps its worktree and branch parked, like a blocked serial feature.

## Iteration rules

1. Process the topmost READY feature in `QUEUE.md`: its status is actionable
   (anything except `done`, `blocked`) and every entry named in its
   `depends:` line is `done` (see Queue entry format). Queue order =
   priority; the user reorders entries to reprioritize. When TWO OR MORE
   features are ready at once, run them as a parallel wave (see Parallel
   waves) instead of one after another.
2. **One stage per iteration — but an iteration is not a reply.** Do one
   status transition's worth of work, update `QUEUE.md`, append the log,
   then START THE NEXT ITERATION immediately. In a headless `claude -p` run
   the runner supplies the next iteration; in an interactive session YOU do,
   in the same reply, without pausing. Exception: `implementing` may span
   many iterations — one coherent chunk per iteration, ticked off in the
   plan. Never end a reply on a completed transition; end only on
   `LOOP-IDLE` (see THE LOOP DOES NOT STOP).
3. Keep `QUEUE.md` truthful: update `status:` the moment a stage completes;
   maintain `last:` and `cycles:` — see QUEUE.md carries STATE, not evidence.
4. If git is initialized, commit at the end of every iteration — and during
   `implementing`, after each completed step/milestone — always by invoking
   the /git-commit skill (Skill tool), applying the autonomous-mode
   overrides in Skills per stage (no approval wait; message
   `(<type>): <feature> — <summary>`), so every stage is diffable and
   revertable. These commits go on the feature's branch, never `main`
   (see Git granularity); `main` receives exactly one squash commit per
   feature at `done`. Iterations that changed only untracked pipeline
   bookkeeping (Git granularity rule 5) have nothing to commit — skip
   the call.
   Never hand-roll `git commit` directly. The write-back-before-commit
   discipline (Context hygiene rule 1) is what makes the session safely
   compactable/clearable at any moment — never skip it.
5. If — and ONLY if — nothing is actionable, i.e. every feature is `done` or
   `blocked`: report the blocked items (with their `blocked-on:` lines) and
   anything the user must decide, include the exact line `LOOP-IDLE` in the
   reply, and stop the loop. Before writing `LOOP-IDLE`, re-read QUEUE.md
   and verify entry by entry that no status is actionable; a loop that
   idles with work left in the queue is the worst failure mode there is.
6. Never invent new features. Only the user adds entries to `QUEUE.md`.

## Queue entry format

```markdown
## <feature-slug>
status: backlog
depends: <comma-separated slugs, or `none`>
cycles: 0
notes: <optional context from the user>
feedback: <only for rework — what to change>
worktree: <loop writes this only while the feature runs in a parallel wave>
last: <loop writes this — one SHORT line, ≤200 characters>
```

`depends:` is written by the USER, the same as `notes:`. The loop never
edits it. An entry WITHOUT a `depends:` line depends on every entry above it
that is not yet `done`, which is the old strictly-serial behaviour. So only
an explicit `depends:` line makes an entry eligible to run in parallel.
`depends: none` means the entry can start at once. A `depends:` names only a
FUNCTIONAL dependency: a feature that cannot be built or verified until the
named one exists. Touching the same files is never a reason to depend —
parallel features run in their own worktrees and conflicts are resolved at
landing (user ruling 2026-09-29). A slug that names no
entry, or a cycle, is a queue error: the loop records it in DECISIONS.md and
treats the entry as serial.

## QUEUE.md carries STATE, not evidence (user ruling 2026-08-30)

The queue is a status board. The only things the loop writes into an entry are
`status:`, `cycles:`, and a `last:` line that is **one short sentence naming the
transition and pointing at the file that holds the detail** — a soft cap of 200
characters, e.g.:

```
last: 2026-08-30 validating → docs-sync — suites + device pass green; logs/<slug>/12-validating.md
```

Findings, verdicts, measurements, verbatim grader output, deviations and
rationale go where they already belong and nowhere else:
`pipeline/logs/<slug>/NN-<stage>.md` (the audit trail), `pipeline/specs/`,
`pipeline/plans/`, `pipeline/DECISIONS.md`. Duplicating them into QUEUE.md makes
the one file the user reads to see WHERE WORK STANDS unreadable, and creates a
second copy of the truth that drifts from the log.

Historical entries in QUEUE.md carrying paragraph-length `last:` blobs are the
anti-pattern this rule ends, not a precedent to match. Leave them; do not extend
them. When a `last:` line needs more than a sentence, that is the signal the
stage log is missing something — write it there.
