---
name: git-edit
description: Workflow for editing the git package (git/.gitconfig) and its delta/aliases/credential integrations. Enforces fetching upstream docs before writing config keys, validating with `git config --file --list`, and keeping identity/signing/secrets in ~/.gitconfig.local. Trigger when the user asks to edit, add, remove, audit, or debug anything in git/.gitconfig, ~/.gitconfig.local, a git alias, delta styling, credential helper, or signing setup.
---

# git-edit

Goal: every change to `git/.gitconfig` is grounded in current upstream docs, parses cleanly via `git config --file`, and keeps identity, signing keys, and per-client `includeIf` blocks in `~/.gitconfig.local` rather than the tracked file.

## When to invoke

- Any Edit/Write touching `git/.gitconfig`
- Adding/removing an alias under `[alias]`
- Tweaking `[delta]` styling, palette, or features
- Changing pager, editor, credential helper, autocorrect, or any global default
- Wiring a new `[include]` / `[includeIf "..."]` block
- Adding signing config (`commit.gpgSign`, `gpg.format`, `user.signingKey`)
- Debugging "wrong author email per repo", "delta not running", "alias not found", "credential prompt loops"

## Workflow

1. **Identify which file owns the change.** Identity (`user.name`, `user.email`, `user.signingKey`), signing toggles (`commit.gpgSign`), work-vs-personal `includeIf` blocks, GitHub Enterprise hosts, and any token → `~/.gitconfig.local`. Universal defaults (pager, editor, delta styling, aliases, pull/push/branch/rebase behavior) → tracked `git/.gitconfig`. If unsure, see the "What lives where" section.
2. **Fetch upstream docs before writing keys.** Use `WebFetch` against the canonical URL in the table below. `git-config(1)` adds and deprecates keys over releases (e.g. `pull.rebase` semantics, `init.defaultBranch`, `safe.directory`); delta's flag names shift between minor versions. Do not paste from memory.
3. **Check for duplication.** Grep `git/.gitconfig` for an existing key before adding — last-write-wins inside one file, but a value duplicated across `~/.gitconfig.local` and the tracked file is confusing during debug. Prefer setting once in the right file.
4. **Don't shadow the include.** `[include] path = ~/.gitconfig.local` is sourced **at parse position** — anything below `[include]` in the tracked file overrides values set in `.gitconfig.local`. Keep the include near the top (its current position) so the local file can override tracked defaults if needed.
5. **Validate by parsing.** Run `git config --file /Users/gabrieldacunha/Developer/dotfiles/git/.gitconfig --list` after edits. Non-zero exit with a "bad config" message means the INI syntax broke — fix before reporting done. Then run `git config --get <key>` against any key you added to confirm the value resolves as expected.
6. **If a new external command is introduced** (a new pager, signing program, credential helper, or hook runner), add the binary to `Brewfile`. The repo's contract is that `make install` brings up a fresh machine; a config line referencing an uninstalled binary breaks that.
7. **Reload guidance.** Git re-reads config on every invocation — no reload needed. Editor/pager changes take effect on the next `git` command. `includeIf` is evaluated per-repo on each command — `cd` into the affected repo and `git config user.email` to confirm.
8. **After editing**, mention the doc URL(s) consulted in your end-of-turn summary.

## Secrets and identity — never commit

The tracked `git/.gitconfig` **must not contain**: `user.name`, `user.email`, `user.signingKey`, GPG/SSH key fingerprints, work-specific hostnames, employer-identifying repo URLs, or any token. These live in `~/.gitconfig.local`, which the tracked file already `[include]`s at the top. `.gitconfig.local` is gitignored (see `.gitignore`) and outside the stow tree.

If the user asks you to "set my email to X", write `[user] email = X` to `~/.gitconfig.local` (create the file if missing) — never to `git/.gitconfig`. Same for `commit.gpgSign = true` and `user.signingKey = ...`: those are personal and may differ per machine.

If you find an apparent identity or secret already in a tracked file, flag it and offer to migrate it to `~/.gitconfig.local` rather than silently leaving it.

## What lives where

| Setting | Tracked `git/.gitconfig` | `~/.gitconfig.local` |
|---------|--------------------------|----------------------|
| `user.name`, `user.email` |  | ✓ |
| `user.signingKey`, `commit.gpgSign`, `gpg.format` |  | ✓ |
| `[includeIf "gitdir:~/work/"]` work overrides |  | ✓ |
| GHE host alias, work git URL rewrites |  | ✓ |
| `pull.rebase`, `fetch.prune`, `push.default` | ✓ |  |
| `core.editor`, `core.pager`, `interactive.diffFilter` | ✓ |  |
| `[delta]` styling | ✓ |  |
| `[alias]` shortcuts | ✓ |  |
| `credential.helper = osxkeychain` | ✓ (macOS-only repo, fine here) |  |

