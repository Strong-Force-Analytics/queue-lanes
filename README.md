# queue-lanes — session lanes for Claude Code

A Claude Code plugin, `queue`. One queue file per repo, four commands that each open a different
kind of session, and one command that closes it. Every session starts knowing what to do, ends by writing down what the
next one needs, and several can run at once on the same repo.

**Visual guide with diagrams:** open [`docs/session-lanes-guide.html`](docs/session-lanes-guide.html) in a browser.

> The method and the commands are by **Brett Ragozzine**, who runs every Claude Code session this
> way. Strong Force Analytics packaged them as a plugin: pull requests instead of direct pushes,
> `/queue:init`, and the architect-crew agents.

## The 30-second version

- **`QUEUE.md`** lists all pending work, sorted into lanes by *kind* of work.
- **Four openers** start a session by reading one lane:

  | Command | Lane | The session's job |
  |---|---|---|
  | `/queue:build` | `## Build` | Build the next group of rows to their "Done when" checks |
  | `/queue:spec` | `## Spec` | Make open decisions, sort the Inbox, write Build rows |
  | `/queue:meta` | `## Meta` | Improve how the work gets done: commands, rules, scripts |
  | `/queue:audit` | `## Audit` | Check that docs and claims match the code; fix or queue gaps |

- **`/queue:end`** closes any session: updates the queue, writes a handoff note at the top of
  `QUEUE.md`, commits, opens a pull request, and prints which command to run next.
- **`/queue:init`** sets a repo up once.

The lanes exist because each kind of work needs different behaviour. A build session builds and
never stops to redesign; a design gap becomes a Spec row. A spec session decides and writes it
down. Mixing them is how a session opened to ship spends an hour planning.

## What's in the kit

| Path | What it is |
|---|---|
| `commands/build.md`, `spec.md`, `meta.md`, `audit.md`, `end.md` | The five session commands |
| `commands/init.md` | `/queue:init`, which sets a repo up |
| `templates/QUEUE.md` | Starter queue with example rows |
| `docs/session-lanes-guide.html` | The visual tutorial, including the parallel-sessions diagram |
| `docs/add-to-existing-repo.md` | Step-by-step setup for a repo that already has code and a backlog |

## Install

In Claude Code:

```text
/plugin marketplace add Strong-Force-Analytics/claude-plugins
/plugin install queue@sfa-plugins
/plugin install architect-crew@sfa-plugins
```

architect-crew is optional: it gives the commands cheap subagents for reading (`scout`), running
(`runner`) and decided edits (`builder`). Without it, the main session does that work itself.

Then, in a repo, run `/queue:init`. It places `QUEUE.md`, ignores session worktrees, brings the
existing backlog into `## Inbox`, adds the work-queue section to `CLAUDE.md`, and opens a pull
request with the setup.

The commands look for the queue at the nearest `QUEUE.md` from the launch folder up to (not
including) the repo root, then `Documentation/planning/QUEUE.md`, then `QUEUE.md` at the repo root.
In a monorepo, a project folder may hold its own `QUEUE.md`; launch Claude Code in that folder.

**Adding lanes to a repo that already has code and a backlog:** `/queue:init` does it;
[`docs/add-to-existing-repo.md`](docs/add-to-existing-repo.md) walks through the same steps by hand,
and the first `/queue:spec`.

**Requirements**
- git, and a recent Claude Code that has the `EnterWorktree` / `ExitWorktree` tools. Without them
  the commands skip the worktree step and work in the current checkout; parallel sessions then
  depend on the explicit-path git rules alone.
- `gh` (GitHub CLI), signed in, so `/queue:end` can open the pull request. Without it, the recap prints
  the compare link.
- The architect-crew subagents are optional. Without them, the main session does that work itself.

**Optional project hooks the commands use when present** (nothing breaks without them):
- A `## /end in this repo` section in the project's `CLAUDE.md`: extra wrap steps, such as
  page generators to re-run, and the `Land:` line (`pull request against <branch>`, the default, or
  `push` to merge and push directly).
