# Personal preferences

How I work. Defaults for any project. Project-level rules override these.

## Principles

- **Clarity first.** Code is read more than written. Optimize for the next reader.
- **Single responsibility.** Each function/module does one thing. Split when a name needs "and".
- **Open/closed, Liskov, interface segregation, dependency inversion.** Apply when seams already exist; don't invent seams speculatively.
- **YAGNI / KISS.** Build for current requirements, not hypothetical ones. Three similar lines beats a premature abstraction.
- **Idiomatic over clever.** Follow the host language's conventions, formatter, and standard library before reaching for patterns from another ecosystem. Match the style already in the repo. Respect the project's formatter / linter / EditorConfig as configured — don't override settings to suit personal preference.
- **Boy Scout rule.** Leave touched code marginally cleaner — but don't bundle drive-by refactors into unrelated changes.

## Style

- Small, single-purpose functions over long ones.
- Explicit types at module/public boundaries; let inference handle locals.
- No dead code, no commented-out blocks. If it's not running, delete it.
- Comments explain *why*, not *what*. Well-named identifiers do the rest.
- **No WIP merges.** If a change requires follow-up, either scope it down to something shippable or open a tracking issue. Don't leave half-finished code in a merged branch.
- **No backwards-compat shims for code that hasn't shipped or has no real consumers.** Don't add compat for hypothetical callers.
- **`TODO` / `FIXME` must name an owner or a removal condition** (e.g. `TODO(gabriel): remove after migration X`). No orphan TODOs.
- **Prefer editing existing files to creating new ones.** Don't create README/docs/example files unless explicitly asked.

## Scope discipline

- Don't expand scope mid-task. Refactors, renames, dependency bumps, and style cleanups stay out of a feature/bug PR unless the user asked for them.
- If a touched file is broken in ways unrelated to the task, flag it — don't silently fix it inline.
- One logical change per branch and per commit.

## Plan mode

- **Enter plan mode** before implementation when the change touches more than two files, includes an irreversible or shared-state step, the user's ask is ambiguous about scope, or the work involves unfamiliar third-party config / API surface. Skip it for single-file edits, trivial bug fixes, and read-only tasks.
- After `ExitPlanMode` is approved, **persist a curated copy** of the plan to `~/.claude/projects/<slug>/plans/<UTC-ISO>.md` per the `plan-mode` skill. The flat `~/.claude/plans/` files the harness may write are not durable — the per-project copy is what SessionStart surfaces on resume.
- Treat the persisted plan's Approach + Files as the agreed scope. Append a `## Status log` entry on resume and on non-trivial state transitions. Move the file into `plans/completed/` when shipped, or set `status: abandoned`.
- Project rules override these defaults. See `~/.claude/skills/plan-mode/SKILL.md`.

## Sources of truth

- **Inside a repo: trust the code, not the docs.** READMEs, ADRs, and inline comments drift; the running source is authoritative. When code and docs disagree, follow the code and either update the stale doc or flag the drift in the PR.
- **Outside a repo: verify before writing.** Before generating config, CLI invocations, plugin schemas, or SDK calls for any unfamiliar tool, library, or API, consult the **current upstream documentation** (WebFetch / WebSearch / official docs MCP). Plugin schemas and flags drift fast; do not rely on training-data recall for version-specific behavior.
- Cite the source (URL or repo path) only for **non-obvious or version-specific** claims, or when the user is about to act on the answer. Don't link-spam every sentence.
- **Memory snapshots can be stale.** Before recommending or acting on a memory entry that names a file, flag, function, or fact, re-read the current code / `git log` and confirm it still holds. Trust live state over recalled state.

## Error handling

- Fail loud locally, recover at system boundaries (user input, external APIs, IPC).
- No swallowed errors. No `catch (e) {}`-style blocks without a stated reason.
- Validate untrusted input at the boundary; trust internal callers.
- Surface the original error context — don't replace it with a generic message.

## Security defaults

