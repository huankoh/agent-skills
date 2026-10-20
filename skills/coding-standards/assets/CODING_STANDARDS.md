# Coding standards

These are the rules a reviewer, human or agent, checks every change against.
They apply to new and changed code.
Existing code that breaks a rule may stay until someone changes it, and the count of such places only goes down.
When a linter, type checker, or CI script can enforce a rule, the check enforces it and this file names the check.
The other rules are judgment calls, so each one says which failure it prevents.

## Changes

### Every changed line serves the task

A change does what it set out to do, with no accidental side effects.
Put unrelated fixes in their own commits and say what they fix.
Leave code and comments you do not understand as they are, and ask about them.

### Delete what the change makes unused

When a change leaves a function, parameter, flag, import, file, or test without users, the same change deletes it.

### Name the assumptions

When the spec was silent and the code had to choose, the pull request description says which choice it made and why.

## Simplicity

### Write the least code that does the job

If 1,000 lines could be 100, write the 100.
Prefer deleting code to adding it.

### Build only what is needed now

Add configuration options, extension points, factories, and flags when a real second use arrives.
A seam with one implementation is a guess, and a seam with two is real.

### Start from the obviously correct version

Write the plain version that is very likely correct first.
Optimize it only when measurements show it is too slow, and keep the plain version as the reference that tests check the fast one against.

### Keep functions small enough to read

Split a function that branches too much into named helpers, or move its decisions into a table or a reducer.
Enforced by the linter's complexity rule, with a limit such as 15.
Fix the code instead of disabling the rule.

### Names say what things do

A function, variable, or type name tells the reader what it does or holds.
If no honest name comes to mind, the design is unclear, so fix the design.

## Modules and interfaces

### Small interface, deep implementation

A module exposes few functions with simple parameters and hides the complex work behind them.
A module that only passes calls through adds a layer and no value, so callers call the real target directly.

### Self-contained units

Write functions and modules that someone could understand and copy out without reading the rest of the codebase or importing anything new.
Every dependency is one more file a reader must open.

### Accept dependencies and return results

Pass external services in instead of constructing them inside.
Return values instead of mutating shared state.
Code built this way can be tested without mocking its own internals.

### Derive state instead of copying it

Compute a value from its source of truth instead of keeping a second copy in sync.

### Make parameters required by default

An optional parameter that a caller forgets silently takes its default.
Make a parameter optional only when omitting it is safe, and update the callers instead of keeping a compatibility default.

### One helper per shared job

When many places do the same job, such as formatting a duration, showing an error, or building a URL, one helper does it and every place calls that helper.
A check that rejects hand-rolled copies keeps it that way.

### Code smells are flags

Reviewers flag Fowler's code smells as possible problems, never as hard violations: Mysterious Name, Duplicated Code, Feature Envy, Data Clumps, Primitive Obsession, Repeated Switches, Shotgun Surgery, Divergent Change, Speculative Generality, Message Chains, Middle Man, and Refused Bequest.

## Types and data

### Every escape from the type checker is a leak

An `any`, an unchecked cast, or a suppressed type error turns off checking for everything that flows through it.
Write the type you mean, and use `unknown` with narrowing when the type is truly unknown.
At an untyped third-party boundary, convert once into a named type and keep the escape hatch out of exported signatures.

### Check inputs where they enter

Read every environment variable and config value at startup, so a missing one stops the program before any work begins, and name the missing value in the error.
Validate data from users, files, and networks where it enters, and pass typed values inward.

### Link records by stable IDs

Join and look up records by IDs that never change, never by emails, names, or other values people can edit.
A payment matched to a user by email breaks when the payment email differs from the login email.

### Handle every case of a closed set

A branch over an enum or a union names every case, with no catch-all default, so a new case breaks the build until each branch decides what to do.
Enforced by the type checker or the linter's exhaustiveness rule.

## Errors

### Fail loudly

Catch only the errors you expect and can handle, and log anything you deliberately drop.
When code can be wrong without crashing, add an assertion or a check that makes the failure visible.

### Throw error objects

Throw an error object, never a string or a plain value, so stack traces and error-type checks work.

### Await or handle every async operation

A promise that nobody awaits loses its failure.
Await it, handle its error where it starts, or mark it as deliberately detached with a comment saying why.
Enforced by the linter's floating-promise rule where the language has one.

## Testing

### Every test can fail for a real bug

Every test must be able to fail for a plausible real bug a user or caller would see; if you can't name the bug, don't write it.

### Test behavior through the public interface

Tests call the code the way its callers do and check what those callers see.
A refactor that keeps behavior the same keeps every test passing.

### Take expected values from an independent source

Use a literal worked out by hand, an example from the spec, or a simple reference implementation.
An expected value computed the way the code computes it agrees with every bug in that code.

### Mock only at system boundaries

Mock external services, time, and randomness, plus the file system or a database when a real one is impractical.
Use your own modules for real.
If code is hard to test that way, change its design.

### One test per behavior, at the strongest boundary

Test each behavior once, at the level where callers meet it, instead of again in the layers above and below.
Prefer the real interface with fake external I/O over a mocked internal collaborator.

### A regression test fails before the fix

Every bug fix comes with a test that fails without the fix and passes with it.

### Tests are deterministic

Inject clocks and random sources, fix random seeds, and wait on produced state instead of sleeping.
A flaky test is a bug, so fix its cause instead of adding retries.

### Some things are not worth a test

- Checks that cannot fail, such as recomputed expected values, mocks that return the value the test then asserts, constants compared with themselves, and copied lists or config.
- Implementation details, such as call counts, call order, private helpers, internal state, and the text of source files.
- Glue, such as a pass-through or a one-line mapping.
  Test what it delegates to.
- Someone else's code, such as the framework rendering or the library parsing.

### UI logic lives outside components

Put UI logic in plain functions or reducers and test those directly.
Test components only for wiring and for behavior that needs a real browser, such as focus, keyboard handling, and layout, and assert what a user sees.

## Tools for people and agents

### Every manual step can be scripted

Anything a person can do through a prompt, a form, or a dashboard, a script can do through a flag, a CLI, or an API.
When there is no terminal and a needed flag is missing, fail fast and name the flag.

## Sources

- Matt Pocock's standards in [course-video-manager](https://github.com/mattpocock/course-video-manager/blob/main/CODING_STANDARDS.md) and [its testing standards](https://github.com/mattpocock/course-video-manager/blob/main/docs/TESTING_STANDARDS.md), [sandcastle](https://github.com/mattpocock/sandcastle/blob/main/.sandcastle/CODING_STANDARDS.md), and his [tdd](https://github.com/mattpocock/skills/blob/main/skills/engineering/tdd/SKILL.md), [codebase-design](https://github.com/mattpocock/skills/blob/main/skills/engineering/codebase-design/SKILL.md), and [code-review](https://github.com/mattpocock/skills/blob/main/skills/engineering/code-review/SKILL.md) skills.
- Andrej Karpathy's [notes on coding with agents](https://x.com/karpathy/status/2015883857489522876), [Sequoia Ascent 2026 summary](https://karpathy.bearblog.dev/sequoia-ascent-2026/), [bacterial code](https://x.com/karpathy/status/1941616674094170287), [nanochat](https://github.com/karpathy/nanochat), and [A Recipe for Training Neural Networks](https://karpathy.github.io/2019/04/25/recipe/).
- openclaw's [test-audit skill](https://github.com/openclaw/openclaw/blob/main/.agents/skills/test-audit/SKILL.md).
