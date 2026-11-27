#!/usr/bin/env bash
# Global PreToolUse hook (matcher: Bash). Blocks:
#   - rm with recursive + force flags whose target IS root or home
#     (/, /*, ~, ~/*, $HOME, the literal home path) — not paths under them
#   - classic fork bomb
#   - mkfs invocations
#   - dd writing to /dev
#   - force-push to protected branches (main/master/release/prod[uction]),
#     including a bare `git push -f` while one of them is checked out
#   - curl/wget piped (or process-substituted) into a shell interpreter
#   - `git commit` / `gh` chained with other commands in a sandboxed call
#     (sandbox.excludedCommands only matches when every command in the call
#     matches, so a chained commit runs sandboxed and GPG signing fails)
# Exits 2 (blocks tool call) and prints reason on stderr.
#
# Checks run against a sanitized copy of the command with heredoc bodies
# stripped, so dangerous tokens inside commit messages or other `<<EOF` data
# don't false-positive. Quotes are removed but quoted strings are kept, so
# `bash -c "rm -rf /"` is still caught. The rm and git push checks run per
# simple command (split on ; && || | & newlines and subshell delimiters) so
# flags from one command don't leak into another.
#
# Must stay bash 3.2 compatible: macOS /bin/bash is what `env bash` resolves to.

set -euo pipefail

payload="$(cat)"
cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')"
[[ -z "$cmd" ]] && exit 0

# Strip heredoc bodies (<<DELIM ... DELIM, including <<'DELIM', <<"DELIM",
# and <<-DELIM with tab-indented terminators).
scan="$(printf '%s' "$cmd" | perl -0777 -pe '
  s/<<-?\s*([\x27"]?)(\w+)\1[^\n]*\n.*?\n\s*\2\s*(\n|\z)//smg;
' 2>/dev/null)" || scan="$cmd"

block() {
  printf 'Blocked by ~/.claude/hooks/pre-tool-use.sh: %s\n' "$1" >&2
  printf 'Command: %s\n' "$cmd" >&2
  exit 2
}

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

home_lc="$(lower "${HOME%/}")"

# --- Whole-command checks ---------------------------------------------------

if printf '%s' "$scan" | grep -Eq ':[[:space:]]*\(\)[[:space:]]*\{[[:space:]]*:[[:space:]]*\|[[:space:]]*:[[:space:]]*&[[:space:]]*\}[[:space:]]*;[[:space:]]*:'; then
  block "fork bomb pattern detected"
fi

if printf '%s' "$scan" | grep -Eq '(^|[[:space:]])mkfs([[:space:]]|\.)'; then
  block "mkfs invocation"
fi

if printf '%s' "$scan" | grep -Eq 'dd[[:space:]]+if=.*[[:space:]]+of=/dev/'; then
  block "dd writing to a device node"
fi

shells='(sh|bash|zsh|ksh|fish|dash)'
if printf '%s' "$scan" | grep -Eq "(curl|wget)[[:space:]][^|]*\|[[:space:]]*(sudo[[:space:]]+)?${shells}([[:space:]]|\$|-)"; then
  block "curl/wget piped into a shell interpreter"
fi
if printf '%s' "$scan" | grep -Eq "(^|[[:space:]])(${shells}|source|\.)[[:space:]]+<\([[:space:]]*(curl|wget)[[:space:]]"; then
  block "curl/wget process-substituted into a shell interpreter"
fi

# --- Per-command checks -----------------------------------------------------

# True when an rm operand names root or home itself (optionally with a
# trailing / or /*), not something beneath it.
is_root_or_home() {
  local t="$1"
  t="${t%/\*}"
  while [[ "$t" == */ && "$t" != "/" ]]; do t="${t%/}"; done
  # shellcheck disable=SC2016 # matching the literal, unexpanded token
  case "$t" in
  "" | / | "~" | '$HOME') return 0 ;;
  esac
  [[ "$(lower "$t")" == "$home_lc" ]]
}

check_rm() {
  local has_r=0 has_f=0 end_opts=0 tok danger=0
  for tok in "$@"; do
    if [[ $end_opts -eq 0 ]]; then
      case "$tok" in
      --) end_opts=1; continue ;;
      --recursive) has_r=1; continue ;;
      --force) has_f=1; continue ;;
      --*) continue ;;
      -*)
        [[ "$tok" == *[rR]* ]] && has_r=1
        [[ "$tok" == *f* ]] && has_f=1
        continue
        ;;
      esac
    fi
    is_root_or_home "$tok" && danger=1
  done
  if [[ $has_r -eq 1 && $has_f -eq 1 && $danger -eq 1 ]]; then
    block "rm -rf against root or home directory"
  fi
}

is_protected() {
  local ref="${1#+}"
  ref="${ref#refs/heads/}"
  case "$ref" in
  main | master | release | production | prod) return 0 ;;
  esac
  return 1
}