- Byte caps on files like `CLAUDE.md` and `QUEUE.md`, named in `CLAUDE.md` or a pre-commit hook.
  `/queue:end` reports sizes against them; `/queue:meta` moves material out when one is over.
- A briefing script (for example `scripts/brief.py`) that prints the queue head, counts and repo
  state. Openers run it if it exists; otherwise they read `QUEUE.md` and `git status`.
- `OPEN_QUESTIONS.md`: a list of things waiting on a person.

## Anatomy of QUEUE.md

```
## ▶ NEXT SESSION — START HERE    handoff note, rewritten by /queue:end
## Settled                        dated decisions, append-only
## Inbox                          raw ideas; anyone adds, /queue:spec sorts
## Build                          concrete rows, packed into "Session N" groups
## Spec                           open decisions
## Meta                           friction in how the work gets done
## Audit                          claims to verify
```

A Build row:

```
- [HEAD] Build 7 — Parse the export header into a typed record
  - Files: src/parser.py, tests/test_parser.py
  - Guardrails: header order varies by vendor; match on names, never position
  - Done when: pytest tests/test_parser.py passes on all three sample files
```

- `[HEAD]` is the row `/queue:build` takes next.
- **Guardrails** is the condition to hold so the work lands right — what someone reading only the
  one-line summary would miss.
- **Done when** is an observable check, so "finished" is a fact.
- Finished rows are deleted; the commit message is the record.
- Task numbers are never reused, because commit messages cite them.

## What each command does

**`/queue:build`**
- Picks the top `Session N` group no other terminal holds, and claims it by creating a git worktree named after it (`build-s3-<date>`). If the name is taken, it picks another group.
- Reads the handoff note and `## Settled`, checks the note against the repo, then builds the `[HEAD]` row.
- When rows are marked as a `Parallel wave` (no shared files), dispatches one `builder` subagent per row at once and reviews every diff itself.
- Commits each row as its test passes, runs the full test suite once at the end of the group.
- Stops at anything needing a human: spend, credentials, irreversible actions, taste calls. Then runs `/queue:end`.

**`/queue:spec`**
- Claims its own worktree, reads the handoff and `## Settled`.
- Sorts `## Inbox` — the only lane that does. Each item becomes its own row, gets done now, or is dropped with a reason in the commit.
- Takes the top `## Spec` item: states the goal, makes the decisions, verifies before deciding, records them in `## Settled`.
- Writes the result as Build rows with Files / Guardrails / Done when, packs them into Session groups by file, and marks file-disjoint rows as parallel waves.
- Runs `/queue:end`.

**`/queue:meta`**
- Takes the top `## Meta` item: a manual step, a stale rule, a missing script.
- Asks whether the step is truly gated (needs a person, an account, a legal step) or simply not automated yet, and automates the second kind.
- Fixes a problem at the highest level that governs it: `CLAUDE.md` > `QUEUE.md` > `/queue:meta` > `/queue:audit` > `/queue:spec` > `/queue:build`. A wrong rule high up silently corrupts everything below it.
- Climbs only as high as the actual blocker, then hands back to `/queue:build`.

**`/queue:audit`**
- Takes the top `## Audit` item, or runs a standing sweep: do recent commits do what their messages claim, do documented paths and commands exist, do stated numbers re-derive.
- Every finding carries the command or file that produced it.
- Fixes cheap gaps on the spot; queues up to three larger ones as Build or Spec rows.

**`/queue:end`**
- Waits for or stops background work.
- Sends each idea from the session to a home: `## Inbox`, `## Settled`, or the commit body.
- Rewrites the handoff note: the one most useful next action, what is blocked, next steps.
- Re-reads the note as a fresh session would and fixes anything stale.
- Commits explicit paths only, rebases the session branch onto the base, pushes it and opens a pull request (or, with `Land: push`, fast-forward merges and pushes), and removes the worktree.
- Prints `Next: /queue:build ×2 — Sessions 3 and 4 (files disjoint)` (or `/queue:spec`, `/queue:audit`, `/queue:meta`), so you know how many terminals to open next.

