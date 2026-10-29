---
description: Open an audit session — check that what the docs claim is what the repo actually does, from the Audit lane
---

This is an **audit** session. The job is verification: find where the repo's stated position and its actual state have moved apart, then close the gap. Be concise; report findings with evidence, and fix what is cheap to fix in the same pass.

**Print `Session start: <git rev-parse --short HEAD>` in your first reply.** `/queue:end` uses that commit as the session's starting point.

**Work in a worktree.** Each lane session runs in its own git worktree so parallel sessions never edit the same tree. Before other work, call `EnterWorktree` with `name` = `audit-<N>-<YYYYMMDD>`, where `<N>` is the lowest number no live `audit-*` entry in `git worktree list` uses. Read the result: `Created` means the name is yours; `Resumed` means another terminal took it, so call `ExitWorktree` with `action: "keep"` at once, bump `<N>`, and retry. Never enter an existing worktree by path. Add the worktree path and launch branch to the `Session start:` line. Skip this when the session is already in a worktree. If the `EnterWorktree` tool is unavailable, or the repo does not use worktrees, skip this step and work in the current checkout; the explicit-path git rules still apply. **Keep the launch folder.** Before `EnterWorktree`, run `git rev-parse --show-prefix` in the launch directory. When it prints a subfolder (`apps/web/`), the worktree still opens at the repo root, so `cd` into that same subfolder inside it right after entering, write the subfolder and its queue's absolute path on the `Session start:` line, and read that queue by that path for the rest of the session. Otherwise a lane launched in a monorepo project folder reads the root queue and the root `CLAUDE.md`.

**Claim your item so a parallel session skips it.** Right after reading the queue, pick the lane item and record it: `git config branch.<your-branch>.description "<item title, first ~80 chars>"`. Before picking, run `git config --get-regexp 'branch\..*\.description'` and pass over any item a live `audit-*` branch already holds. Re-run the regexp after writing; if another live `audit-*` branch holds the same item, the lower `<N>` keeps it and the higher one unsets its description and takes the next item. Print `Claimed: <item>` once the claim stands.

**The queue contract (every opener).** A row is added on purpose, by the user or by the `/queue:spec` or `/queue:audit` session opened to write it, never as a by-product. A finished row is deleted in the commit that finishes it; the commit message is the record, so no `[done]` rows are kept. A project may cap the queue's size in its `CLAUDE.md` or a hook.

1. **Find the queue.** The queue is the nearest `QUEUE.md` from the launch directory up to, but excluding, the repo root (a monorepo keeps one per project folder, e.g. `apps/web/QUEUE.md`); with none, `Documentation/planning/QUEUE.md`, then `QUEUE.md` at the repo root. Use that chain in every repo; invent no other location. **A root session leaves folder queues alone:** launched at the repo root, it reads, plans and edits nothing inside a subfolder that has its own `QUEUE.md`, and works only the root queue. When the root lane has nothing this session can take, it names each folder queue as where work sits (`web has its own queue — launch in apps/web`) and stops. That project is worked only from a session launched in its folder. Read its `## ▶ NEXT SESSION — START HERE` block, `## Settled`, and the lanes (`## Inbox`, `## Build`, `## Spec`, `## Meta`, `## Audit`). The top item of `## Build` is marked `[HEAD]`. Also read the repo state: `git status`, recent `git log`, and the queue counts.

2. **Leave `## Inbox` to `/queue:spec`.** Only `/queue:spec` triages the Inbox, so every new row goes through its packing step. A finding this audit makes becomes a row directly; an Inbox line someone else wrote stays where it is.

3. **Take the top item of `## Audit`.** That is this session's work. Read every item in the lane before choosing: file order is arrival order, never priority.

   Every plain `/queue:audit` also runs the sweep's first two checks, recent work and then `CLAUDE.md`, after the lane item.

   **If the lane is empty:** run the repo's drift tooling if it has any and take what it flags; else run the standing sweep below; else say the Audit lane is empty and the sweep came back clean.