check_push() {
  local force=0 all=0 tok dst positional=0 skip=0 named=0
  local -a refspecs=()
  for tok in "$@"; do
    if [[ $skip -eq 1 ]]; then
      skip=0
      continue
    fi
    case "$tok" in
    -f | --force | --force-with-lease* | --force-if-includes) force=1 ;;
    --all | --mirror) all=1 ;;
    -o | --push-option | --repo | --receive-pack | --exec) skip=1 ;;
    --*) ;;
    -*) [[ "$tok" == *f* ]] && force=1 ;;
    *)
      positional=$((positional + 1))
      # First positional is the remote; the rest are refspecs.
      [[ $positional -ge 2 ]] && refspecs+=("$tok")
      ;;
    esac
  done

  if [[ ${#refspecs[@]} -gt 0 ]]; then
    for tok in "${refspecs[@]}"; do
      named=1
      dst="${tok##*:}"
      [[ "$tok" == +* ]] && is_protected "$dst" && block "force-push (+refspec) to a protected branch"
      [[ "$dst" == HEAD ]] && dst="$(git branch --show-current 2>/dev/null || true)"
      [[ $force -eq 1 ]] && is_protected "$dst" && block "force-push to a protected branch"
    done
  fi

  [[ $force -eq 1 ]] || return 0
  [[ $all -eq 1 ]] && block "force-push with --all/--mirror includes protected branches"
  if [[ $named -eq 0 ]]; then
    dst="$(git branch --show-current 2>/dev/null || true)"
    is_protected "$dst" && block "force-push while a protected branch is checked out"
  fi
  return 0
}

# Quotes removed, ${VAR} → $VAR (so braces can delimit groups), then one
# simple command per line.
segments="$(printf '%s' "$scan" | tr -d "\"'" | perl -pe 's/\$\{(\w+)\}/\$$1/g; s/\|\||&&|[;|&(){}`]|\$\(/\n/g')"

while IFS= read -r seg; do
  [[ -z "${seg//[[:space:]]/}" ]] && continue
  read -ra toks <<<"$seg"
  n=${#toks[@]}
  i=0
  while [[ $i -lt $n ]]; do
    word="${toks[$i]##*/}"
    rest=("${toks[@]:$((i + 1))}")
    if [[ "$word" == rm ]]; then
      [[ ${#rest[@]} -gt 0 ]] && check_rm "${rest[@]}"
    elif [[ "$word" == git ]]; then
      # Skip git's own options (-C dir, -c k=v, --no-pager, ...) to find the subcommand.
      j=$((i + 1))
      while [[ $j -lt $n ]]; do
        case "${toks[$j]}" in
        -C | -c) j=$((j + 2)) ;;
        -*) j=$((j + 1)) ;;
        *) break ;;
        esac
      done
      if [[ $j -lt $n && "${toks[$j]}" == push ]]; then
        args=("${toks[@]:$((j + 1))}")
        if [[ ${#args[@]} -gt 0 ]]; then
          check_push "${args[@]}"
        else
          check_push
        fi
      fi
    fi
    i=$((i + 1))
  done
done <<<"$segments"

# --- Sandbox-excluded commands must run alone -------------------------------
# `git commit *` and `gh *` are in sandbox.excludedCommands, which applies only
# when the whole call matches: `git add x && git commit …`, `cd … && gh …`, a
# pipe, or a $(…) substitution all keep the call sandboxed. Skipped when the
# call already opts out of the sandbox.

sandbox_off="$(printf '%s' "$payload" | jq -r '.tool_input.dangerouslyDisableSandbox // false')"
if [[ "$sandbox_off" != true ]]; then
  # Unlike $segments, blank quoted strings first so `-m "fix(scope): a && b"`
  # stays one command; a quoted $(…) or backtick still counts as a command.
  # Redirections like 2>&1 and &> are not separators.
  strict="$(printf '%s' "$scan" | perl -0777 -ne '
    my ($s, $o) = ($_, "");
    while (length $s) {
      if    ($s =~ s/^\x27[^\x27]*\x27//)          { $o .= "Q" }
      elsif ($s =~ s/^"((?:[^"\\]|\\.)*)"//s)      { $o .= ($1 =~ /\$\(|`/) ? "Q\nSUBST\n" : "Q" }
      elsif ($s =~ s/^\\.//s)                      { $o .= "E" }
      else  { $s =~ s/^(.)//s; $o .= $1 }
    }
    $o =~ s/[0-9]*[<>]&[0-9-]*|&>>?/ R /g;
    $o =~ s/\|\||&&|\|&|[;|&(){}`\n]|\$\(/\n/g;
    print $o;
  ')"

  count=0
  excluded=""
  while IFS= read -r seg; do
    [[ -z "${seg//[[:space:]]/}" ]] && continue
    count=$((count + 1))
    read -ra toks <<<"$seg"
    # Skip shell keywords so `for …; do gh …` still finds `gh`.
    k=0
    while [[ $k -lt ${#toks[@]} ]]; do
      case "${toks[$k]}" in
      do | then | else | elif | if | while | until | time | !) k=$((k + 1)) ;;
      *) break ;;
      esac
    done
    case "${toks[$k]:-}" in
    gh | */gh) excluded="gh" ;;
    git | */git) [[ "${toks[$((k + 1))]:-}" == commit ]] && excluded="git commit" ;;
    esac
  done <<<"$strict"

  if [[ -n "$excluded" && $count -gt 1 ]]; then
    block "\`$excluded\` chained with other commands stays sandboxed (excludedCommands needs the whole call to match), so GPG/gh credentials are unreachable. Run it as its own Bash call: stage or cd in an earlier call, and pass the message with repeated -m flags instead of \$(...)."
  fi
fi

exit 0