## A typical day

1. Drop ideas into `## Inbox` whenever they come up — by hand or by asking Claude.
2. Run `/queue:spec` to turn them into Build rows.
3. Run `/queue:build` (in as many terminals as the last `/queue:end` said).
4. Run `/queue:audit` now and then, and `/queue:meta` when the same friction shows up twice.
5. Every session ends with `/queue:end`, and the next one starts from its note.

## Running sessions in parallel

Each session works in its own worktree. `/queue:build` claims its Session group by the worktree's name
(two worktrees cannot share one), so terminals never take the same group. `/queue:spec`, `/queue:meta` and
`/queue:audit` claim their row by writing it to the branch description (`git config
branch.<branch>.description`), which every worktree can read, and skip rows another branch holds. Session groups are packed so they share no files. `QUEUE.md` is the one
shared file: on a merge conflict, keep both sessions' rows and both handoff notes, and the next
`/queue:end` folds them together.

| Pair | Fit |
|---|---|
| `/queue:build` + `/queue:build` | Good when the groups share no files — `/queue:end` tells you the count |
| `/queue:build` + `/queue:audit` | Good: code versus docs |
| `/queue:build` + `/queue:spec` | Good: spec puts new rows in a new group when one is held |
| `/queue:spec` + `/queue:spec` | One at a time is simpler; both repack groups |
| `/queue:meta` + anything | Plan it: meta edits the commands the others run |

Git rules that keep it safe: stage and commit explicit paths (`git commit -m "..." -- path`),
avoid `git add .` / `git commit -a` / bare `git commit`, commit small, and land at `/queue:end`.

With pull requests, the next session reads the queue from the default branch, so merge the
session's pull request before opening the next one, or start the next one from that branch.

## Glossary

| Term | Meaning |
|---|---|
| `[HEAD]` | A queue marker on the Build row to take next. Unrelated to git's `HEAD` |
| Session group | A heading in `## Build` (`**Session 3 — packed by file:** Files ...`) bundling rows one terminal builds in order |
| Sitting | A group that needs a person present; `/queue:build` never claims one |
| Parallel wave | Rows inside a group with no shared files, handed to several `builder` subagents at once |
| Hub file | A file several wave rows would need to edit; one owner (usually the main session) writes it |
| Gate / Done when | The observable check that makes a row finished |
| Guardrails | The condition to hold so a row lands right |
| `Owner: <name>` | A marker on a group or row meaning that teammate works it; `/queue:build` skips it and names the owner |
| Worktree | A second checkout of the repo on its own branch, under `.claude/worktrees/<name>` |
| Launch branch | The branch the session started from (usually `main`); the pull request targets the default branch |
| Main session | The Claude session you type in, as opposed to the subagents it dispatches |
| Packing | How `/queue:spec` groups rows: by the files they touch, so groups do not collide |
| Commit prefixes | `[Build]`, `[Spec]`, `[Meta]`, `[Audit]`, `[Docs]`: the lane a commit came from, so `git log --grep` finds a lane's history |

## Why there is a ranking of where to fix things

`/queue:meta` fixes a problem at the highest place that governs it: `CLAUDE.md` > `QUEUE.md` > `/queue:meta` >
`/queue:audit` > `/queue:spec` > `/queue:build`. A wrong standing rule in `CLAUDE.md` misleads every session below it,
so fixing it in one build only fixes it once. The ranking says where to fix, never where to spend
time: once the blocker is fixed, go back to `/queue:build`. Two sessions in a row that end without
building is the signal to build next.

## Notes

- The lane is called **Spec**, not Plan, because `/plan` is a built-in Claude Code command.
- The guide's diagrams use the short names (`/build` for `/queue:build`) where the full name would not fit.
- Commands are plain Markdown prompts. Edit them to fit your team; the queue format is the contract.

## License

MIT. See [LICENSE](LICENSE).