- Never commit secrets. Use the project's secret manager / env vars; if none exists, ask before introducing one.
- Treat all external input as hostile until validated. Prefer parameterized queries, structured serializers, allowlists over denylists.
- Apply least privilege to tokens, service accounts, and file permissions.
- Don't disable safety mechanisms (signature verification, hook execution, lint rules) without a written reason.

## Dependency hygiene

- Prefer the standard library and existing project dependencies before adding new ones.
- Justify every new dependency: what it provides, why it's worth the supply-chain and maintenance cost.
- Pin versions in lockfiles. Avoid floating ranges in production manifests.
- Prefer well-maintained, widely-used packages over novel single-maintainer ones.

## Performance discipline

- Measure before optimizing. Profile, don't guess.
- Premature optimization is a style smell — clarity wins until a measurement says otherwise.
- Note the hot path with a comment if you intentionally trade clarity for speed.
- Avoid quadratic blowups, N+1 queries, and unbounded buffers in code that handles untrusted volume.

## Risky / irreversible actions

- **Confirm before destructive or shared-state operations.** Examples: `rm -rf`, dropping tables, deleting branches, killing processes, force-push, mass file rewrites, schema migrations, dependency downgrades, modifying CI/CD pipelines, posting to external services (Slack, email, GitHub comments, PRs).
- Authorization is scope-limited. Approval for one destructive action does not extend to similar actions later.
- When stuck, fix the root cause — don't use destructive shortcuts (`--no-verify`, `git reset --hard`, deleting lockfiles) to bypass safety checks.
- Investigate unfamiliar files, branches, or state before deleting or overwriting — it may be in-progress work.

## Testing

- Run the relevant test/lint/typecheck command for every touched file before declaring a change done. If a project skill (e.g. `test-runner`) codifies the matrix, follow it; otherwise infer from the toolchain.
- Prefer adding a failing test first when fixing a bug, then making it pass. Skip only when the bug is config/infra (no meaningful unit to assert on).
- Manual verification beats "looks right" for UI/CLI work — run the thing.

## Git

- Conventional commits (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `test:`, `perf:`, `build:`, `ci:`).
- **Prefer single-line commits:** `<type>(<scope>): <concise description>`. Include the scope and keep the description tight.
- Subject ≤ 50 chars, imperative mood, no trailing period. Add a body **only when critically necessary** — when the "why" can't be inferred from the diff or subject; wrap at ~72.
- One logical change per commit. Squash noise locally before pushing.
- Never force-push to `main`/`master`. Force-push to feature branches only with `--force-with-lease`.
- Branch names: `kebab-case`, prefixed by type (`feat/`, `fix/`, `chore/`).
- PR titles mirror the commit style.
- **Project commit/PR conventions override these defaults.** If a repo's `CLAUDE.md`, `CONTRIBUTING.md`, or commit history shows a different style (gitmoji, ticket prefixes, custom scopes), follow that.
- **Always include the `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>` trailer when Claude helped write the change** (use the current model's id/version at commit time). `includeCoAuthoredBy: true` stays on globally; a project may not disable it without a written reason in its `CLAUDE.md`.

## Working in any repository

- Read the repo's `CLAUDE.md` and any files under `.claude/` before acting. **Project rules override these defaults.**
- Prefer reading existing patterns over generating new abstractions. Consistency with what's already in the repo wins.
- Verify upstream documentation before writing config for an unfamiliar tool (see *Sources of truth*).

## Session learnings (feedback loop)

- At session end (or when the user invokes `/session-learnings`), scan the conversation for: corrections received, repeated mistakes, validated non-obvious successes, and missing project context.
- Convert each into one of: (a) a memory entry under `~/.claude/projects/<project>/memory/` per the auto-memory system, (b) a one-line rule appended to global `~/.claude/CLAUDE.md`, or (c) a one-line rule appended to project `CLAUDE.md`. Propose; let the user accept.
- The skill at `~/.claude/skills/session-learnings/SKILL.md` defines the full workflow.

## Editor / OS

- Neovim is my primary editor (config under `~/.config/nvim`).
- macOS workstation; tools installed via Homebrew where possible.
