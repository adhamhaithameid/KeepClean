# Atomic Commit Workflow

This repository is set up for frequent, minimal commits.

## One-time setup per clone

```bash
./script/setup_atomic_commits.sh
```

## Fast commit loop

```bash
git status --short
git add -p
git diff --cached
git commit
```

For larger local change sets, generate suggested slices first:

```bash
./script/suggest_commit_slices.sh
```

## Rules of thumb

- One behavior change per commit.
- Keep commits tiny: default guardrail is at most 8 files and 220 changed lines.
- Prefer focused tests/docs in the same commit when they directly validate that change.
- If the staged diff tells two stories, split again with `git add -p`.

## Suggested slice order

1. Models and pure logic
2. Services and side-effects
3. UI wiring
4. Tests
5. Docs/changelog

## Naming convention

Use an imperative summary with optional scope:

```
feat(clean-tab): add lock-state elapsed timer
fix(input-monitoring): avoid false negative on launch
test(app-view-model): cover timer auto-recovery edge case
docs(permissions): clarify setup screenshot note
```

## Bypass for exceptional commits

If a larger commit is genuinely required:

```bash
KEEP_CLEAN_ALLOW_LARGE_COMMIT=1 git commit ...
```

Use this sparingly and return to atomic commits afterward.
