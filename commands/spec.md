---
description: Open a spec session — read the Spec lane of the queue, make the open decisions, and write the spec a build session can act on
---

This is a **spec** session (the planning lane). You decide *what* to build and *why*; you do not build it. Be concise. Produce a decision or a written plan, never an option menu.

**Print `Session start: <git rev-parse --short HEAD>` in your first reply.** `/queue:end` uses that commit as the session's starting point.

**Work in a worktree.** Before any other tool call, call `EnterWorktree` with `name` = `<lane>-<N>-<YYYYMMDD>` (for example `spec-2-20260925`), where `<N>` is the lowest number that no live `<lane>-*` entry in `git worktree list` uses. Read the result text. `Created` means the name is yours. `Resumed` means another terminal took that name first: call `ExitWorktree` with `action: "keep"` at once, bump `<N>`, and retry. Never enter an existing worktree by `path`, because that puts two sessions in one tree. Add the worktree path and the launch branch to the `Session start:` line. Skip this step if the session is already in a worktree. If the `EnterWorktree` tool is unavailable, or the repo does not use worktrees, skip this step and work in the current checkout; the explicit-path git rules still apply. **Keep the launch folder.** Before `EnterWorktree`, run `git rev-parse --show-prefix` in the launch directory. When it prints a subfolder (`apps/web/`), the worktree still opens at the repo root, so `cd` into that same subfolder inside it right after entering, write the subfolder and its queue's absolute path on the `Session start:` line, and read that queue by that path for the rest of the session. Otherwise a lane launched in a monorepo project folder reads the root queue and the root `CLAUDE.md`. Tell any subagent you dispatch the worktree path.

**Claim your item so a parallel session skips it.** Right after reading the queue, pick the lane item and record it: `git config branch.<your-branch>.description "<item title, first ~80 chars>"`. Before picking, run `git config --get-regexp 'branch\..*\.description'` and skip any item a live `<lane>-*` branch already holds. After writing, re-run the regexp. If another live `<lane>-*` branch holds the same item, the lower `<N>` keeps it; the higher one runs `git config --unset branch.<your-branch>.description` and picks the next free item. Print `Claimed: <item>` once the claim stands.

**The queue contract.** A row is added on purpose, by a person or by the `/queue:spec` or `/queue:audit` session opened to write it, never as a by-product. A finished row is deleted in the commit that finishes it; the commit message is the record, so no `[done]` rows are kept.

1. **Find the queue.** The queue is the nearest `QUEUE.md` from the launch directory up to, but excluding, the repo root (a monorepo keeps one per project folder, e.g. `apps/web/QUEUE.md`); with none, `Documentation/planning/QUEUE.md`, then `QUEUE.md` at the repo root. Use that chain in every repo; invent no other location. **A root session leaves folder queues alone:** launched at the repo root, it reads, plans and edits nothing inside a subfolder that has its own `QUEUE.md`, and works only the root queue. When the root lane has nothing this session can take, it names each folder queue as where work sits (`web has its own queue — launch in apps/web`) and stops. That project is worked only from a session launched in its folder. The file starts with `## ▶ NEXT SESSION — START HERE` (the handoff), then `## Settled` (decisions already made), then the lanes: `## Inbox`, `## Build`, `## Spec`, `## Meta`, `## Audit`. The top open item of a lane is marked `[HEAD]`. Read the handoff and `## Settled` first.

2. **Triage `## Inbox` first. `/queue:spec` is the only lane that does.** The other lanes add Inbox lines and leave them, so every new row goes through step 5's packing. Each Inbox item gets exactly one fate: it becomes **its own numbered row** in the lane it belongs to (`## Build`, `## Spec`, `## Meta`, `## Audit`) with its own **Files** and **Done when**; or it is done now, when that is cheaper than writing the row; or it is deleted, with a `Dropped: <item> — <reason>` line in this session's commit body. Never fold an Inbox item into an existing open row, because rows that absorb new items grow until no session can close them. Leave `## Inbox` empty when done: it is a landing zone, not a backlog. Say in one line what you triaged and where each item went. A queue with no `## Inbox` section skips this step.

3. **Take the top item of `## Spec`.** That is this session's work. Read every item in the lane before choosing, because file order is arrival order, not priority.

   **Fallback if the lane is empty:**
   1. The repo's open planning docs: an unfinished spec, or a plan file marked *awaiting decision*.
   2. Otherwise, say the Spec lane is empty, name what you looked at, and ask what to plan.

4. **Do the planning work.** For the item you took:
   - State the goal in one sentence and the decisions that have to be made.
   - **Make the calls you own.** Escalate only money or spend, credentials, publishing or sharing data, account/legal/platform-gated steps, irreversible actions, and taste or values calls. "Not fully sure" is a confidence level: state it and decide.
   - **Verify before deciding.** Check the code, measure it, or check current best practice, rather than settling an approach from memory alone.
   - Name the **Guardrails**: the conditions to hold so this lands right, and what a builder would get wrong reading only the summary.

