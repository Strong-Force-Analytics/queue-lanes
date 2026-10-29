# QUEUE — <project name>

One queue, four lanes, one opener command each. Copy this file to
`Documentation/planning/QUEUE.md` (or the repo root if the project has no `Documentation/` tree; in a
monorepo, a project folder such as `apps/web/QUEUE.md`, worked by launching Claude Code in that folder)
and delete the example items.

**How it works**
- `/queue:build` reads `## Build`, `/queue:spec` reads `## Spec`, `/queue:meta` reads `## Meta`, `/queue:audit` reads `## Audit`.
- Anyone adds lines to `## Inbox`; only `/queue:spec` turns them into rows, so every new row is packed
  into the right build group.
- `## Build` is packed into `**Session N — ...**` groups, each with a Files line. One `/queue:build`
  terminal claims one group (by creating a git worktree named after it), so several terminals
  can build at once without touching the same files.
- Finished rows are deleted in the commit that finishes them (no `[done]` rows); the commit
  message is the record.
- The handoff for the next session lives in the `## ▶ NEXT SESSION` block at the top. `/queue:end` rewrites it.
- `[HEAD]` marks the item `/queue:build` builds next; `/queue:end` advances it once the gate passes.
- A `**Parallel wave:**` line groups file-disjoint items that `/queue:build` can hand to several
  subagents at once. Wave members add `Owns` / `Interface` / `Test`; shared "hub" files go to one
  item or to the main session; anything dependent waits for a later wave.
- **Names.** A task is its lane word plus a number: `Build 1`, `Spec 1`, `Meta 1`, `Audit 1`.
  A number is given once and never reused, because commit messages cite it; a task split into
  parts takes decimals, `Build 2.1`.

## ▶ NEXT SESSION — START HERE (written YYYY-MM-DD HH:MM)

<!-- One handoff block, rewritten by /queue:end each session:
     One thing: the single most useful next action.
     Blocked on: what is waiting on a person, if anything.
     Next actions: 2-4 concrete steps. -->

## Settled

<!-- One dated line per decision, append-only: `YYYY-MM-DD — decision, reason`. -->

## Inbox

<!-- Untagged captures land here. Any session adds lines; /queue:spec moves each one to a lane,
     does it, or drops it, and leaves this section empty. -->

## Build

**Session 1 — packed by file:** Files `path/one.py`, `path/two.md`

- [HEAD] Build 1 — <the next thing to build, one sentence>
  - **Files:** `path/one.py`, `path/two.md`
  - **Guardrails:** <the condition to hold so this lands right — what a builder reading only the summary would miss>
  - **Done when:** <the observable gate — a passing suite, a regenerated artifact, a green run>
- [ ] Build 2 — <the one after that, same three lines>

**Session 2 — packed by file:** Files `path/three.py`, `path/four.py`, `src/registry.py`

**Parallel wave 1:** Build 3, Build 4 — file-disjoint, dispatch together. Main session owns `src/registry.py`.

- [ ] Build 3 — <a wave member carries three extra lines so the dispatch prompt is the decision>
  - **Files:** `path/three.py`
  - **Owns:** `path/three.py` — no other item in this wave writes it
  - **Interface:** <the signature / schema / flag it must meet>
  - **Test:** `pytest tests/test_three.py`
  - **Guardrails:** <...>
  - **Done when:** <...>

## Spec

- [ ] Spec 1 — <a decision that has to be made before something can be built>

## Meta

- [ ] Meta 1 — <friction in how the work gets done: a manual step, a stale rule, a missing script>

## Audit

- [ ] Audit 1 — <something to verify: a claimed number, a doc that may have drifted>