## Canonical doc URLs

| Topic | Docs |
|-------|------|
| `git config` reference (every key, scope, since-version) | https://git-scm.com/docs/git-config |
| Conditional includes (`includeIf`) | https://git-scm.com/docs/git-config#_conditional_includes |
| `pull`, `push`, `fetch`, `rebase`, `branch` defaults | https://git-scm.com/docs/git-config — sections under each verb |
| `commit.gpgSign`, `gpg.format`, signing setup | https://git-scm.com/docs/git-config#Documentation/git-config.txt-commitgpgSign — https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work |
| Credential helpers (`osxkeychain`, `manager`, `cache`) | https://git-scm.com/docs/gitcredentials — https://git-scm.com/doc/credential-helpers |
| Aliases | https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases |
| delta (pager, themes, flags) | https://dandavison.github.io/delta/ — config keys: https://dandavison.github.io/delta/configuration.html |
| delta supported syntax themes | https://dandavison.github.io/delta/using-delta-with-bat.html (delta reads bat's themes) |
| gh (separate from git config, but related) | https://cli.github.com/manual/ |

For features not listed: `git help config` opens the man page locally; section anchors on git-scm.com mirror that structure.

## Section ordering and `[include]` semantics

`git/.gitconfig` is parsed top-to-bottom. `[include]` and `[includeIf]` lines are evaluated **in place** — keys defined later in the same file override included values. Current layout:

```
[include] path = ~/.gitconfig.local   ← runs first; user.email etc. set here
[pull] ...                            ← tracked defaults below; can override the local file
[fetch] ...
...
```

Implications:
- If the user wants `~/.gitconfig.local` to win over a tracked default (e.g. set `pull.rebase = false` for a single machine), the include needs to move to the **bottom**, OR the local file needs an explicit later `[include]` self-reference. Don't reorder casually — the current setup intentionally lets tracked defaults override identity-side overrides for non-identity keys.
- Per-repo `~/.git/config` always wins over global. `git config --local` writes there; `git config --global` writes to `~/.gitconfig` (the symlink into this repo). Be explicit about scope when guiding the user.

## Aliases — conventions in this repo

Existing aliases are short (`s`, `co`, `br`, `ci`, `st`) plus a few opinionated ones (`wip`, `undo`, `amend`, `cleanup`, `logs`). When adding:

1. Keep one-letter aliases reserved for very high-frequency commands. Use two-or-more letters otherwise.
2. Shell aliases (prefixed with `!`) run in `/bin/sh` from the repo root. Multi-line shells use `"!..."` with `\` continuations — see `cleanup` for the canonical pattern. Quote carefully; the value is a single string.
3. Destructive aliases (anything that calls `reset --hard`, `branch -D`, `clean -fd`, `push --force`) require a written safety rationale or interactive confirm. The existing `cleanup` only deletes **merged** branches and skips `main`/`develop` — preserve those guards.
4. Don't shadow built-in subcommands. `git checkout` exists; `git co` doesn't — that's why `co` is safe. Test with `git <alias> --help` before adding (alias names show as "command not found" from help if free).

## Delta — gotchas

- `syntax-theme` must match a bat-known theme name exactly (case-sensitive). Current value: `Catppuccin Mocha`. If you change it, confirm with `bat --list-themes | grep -i <name>`.
- `blame-palette` is a space-separated list of hex colors — five colors here, cycling per author. More colors = more author distinction; fewer = palette repeats sooner.
- `line-numbers = true` and `navigate = true` change the diff UI shape. Don't toggle without telling the user — muscle memory disrupts.
- `delta` itself must be installed (`brew "git-delta"` in Brewfile). If you reference a delta feature added after the installed version, `git diff` falls back to printing raw or errors — check `delta --version` against the docs' "since" notes.
- `interactive.diffFilter = delta --color-only` is **required** for `git add -p` to render via delta — don't remove without removing `[delta]` block too.

## Credential helper

- `credential.helper = osxkeychain` is macOS-only. The repo is macOS-only, so it lives in the tracked file. If multi-OS support is ever added, move this to `~/.gitconfig.local` and document per-OS values.
- For GitHub HTTPS pushes, `gh auth login` writes credentials osxkeychain reads. SSH pushes don't use credential helper at all.
- If the user reports "git keeps prompting for password" on HTTPS: confirm `osxkeychain` is the active helper with `git config --get-all credential.helper` (multiple values stack — only the *last* one wins for storage).

## Signing (lives in `~/.gitconfig.local`)

The tracked file does not set `commit.gpgSign`, `tag.gpgSign`, `gpg.format`, or `user.signingKey`. These are personal. Brewfile installs `gnupg` and `pinentry-mac` so the toolchain is present on every machine; the user enables it per-machine in `.gitconfig.local`:

```ini
[user]
    signingKey = <fingerprint-or-SSH-pubkey-path>