5. **Write the plan where a build session will find it.** A plan that lives only in this transcript did not happen.
   - **The plan is the Build rows themselves.** Write no separate plan file unless asked; if one is written, delete it in the commit that finishes its last row.
   - Add the concrete steps to `## Build` as `[ ]` items, each with **Files**, **Guardrails**, and **Done when** lines, so `/queue:build` can act on them with no further interpretation.
   - **Plan parallel waves wherever build steps are file-disjoint.** A build session can dispatch several `architect-crew:builder` subagents (optional subagents from the architect-crew plugin, dispatched as `architect-crew:scout`, `architect-crew:runner` and `architect-crew:builder`; without them, do the step in the main session) in one message, so a wave finishes in the time of its slowest member. Mark each wave with a line directly above its first member:

     ```markdown
     **Parallel wave 1:** Build 3, Build 4 — file-disjoint, dispatch as `architect-crew:builder` subagents
     in one message. The main session owns `src/registry.py`.
     ```

     **Every item in a wave carries three more lines**, so the dispatch prompt is the decision rather than the problem:

     - **Owns:** the exact files it may write. No two items in a wave name the same file.
     - **Interface:** the contract it must meet: function signature, schema, CLI flag, or section heading. Builders cannot talk to each other, so this makes the pieces fit.
     - **Test:** one command that verifies that item alone.

     **Two rules keep a wave safe:**

     - **A hub file goes to exactly one item, or to the main session.** Registries, import hubs, `__init__.py`, `QUEUE.md`: anything several items want to touch. Name its owner on the wave line. If more than one item needs it, the main session writes it after the wave returns.
     - **A dependent item belongs to a later wave.** If Build 5 reads what Build 3 writes, Build 5 is wave 2. Items inside a wave run at once; waves run in order.

     Leave a lone item unmarked. When nothing in the lane is file-disjoint, say so in one line rather than forcing a grouping.
   - **Pack the Build lane into sessions, and count them.** The unit a spec session hands over is a session plan (`Session 1`, `Session 2`, ...), rather than a flat list of rows. Pack by three keys, in this order:
     1. **Files touched.** Write each row's owned files down first, merge every pair of rows whose files overlap into one session, and only then look at anything else. Packing by feature instead leaves two sessions writing the same hub files.
     2. **The same expensive step.** Rows that end in the same long re-run, probe, render, or full test pass go into one session, so that step runs once rather than per row.
     3. **File-disjointness inside the session.** What is left becomes the parallel waves above. A file-disjoint tail (packaging, docs) rides as the last wave of the session before it rather than becoming its own session.

     **Rows step 2 just wrote from the Inbox are packed by the same keys.** A row whose files an unheld group already owns joins that group. A row whose files belong to a group a live lane holds (a worktree or branch claims it) goes in a new group marked `after Session N`; leave the held group's text unedited.

     **Name the packing key on each session line**, so a later session can tell whether the grouping still holds: `Session 2 — packed by file: src/parser.py, tests/test_parser.py`.

     **Group labels are `Session N` and nothing else.** A property of a group (unattended, attended, `after Session N`) is a tag on the line, such as `Session 3 — unattended — packed by file: …`, never a new letter in the label. Work that needs a person present is a `Sitting N`, which `/queue:build` never claims. `/queue:build` names its worktree from the label, so an invented label becomes an invented worktree name, and two terminals can end up building the same row.

     A session's size is bounded by escalations, rather than row count: order the unattended rows first and cut the session at the first row that waits on a human, so an unattended run reaches a clean commit. Close a row that is already built, or whose premise a later change refuted, rather than carrying it. **End every plan with a burn-down line**: N sessions to done, which rows each carries, which rows stay blocked and on what. A good plan means fewer total sessions, less wall-clock per session, and fewer tokens per session.
   - Delete the `## Spec` item in the same commit; the commit message records the decision.
   - If a decision needs a human, add it to `OPEN_QUESTIONS.md` (an optional file listing things waiting on a human; `Documentation/planning/` or the repo root), in the same commit, with the date and the row it unblocks. Ask first whether a human is really needed; a reversible call inside the work is yours to make.

6. **Report.** The decisions made and your confidence, what went into `## Build`, and anything escalated, as short prose bullets rather than a survey.

**Wrap yourself.** When the work stops (the lane item is done, a stop line is hit, or context runs thin), as the last step: invoke the `queue:end` skill (the `/queue:end` command); if that is unavailable, tell the user to type `/queue:end`.

If `$ARGUMENTS` is provided, treat it as the topic to spec, ahead of the lane's top item.

**Named `/queue:spec` rather than `/plan` on purpose:** `/plan` is a built-in Claude Code command that toggles plan mode, and what happens when a custom command shadows a built-in is undocumented. The two are complementary: plan mode is a read-only mode within a session; `/queue:spec` is a session type that ends by writing files. Using plan mode during a `/queue:spec` session is a good fit.
