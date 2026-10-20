---
name: coding-standards
description: Interview the user to write or extend the repo's CODING_STANDARDS.md, the rules reviewers check every change against. Use when the user asks to be interviewed about coding standards, to create or update CODING_STANDARDS.md, or to turn a recurring mistake into a standing rule.
---

# Coding standards interview

`CODING_STANDARDS.md` at the repo root holds the rules a reviewer, human or agent, checks every change against.
Reviewers read it at review time, so it stays out of the context of every coding session.
Each rule states what to do, the failure it prevents, and the check that enforces it when one exists.
Start from [assets/CODING_STANDARDS.md](assets/CODING_STANDARDS.md), a general baseline distilled from Matt Pocock's standards and Andrej Karpathy's notes on coding with agents.

Facts are your job, and decisions are the user's.
Look up anything the repo can tell you, and ask the user only for decisions.

## 1. Gather the facts

Read these before asking anything:

- Existing standards and guidance, such as `CODING_STANDARDS.md`, `CONTRIBUTING.md`, `AGENTS.md` or `CLAUDE.md`, and docs on testing or style.
- What tooling already enforces, from lint, format, and type-check config, pre-commit hooks, and CI workflows.
  A rule that a check already enforces needs one line at most.
- The code, for its languages, frameworks, test layout, and the conventions it follows without writing them down.
- The history, from `git log`, for fix commits, reverts, and repeated review feedback.
  Each one is a lesson the repo has already paid for.

When you can run sub-agents, gather these in parallel.

Done when you can name the repo's stack, its existing rules and checks, and the conventions and lessons the code and history show.

## 2. Interview in rounds

Turn the baseline, the conventions, and the lessons into questions.
Skip baseline rules that cannot apply, such as browser rules in a CLI.
Make every question concrete by citing the file, convention, or commit that raised it.

Ask in rounds.
A round holds every question whose answer does not depend on another open question.
Number each question, give your recommended answer, and word it so that "yes" accepts the recommendation.

> **Q1. Exhaustive branches.** `src/orders.ts` switches on `OrderStatus` in four places, and two of them end in a `default` branch.
> Should every branch over a closed set name each case with no `default`, so a new status breaks the build until each site handles it?
> Recommended: yes, enforced by the linter's switch-exhaustiveness rule.

Wait for the answers, then ask the next round.

Done when no question is open and the user confirms the list of agreed rules.

## 3. Choose how each rule is enforced

- A mechanical rule, such as a banned API, an import boundary, a file location, or a fixed pattern, gets a check, such as a lint rule, a type, a CI script, or a test.
  Write the check or propose it, and give the rule one line in the file that names the check.
- A judgment rule, such as one about design, naming, test value, or consistency across files, gets written out in full.

Done when every agreed rule is marked mechanical or judgment, and every mechanical rule names its check.

## 4. Write the file

Write or update `CODING_STANDARDS.md` at the repo root, keeping the baseline's layout:

- Group rules under topic headings.
- Give each rule a heading that states the rule, followed by one to three sentences on the failure it prevents.
- Add a short bad and good example only when the rule is unclear without one.
- End a mechanical rule with "Enforced by" and the check.
- Keep the essence of each rule in the file, and move long reasoning into a linked doc.

Show the user the diff, and commit only when they ask.
When the repo's `AGENTS.md` or `CLAUDE.md` does not mention the file, propose one line telling reviewers to check changes against `CODING_STANDARDS.md`.

Done when the file contains every agreed rule and the user has seen the diff.

## Adding one rule

When the user names a single mistake to turn into a rule, skip the full interview.
Ask one round that settles what the rule covers, what it excludes, and whether a check can enforce it.
Then write the rule as in steps 3 and 4.