4. **The standing sweep.** Each line is a check with a command behind it, rather than a reading of the docs:
   - **Recent work holds what its commits claim.** List every commit since the last `[Audit]` commit (`git log --format='%h %s' <last-audit>..HEAD`). For each `[Build]` commit, check its message against the tree: the focused test it names exists and passes today (one `architect-crew:runner` per test file, dispatched together), the queue row it says it finished is gone, its Done when is met, and any figure it cites was measured rather than recalled. A commit whose claim fails is a finding; a fix that later work silently undid is the most consequential kind.
   - **Docs against reality.** Every path, filename, script, and command named in `CLAUDE.md` and the README still exists and still does what the sentence says.
   - **`CLAUDE.md` holds rules, and state lives elsewhere.** Read it line by line and ask of each sentence: will this still be true in six months? Yes: it is a rule and stays. No: it is state, so move it to `QUEUE.md` (`## Settled` or the handoff block) with a pointer, delete it, or tag it `(until <row>)` naming the open queue row that retires it. Short provenance (`measured at 96f8d693`) stays; a history sentence is git's job, so cut it. Commit the pass alone as `[Audit]: CLAUDE.md — <what moved>`.
   - **Claimed numbers.** Test counts, file sizes, item counts, version pins: re-derive each one rather than trusting the written figure.
   - **Dead surface.** Files nothing references, a skill or command superseded by another, a config key nothing reads.
   - **Forward-looking blocks.** `QUEUE.md` holds exactly one `## ▶ NEXT SESSION` block; anything superseded is deleted.
   - **Queue truth.** No finished row is still in `QUEUE.md`, every row still describes work the product needs, and `[HEAD]` sits on the next real item. Delete the rest.
   - **Growth.** `git diff --shortstat` over the last ten commits, split by the project's areas: docs or tests growing faster than the code they serve is a finding.
   - **Distance to done, measured.** Count the work actually left against the project's own definition of finished, and say whether the last ten commits moved toward it or sideways. An audit that lists only defects says the repo is tidy without saying whether it is closer to shipping.
   - **Repo hygiene.** `git status` clean, nothing unpushed, and no script left in a scratchpad that something runs again (a one-off stays there, recorded in its commit message).
   - **Things waiting on a human.** If the repo keeps an `OPEN_QUESTIONS.md` (an optional list of items only a person can answer), check that each entry is still open and that nothing the session found belongs there.

5. **Verify, never recall.** Every finding carries the command or file read that produced it. A claim that feels obviously true from context is the kind that goes stale, so check it.

6. **Close what you can, queue at most three.** Fix each cheap discrepancy in this pass. Of what needs a real build, queue the three with the most consequence in `## Build` (each with **Files**, **Guardrails** (the condition to hold so the change lands right), and **Done when**) or in `## Spec` for a decision; name the rest in the report, where the user can promote one.

7. **Delete the item from `## Audit` in the same commit, and report** the findings ranked by consequence, each with its evidence, plus what you fixed and what you queued. A clean audit is a real result; say so plainly rather than padding it.

**Wrap yourself.** When the work stops (the lane item is done, a stop line is hit, or context runs thin), as the session's last step: invoke the `queue:end` skill (the `/queue:end` command); if that is unavailable, tell the user to type `/queue:end`.

**Subagents.** This command refers to `runner` (runs a decided command and returns numbers), `scout` (reads and traces across files, returns findings with `file:line`), and `builder` (applies a decided edit, returns a diff) (optional subagents from the architect-crew plugin, dispatched as `architect-crew:scout`, `architect-crew:runner` and `architect-crew:builder`; without them, do the step in the main session).

If `$ARGUMENTS` is provided, treat it as the area to audit, ahead of the lane's top item. `/queue:audit CLAUDE.md` runs the sweep's first two checks in order (recent work since the last `[Audit]` commit, then the `CLAUDE.md` rules-versus-state check), commits the second as `[Audit]: CLAUDE.md — ...`, and skips steps 3 and 7 (no lane item is taken). It never runs the `CLAUDE.md` check alone.
