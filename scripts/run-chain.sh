#!/usr/bin/env bash
# run-chain.sh: run queue lanes one after another with no person, on one chain branch.
#
# Usage: run-chain.sh <repo-dir> [max-sessions] [max-total-usd]
#   FIRST_LANE=spec|build|audit   lane to start with (default spec)
#   EXTRA_TOOLS="Bash(npm test*)"  extra allowed tools, comma-separated, for the repo's test command
#   PLUGIN_DIR=<folder>            load the queue plugin from this folder instead of the installed one (to test a branch)
#
# Each lane is one headless Claude Code session (`claude -p "/queue:<lane>"`), so each starts
# fresh and reads only the handoff block. The runner itself is not an AI: it waits for free.
# Flow: check the repo is ready, make a chain branch from the base, run lanes on it while the
# handoff's **Next lane:** line says so, then open one pull request for a person to review.
# It stops on anything unexpected; it never merges and never touches the base branch.

set -u
REPO=${1:?usage: run-chain.sh <repo-dir> [max-sessions] [max-total-usd]}
MAX_SESSIONS=${2:-6}
MAX_TOTAL_USD=${3:-8}
MAX_AUDIT_FAILS=2
PER_SESSION_USD=2
PER_SESSION_TURNS=80
PER_SESSION_SECONDS=1200
FIRST_LANE=${FIRST_LANE:-spec}

# Only what a lane needs. No open shell: no PowerShell tool, no bare Bash, and only the git
# subcommands a lane uses. Push is allowed only as a bare `git push`, which sends the current
# branch to its upstream: the chain branch, since the runner sets it.
TOOLS="Read,Edit,Write,Glob,Grep,Skill,Agent,EnterWorktree,ExitWorktree,Bash(git push),Bash(gh pr view *),Bash(ls *),Bash(cat *),Bash(cd *)"
while IFS= read -r g; do [ -n "$g" ] && TOOLS="$TOOLS,Bash(git $g)"; done <<'EOF'
status*
add *
commit *
log*
diff*
show*
grep *
rm *
mv *
rev-parse*
check-ignore *
fetch*
pull --rebase*
rebase *
merge --ff-only *
worktree *
branch*
config branch.*
config --get-regexp *
EOF
[ -n "${EXTRA_TOOLS:-}" ] && TOOLS="$TOOLS,$EXTRA_TOOLS"
# Anything not allowed above is already refused; these are named so a wide EXTRA_TOOLS can't undo them.
DENY="Bash(gh pr create *),Bash(gh pr merge *),Bash(git push --*),Bash(git push -f*),Bash(git push origin*),Bash(git switch*),Bash(git checkout*),Bash(git -C*),Bash(git reset --hard*),Bash(git branch -f*),Bash(git branch -D*)"

stop() { echo "stop: $*"; exit 1; }
PY=""
for p in python3 python py; do
  if command -v "$p" >/dev/null && "$p" -c pass >/dev/null 2>&1; then PY=$p; break; fi
done
[ -n "$PY" ] || stop "a working python is needed to read the run reports (the Windows Store stub does not count)"
command -v claude >/dev/null || stop "claude is not on PATH"
command -v gh >/dev/null && gh auth status >/dev/null 2>&1 || stop "gh is missing or signed out (run: gh auth login)"
PLUGIN_ARGS=()
if [ -n "${PLUGIN_DIR:-}" ]; then
  [ -f "$PLUGIN_DIR/commands/end.md" ] || stop "no queue plugin in PLUGIN_DIR=$PLUGIN_DIR"
  PLUGIN_ARGS=(--plugin-dir "$PLUGIN_DIR")
else
  claude plugin list 2>/dev/null | grep -q 'queue@' || stop "the queue plugin is not installed for headless runs"
fi
TIMEOUT=""
for t in timeout gtimeout; do
  if command -v "$t" >/dev/null && "$t" 1 true >/dev/null 2>&1; then TIMEOUT=$t; break; fi
done
[ -n "$TIMEOUT" ] || echo "warning: no working timeout command; each session is capped by turns and spend only"

cd "$REPO" || stop "no repo at $REPO"
[ -f QUEUE.md ] || stop "no QUEUE.md in $REPO"
[ -z "$(git status --porcelain)" ] || stop "the working tree has changes; commit or stash them first"
BASE=$(git rev-parse --abbrev-ref HEAD)
DEFAULT=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
[ "$BASE" = "$DEFAULT" ] || stop "start from the default branch ${DEFAULT:-?}, not $BASE"
git fetch -q origin && git merge -q --ff-only "origin/$BASE" 2>/dev/null || stop "could not update $BASE from origin"

STAMP=$(date +%Y%m%d-%H%M%S)
CHAIN="chain-$STAMP"
git switch -q -c "$CHAIN" && git push -q -u origin "$CHAIN" || stop "could not make and push branch $CHAIN"

LOGDIR="$REPO/../chain-$STAMP"
mkdir -p "$LOGDIR"
LOG="$LOGDIR/chain-log.tsv"
printf 'n\tlane\texit\tis_error\tturns\tseconds\tcost_usd\tinput\tcache_create\tcache_read\toutput\tdenials\tnext\tverdict\tblocked\n' > "$LOG"
echo "claude $(claude --version 2>/dev/null)" > "$LOGDIR/version.txt"
git rev-parse HEAD > "$LOGDIR/start-commit.txt"