[commit]
    gpgSign = true
[tag]
    gpgSign = true
[gpg]
    format = openpgp   # or "ssh" for SSH signing
```

If the user wants SSH signing: `gpg.format = ssh`, `user.signingKey = ~/.ssh/id_ed25519.pub` (the *public* key), and `gpg.ssh.allowedSignersFile` if verifying others' signatures.

## Validation commands

```bash
git config --file /Users/gabrieldacunha/Developer/dotfiles/git/.gitconfig --list     # parse + dump tracked file
git config --list --show-origin --show-scope                                          # all effective config + where it came from
git config --get <key>                                                                # resolve a single key against current repo
git config --get-all <key>                                                            # all stacked values (helpful for credential.helper)
git config --get-regexp '^delta\.'                                                    # dump a section
git -C ~/some/repo config user.email                                                  # verify includeIf resolved correctly
```

For "alias doesn't work": `git config --get alias.<name>` to confirm it's defined, then run with `GIT_TRACE=1 git <alias>` to see what command it expands to.

For "wrong email on commit": `git -C <repo> config --show-origin user.email` shows which file set it — usually `~/.gitconfig.local` via `includeIf`.

## Things easy to get wrong

- **Editing the symlinked file vs source.** `~/.gitconfig` is a symlink into this repo via stow. Edit `git/.gitconfig` here, not the symlinked target — both point to the same inode but only one is in the working tree for `git diff`.
- **TAB vs spaces in INI.** Git accepts both, but the existing file uses tabs for indentation under each section. Match it — mixed indentation passes parsing but looks noisy in diffs.
- **Quoting alias values.** Shell aliases need `"!..."` (double-quoted). Embedded single quotes need to be escaped via shell, not git — `\'` works inside the double-quoted value. The existing `cleanup` alias is the reference.
- **`autoSetupRemote = true` + new branches.** This sets the upstream automatically on first push — convenient, but means typo'd branch names get pushed to a typo'd remote branch. Don't disable without warning the user.
- **`autoStash = true` on rebase.** Convenient, but a failed rebase leaves the stash applied automatically only on success; on conflict, the stash entry persists. Run `git stash list` if a rebase aborts unexpectedly.
- **Deleting an alias the user uses in shell aliases too.** zsh's oh-my-zsh `git` plugin defines `gst`, `gco`, etc. — those don't depend on git aliases. But the user may have personal shell aliases in `~/.zshrc.local` that wrap git aliases. Grep there before removing.
- **`includeIf "gitdir:..."` path matching is exact and ends with `/`.** `gitdir:~/work/` matches repos under `~/work/`. `gitdir:~/work` (no trailing slash) does NOT match a subdirectory. Trailing-slash matters.
- **`safe.directory` warnings on stowed repos.** If git ever flags the dotfiles repo as "unsafe" (owner mismatch in a shared/migrated environment), the fix is `git config --global --add safe.directory /Users/gabrieldacunha/Developer/dotfiles` — that writes to `~/.gitconfig` (the tracked file via stow). Add it to `~/.gitconfig.local` instead so per-machine paths don't leak into the repo.
- **`core.autocrlf = input` on macOS** is the right choice (commit LF, check out as-is). Don't change to `true` (would mangle line endings on checkout).

## Stow note

`git/` is a stow package — `git/.gitconfig` symlinks to `~/.gitconfig`. Git re-reads config on every command, so edits to the existing file take effect immediately (no restow). If you add a new tracked file at the package root (e.g. `git/.gitattributes`, `git/.gitignore_global` referenced via `core.excludesFile`), run `make stow PKG=git` to create the symlink.

The per-machine override file `~/.gitconfig.local` lives directly in `$HOME` and is **not** stow-managed — it exists outside this repo and is gitignored.
