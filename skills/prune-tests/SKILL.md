---
name: prune-tests
description: Prune a test suite. Finds tests that cannot catch a real bug (tautological, implementation-coupled, duplicated, or misleading), proves what still covers each behavior, and deletes the rest in reviewable batches. Use when asked to prune, clean up, audit, or slim down tests, or to remove tautological, redundant, or low-value tests.
---

# Prune tests

A test earns its place when it can fail for a plausible bug that a user or caller would see.
When you cannot name that bug, or a stronger test already catches it, the test is a candidate for removal.
The goal is a suite where every test protects something.
A lower test count is a side effect, never the target.

## 1. Learn the repo's rules and commands

Read the repo's standards first, such as `CODING_STANDARDS.md`, `CONTRIBUTING.md`, `AGENTS.md` or `CLAUDE.md`, and any testing docs.
Where they disagree with this skill, follow the repo.
Find the commands in the repo itself (package scripts, Makefile, CI workflows) for the full suite, a single test file, lint, type checks, and a dead-code check if one exists.
Find what the project promises outsiders in its README, public entry points, CLI flags and output, and documented config and defaults.

Done when you can run one test file and the whole suite, and you can list the project's public promises.

## 2. Record a baseline

Run the whole suite and record which test files pass and which fail.
A test that fails before you change anything may be catching a real bug.
Keep those in a separate list and leave them in place.

Done when every test file in scope has a recorded result.

## 3. Build the ledger

This step is read-only.
Prune a small suite in one pass.
For a large suite, take one area of production code at a time and follow [references/campaign.md](references/campaign.md).
Read every test in scope in full, including parameter tables and shared setup, then the production code it exercises and the code that calls it.
Judge each test by its assertions, not its name.
Check each test against [references/junk-patterns.md](references/junk-patterns.md), including its keep list.

Give every test one mark:

- `R` keeps the test, naming the bug it catches.
- `F` keeps the behavior and fixes the test, for when the behavior matters but the assertions are vacuous, misleading, or tied to internals.
- `C` merges its assertion into a named stronger test, then deletes it.
- `D` deletes it, naming the test that still catches the bug or explaining why there is no behavior to protect.

When the behavior matters and no other test catches its bug, mark the test `F` and plan a rewrite that checks the behavior.
When that check needs something the repo lacks, such as a browser, mark the test `D` and report the behavior as untested, because a test that only looks like coverage hides the gap.

For every `F`, `C`, and `D`, record:

1. The bug the test claims to catch, and whether its assertions can catch it.
2. The callers of the covered code outside tests.
   Code that only tests call is dead, so it goes with its tests.
3. The test that will catch the bug afterwards, by file and name, or why no behavior needs protecting.
4. Why the test exists, from `git log` on its file, and what deleting it unlocks, such as a test-only export.
5. The command that checks the change.

A candidate without this evidence stays.
Prefer a few confident deletions to many doubtful ones.

Write the ledger to `test-ledger.md` at the repo root as a table with the columns `Test`, `Mark`, `Bug it catches`, `Evidence`, and `Keeper afterwards`.
Add `test-ledger.md` to `.git/info/exclude` so it never gets committed.
Show the user the ledger and the baseline failures.
Start editing after the user approves, or right away if they already told you to go ahead.

Done when every test in scope has a mark and an evidence line.

## 4. Edit in batches

Group the edits by the production code they cover, not by test file.
Work through each batch in this order:

1. Merge each `C` assertion into its keeper, and rewrite each `F` test to check the behavior through the public interface.
   A rewritten test meets the same bar as a kept one, with its expected value from an independent source.
   When a rewritten test fails because the product breaks a promised behavior, keep it as an expected failure (the runner's `todo`, `xfail`, or equivalent) with the reason, and report the bug.
   When nothing promises the behavior, delete the misleading test and report the open question instead.
2. Prove every behavior that moves to another test, meaning each `C`, each `F`, and each `D` that names a remaining test.
   Break the production code the way the bug would, run the keeper, and confirm it fails on an assertion about that behavior rather than on an unrelated error.
   Restore the code with `git checkout -- <file>` and confirm that `git diff` shows no production change.
   When the keeper still passes with the bug in place, keep the original test.
3. Delete the `D` and `C` tests, the test-only production code they unlock (exports, flags, parameters, and hooks that only tests use), and helpers or fixtures left without users.
4. Run the batch's test files, then the whole suite, lint, type checks, and the dead-code check.
   A new failure means the batch removed something still in use, so fix it before starting the next batch.

When you are committing, make one commit per batch.

Done when the suite fails only where the baseline already failed, and every moved behavior has a caught mutation.

## 5. Report

Tell the user:

- The tests deleted, merged, and rewritten, grouped by pattern.
- For each deletion, the test that still catches its bug and the mutation that proved it.
- The test-only production code removed.
- The baseline failures and any other likely product bugs, with how to reproduce each one.
  Fix them only when the user asks.
- Line counts before and after, with test code and production code counted separately.
- Patterns that kept recurring, written as proposed rules for `CODING_STANDARDS.md`.
  The `coding-standards` skill can add them.
