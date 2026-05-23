---
name: test-runner
description: Validate this dotfiles repo after a change. Runs make check, brew bundle check, bash -n on hook scripts, and jq empty on tracked JSON. Triggers on phrases like "run tests", "validate", "check the repo", "did anything break", "run make check".
allowed-tools: Bash(make check) Bash(brew bundle check *) Bash(bash -n *) Bash(jq empty *)
---

# test-runner

This repo has no traditional test suite. Validation is this matrix, in order:

| Step | Command                              | Stops on failure? |
| ---- | ------------------------------------ | ----------------- |
| 1    | `make check`                         | yes               |
| 2    | `brew bundle check --file=Brewfile`  | yes               |
| 3    | `bash -n .claude/hooks/*.sh`         | yes               |
| 4    | `jq empty .claude/settings.json`     | yes               |

## Process

1. Run each step in order. Capture stderr.
2. Stop at the first non-zero exit. Do not continue.
3. On success, print the matrix with `ok` per row.
4. On failure, print the exact failing command, trimmed stderr, the suspect file, and a one-sentence fix suggestion.

## Output

Success:

```
✅ All checks passed.

- make check: ok
- brew bundle check: ok
- bash -n .claude/hooks/*.sh: ok
- jq empty .claude/settings.json: ok
```

Failure:

```
❌ <one-line summary>

$ <exact failing command>
<exact stderr / stdout, trimmed>

Suspect file: path/to/file:line
Likely cause: <one sentence>
Suggested fix: <one sentence>
```

Do not attempt fixes. Diagnose and return.
