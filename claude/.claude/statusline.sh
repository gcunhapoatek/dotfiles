#!/usr/bin/env bash
# Global statusLine command. Reads Claude Code's JSON session data on stdin
# and prints two lines:
#   Line 1: [Model] effort [style] cwd | ⑂worktree branch +staged ~modified ?untracked
#   Line 2: <bar> pct% | tokens_used/window_size | $cost | +added/-removed | Mm Ss | 5h% 7d%
#
# Field paths track the current Claude Code statusLine JSON schema
# (code.claude.com/docs/en/statusline). Git status is cached per session_id
# with a 5s TTL to keep the script fast on event-driven refreshes.

set -uo pipefail

input="$(cat)"

# --- jq extraction (single call, US-separated to keep empty fields stable) --
IFS=$'\x1f' read -r MODEL CWD SESSION_ID IN_TOK CTX_SIZE PCT COST_USD DUR_MS STYLE RL5 RL7 EFFORT WORKTREE LINES_ADD LINES_DEL < <(
  printf '%s' "$input" | jq -r '[
		.model.display_name // "claude",
		.workspace.current_dir // .cwd // "",
		.session_id // "no-session",
		.context_window.total_input_tokens // 0,
		.context_window.context_window_size // 200000,
		.context_window.used_percentage // 0,
		.cost.total_cost_usd // 0,
		.cost.total_duration_ms // 0,
		.output_style.name // "",
		(.rate_limits.five_hour.used_percentage // -1),
		(.rate_limits.seven_day.used_percentage // -1),
		.effort.level // "",
		.workspace.git_worktree // "",
		(.cost.total_lines_added // 0),
		(.cost.total_lines_removed // 0)
	] | map(tostring) | join("")'
)

DIR="${CWD##*/}"
PCT_INT="${PCT%.*}"
[ -z "$PCT_INT" ] && PCT_INT=0

# --- Git branch + dirty count (cached per session) -------------------------
CACHE_FILE="${TMPDIR:-/tmp}/claude-statusline-git-${SESSION_ID}"
CACHE_TTL=5
stale=1
if [ -f "$CACHE_FILE" ]; then
  mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
  [ $(($(date +%s) - mtime)) -le "$CACHE_TTL" ] && stale=0
fi
if [ "$stale" -eq 1 ]; then
  BRANCH=""
  STAGED=0
  MODIFIED=0
  UNTRACKED=0
  if [ -n "$CWD" ] && git -C "$CWD" rev-parse --git-dir >/dev/null 2>&1; then
    BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null)
    # Detached HEAD (rebase, bisect, checked-out SHA) → fall back to short SHA.
    [ -z "$BRANCH" ] && BRANCH=$(git -C "$CWD" rev-parse --short HEAD 2>/dev/null)
    STAGED=$(git -C "$CWD" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    MODIFIED=$(git -C "$CWD" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    UNTRACKED=$(git -C "$CWD" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
  fi
  printf '%s\x1f%s\x1f%s\x1f%s\n' "$BRANCH" "$STAGED" "$MODIFIED" "$UNTRACKED" >"$CACHE_FILE"
fi
IFS=$'\x1f' read -r BRANCH STAGED MODIFIED UNTRACKED <"$CACHE_FILE"
: "${UNTRACKED:=0}"

# --- Colors + thresholds ---------------------------------------------------
CYAN=$'\033[36m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
DIM=$'\033[2m'
RESET=$'\033[0m'

if [ "$PCT_INT" -ge 90 ]; then
  BAR_COLOR="$RED"
elif [ "$PCT_INT" -ge 70 ]; then
  BAR_COLOR="$YELLOW"
else
  BAR_COLOR="$GREEN"
fi

# --- Progress bar ----------------------------------------------------------
BAR_WIDTH=10
FILLED=$((PCT_INT * BAR_WIDTH / 100))
[ "$FILLED" -gt "$BAR_WIDTH" ] && FILLED="$BAR_WIDTH"
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && printf -v FILL "%${FILLED}s" && BAR="${FILL// /█}"
[ "$EMPTY" -gt 0 ] && printf -v PAD "%${EMPTY}s" && BAR="${BAR}${PAD// /░}"

# --- Humanize token counts -------------------------------------------------
human() {
  local n="$1"
  if [ "$n" -ge 1000000 ]; then
    awk -v n="$n" 'BEGIN { printf("%.1fM", n/1000000) }'
  elif [ "$n" -ge 10000 ]; then
    awk -v n="$n" 'BEGIN { printf("%dK", n/1000) }'
  elif [ "$n" -ge 1000 ]; then
    awk -v n="$n" 'BEGIN { printf("%.1fK", n/1000) }'
  else
    printf '%d' "$n"
  fi
}
TOK_USED=$(human "$IN_TOK")
TOK_MAX=$(human "$CTX_SIZE")

# --- Cost + duration -------------------------------------------------------
COST_FMT=$(printf '$%.2f' "$COST_USD")
DUR_SEC=$((DUR_MS / 1000))
MINS=$((DUR_SEC / 60))
SECS=$((DUR_SEC % 60))

# --- Git segment for line 1 ------------------------------------------------
GIT_SEG=""
if [ -n "$BRANCH" ]; then
  [ "${#BRANCH}" -gt 20 ] && BRANCH="${BRANCH:0:19}…"
  GIT_SEG=" ${DIM}|${RESET}"
  # Worktree marker — present only for linked git worktrees.
  [ -n "$WORKTREE" ] && GIT_SEG="${GIT_SEG} ${DIM}⑂${RESET}"
  GIT_SEG="${GIT_SEG} ${YELLOW}${BRANCH}${RESET}"
  [ "$STAGED" -gt 0 ] && GIT_SEG="${GIT_SEG} ${GREEN}+${STAGED}${RESET}"
  [ "$MODIFIED" -gt 0 ] && GIT_SEG="${GIT_SEG} ${YELLOW}~${MODIFIED}${RESET}"
  [ "$UNTRACKED" -gt 0 ] && GIT_SEG="${GIT_SEG} ${DIM}?${UNTRACKED}${RESET}"
fi

# --- Output style badge (hide when absent or "default") --------------------
STYLE_BADGE=""
if [ -n "$STYLE" ] && [ "$STYLE" != "default" ]; then
  STYLE_BADGE="${DIM}[${STYLE}]${RESET}"
fi

# --- Reasoning effort badge (absent when model has no effort control) -------
EFFORT_BADGE=""
[ -n "$EFFORT" ] && EFFORT_BADGE=" ${DIM}${EFFORT}${RESET}"

# --- Code churn segment (hide when nothing added/removed) ------------------
CHURN_SEG=""
if [ "$LINES_ADD" -gt 0 ] || [ "$LINES_DEL" -gt 0 ]; then
  CHURN_SEG=" ${DIM}|${RESET} ${GREEN}+${LINES_ADD}${RESET}${DIM}/${RESET}${RED}-${LINES_DEL}${RESET}"
fi

# --- Rate limits segment (absent for non-subscribers) ----------------------
RL5_INT="${RL5%.*}"
RL7_INT="${RL7%.*}"
[ -z "$RL5_INT" ] && RL5_INT=-1
[ -z "$RL7_INT" ] && RL7_INT=-1
rl_color() {
  if [ "$1" -ge 90 ]; then
    printf '%s' "$RED"
  elif [ "$1" -ge 70 ]; then
    printf '%s' "$YELLOW"
  else
    printf '%s' "$GREEN"
  fi
}
RL_SEG=""
if [ "$RL5_INT" -ge 0 ] || [ "$RL7_INT" -ge 0 ]; then
  RL_SEG=" ${DIM}|${RESET}"
  [ "$RL5_INT" -ge 0 ] && RL_SEG="${RL_SEG} $(rl_color "$RL5_INT")5h:${RL5_INT}%${RESET}"
  [ "$RL7_INT" -ge 0 ] && RL_SEG="${RL_SEG} $(rl_color "$RL7_INT")7d:${RL7_INT}%${RESET}"
fi

# --- Output ---------------------------------------------------------------
printf '%s[%s]%s%s%s %s%s\n' "$CYAN" "$MODEL" "$RESET" "$EFFORT_BADGE" "$STYLE_BADGE" "$DIR" "$GIT_SEG"
LINE2="${BAR_COLOR}${BAR}${RESET} ${PCT_INT}%"
LINE2="${LINE2} ${DIM}|${RESET} ${TOK_USED}/${TOK_MAX}"
LINE2="${LINE2} ${DIM}|${RESET} ${COST_FMT}"
LINE2="${LINE2}${CHURN_SEG}"
LINE2="${LINE2} ${DIM}|${RESET} ${MINS}m ${SECS}s"
LINE2="${LINE2}${RL_SEG}"
printf '%s\n' "$LINE2"