RULES="Runner rules for this unattended run (no person is watching):
- Land with Land: push onto the launch branch $CHAIN, whatever CLAUDE.md says. Never open or merge a pull request: the runner opens one at the end. Never push to $BASE.
- Write the handoff block's Next lane line, and in an audit session the Audit verdict line, exactly as /queue:end says.
- Never start a Meta session and never pick meta as the next lane.
- Run one shell command per tool call; do not chain commands with && or newlines.
- Anything that needs a person (money, publishing, credentials, taste): write it under Blocked on and set Next lane to none."

field() { # field <label>: value of the first handoff line "**<label>:** value"
  grep -m1 -E "^\*\*$1:\*\*" QUEUE.md | sed -E "s/^\*\*$1:\*\* *//; s/[[:space:]]+$//; s/\.$//"
}
written() { # the whole handoff block, from its heading to the next section, as one hash
  sed -n '/^## ▶ NEXT SESSION/,/^## Settled/p' QUEUE.md | git hash-object --stdin
}

total=0; ran=0; fails=0
lane=$FIRST_LANE
for n in $(seq 1 "$MAX_SESSIONS"); do
  case "$lane" in spec|build|audit) ;; *) echo "stop: next lane is '$lane'"; break ;; esac
  ran=$n
  before=$(written)
  echo "== session $n: /queue:$lane  (spent so far: $total USD)"
  out="$LOGDIR/run-$n-$lane.json"
  $TIMEOUT ${TIMEOUT:+$PER_SESSION_SECONDS} claude -p "/queue:$lane" "${PLUGIN_ARGS[@]}" \
    --permission-mode dontAsk --permission-prompts none \
    --allowedTools "$TOOLS" --disallowedTools "$DENY" --append-system-prompt "$RULES" \
    --max-turns "$PER_SESSION_TURNS" --max-budget-usd "$PER_SESSION_USD" \
    --output-format json > "$out" 2> "$LOGDIR/run-$n-$lane.err"
  code=$?
  pulled=yes
  git pull -q --ff-only 2>"$LOGDIR/pull-$n.err" || pulled=no   # pick up what the session pushed

  stats=$("$PY" -I - "$out" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    print("parse-error\t0\t0\t0\t0\t0\t0\t0\t0"); sys.exit()
# Sum every model in modelUsage: "usage" covers the main session only, not helper agents.
mu = (d.get("modelUsage") or {}).values()
tok = lambda k: sum(v.get(k, 0) for v in mu)
print("\t".join(str(x) for x in [
    d.get("is_error"), d.get("num_turns"), round((d.get("duration_ms") or 0) / 1000),
    round(d.get("total_cost_usd") or 0, 4), tok("inputTokens"),
    tok("cacheCreationInputTokens"), tok("cacheReadInputTokens"),
    tok("outputTokens"), len(d.get("permission_denials") or [])]))
PY
)
  first_word() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/^[^a-z]*([a-z]+).*/\1/'; }
  next=$(first_word "$(field "Next lane")"); verdict=$(first_word "$(field "Audit verdict")")
  blocked=$(field "Blocked on")
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$n" "$lane" "$code" "$stats" "${next:-?}" "${verdict:--}" "${blocked:-?}" >> "$LOG"
  cost=$(printf '%s' "$stats" | cut -f4)
  total=$("$PY" -I -c "print(round($total + ${cost:-0}, 4))")

  [ "$code" -eq 0 ] || { echo "stop: session exited with $code"; break; }
  [ "$(printf '%s' "$stats" | cut -f1)" = "False" ] || { echo "stop: session reported an error"; break; }
  [ "$pulled" = yes ] || { echo "stop: could not update the chain branch after the session (see $LOGDIR/pull-$n.err)"; break; }
  [ -z "$(git status --porcelain)" ] || { echo "stop: the session left changes it did not commit"; break; }
  [ "$(written)" != "$before" ] ||{ echo "stop: the session wrote no new handoff block (queue plugin not loaded, or it never wrapped)"; break; }
  [ -n "$next" ] || { echo "stop: handoff has no Next lane line"; break; }
  case "$blocked" in nothing*|Nothing*|none*|None*|"") ;; *) echo "stop: waiting on a person: $blocked"; break ;; esac
  if [ "$lane" = audit ] && [ "$verdict" = fail ]; then
    fails=$((fails + 1))
    [ "$fails" -le "$MAX_AUDIT_FAILS" ] || { echo "stop: the audit failed $fails times"; break; }
  fi
  "$PY" -I -c "import sys; sys.exit(0 if $total < $MAX_TOTAL_USD else 1)" || { echo "stop: chain spend cap $MAX_TOTAL_USD USD reached"; break; }
  lane=$next
done

echo "== chain over: $ran session(s), $total USD estimated"
echo "log: $LOG"
column -t -s $'\t' "$LOG" 2>/dev/null || cat "$LOG"

# One pull request for the whole chain, for a person to review and merge.
if [ -n "$(git log --oneline "origin/$BASE..$CHAIN" 2>/dev/null)" ]; then
  git push -q origin "$CHAIN" || stop "could not push $CHAIN; open the pull request by hand once it is pushed"
  body=$(printf 'Chain run by run-chain.sh: %s session(s), about %s USD at list price. Sessions ran with no person; review every change before merging.\n\n```\n%s\n```\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n' \
    "$ran" "$total" "$(column -t -s $'\t' "$LOG" 2>/dev/null || cat "$LOG")")
  gh pr create --base "$BASE" --head "$CHAIN" --title "[chain] $ran session(s) on $CHAIN" --body "$body" \
    || echo "could not open the pull request; open it by hand from $CHAIN to $BASE"
else
  echo "the chain made no commits; no pull request"
fi
