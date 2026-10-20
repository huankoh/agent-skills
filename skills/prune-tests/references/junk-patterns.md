# Junk patterns

Each pattern is a way a test fails the bar in [SKILL.md](../SKILL.md).
A match makes a test a candidate, so check the keep list at the end before marking it `D`.

## Tests that cannot fail for a real bug

- **Self-confirming expected value.** The expected value comes from the code under test, or from the same computation the code performs.
  Take expected values from an independent source, such as a literal worked out by hand, an example from the spec, or a simple reference implementation.
- **No real assertion.** The test runs the code and checks nothing that matters.
  Examples are no assertion at all, "does not throw", "is defined", or "is a string" where the behavior requires a specific result.
- **Self-comparison.** A value compared with itself, a constant compared with its own definition, or a copy compared with its source.
- **Mock echo.** A mock supplies a value and the test asserts that the same value comes back.
  The code under test can mishandle real input and the test still passes.
- **Copied inventory.** A hard-coded copy of a list, table, config, or manifest from the source, so the test only checks that the two copies match.
- **Fabricated output.** Setup hands in the result the code under test was supposed to produce, or the test asserts persistence against a store the code never writes.
- **Someone else's code.** The test proves that a library or framework works, such as the parser parsing or the ORM inserting.

A self-confirming expected value next to an independent one:

```ts
// Recomputes the implementation, so it agrees with any bug in it
const expected = items.reduce((sum, i) => sum + i.price * i.qty, 0);
expect(total(items)).toBe(expected);

// Independent literal
expect(total([{ price: 10, qty: 2 }, { price: 5, qty: 1 }])).toBe(25);
```

## Tests that fail for the wrong reasons

- **Source text check.** The test reads source files as text and asserts on their contents.
  It fails on harmless edits and passes when the behavior is broken.
- **Call shape.** The test asserts that an internal function was called, how often, or in what order, instead of checking the result or the effect.
- **Private internals.** The test reaches a private helper or internal state while a test at the public interface covers the same behavior.
- **Side channel.** The test verifies through a back door, such as querying the database directly, instead of reading back through the interface.

## Redundant tests

- **Duplicate behavior.** The same behavior is checked at several layers, or again at the same layer with another literal.
  Keep one test per behavior at the strongest boundary.
  The real interface with fake external I/O beats a mocked internal collaborator.
- **Glue.** The test covers a pass-through, a one-line mapping, or a handler that parses input and delegates.
  Test what it delegates to instead.
- **Test-only production code.** Exports, flags, parameters, getters, and reset hooks exist only for tests.
  Delete them with their tests and prove the behavior through the real interface.

## Misleading tests

These are usually `F`, because the behavior they name may matter and the bug they hide may be real.

- **Wrong name.** The name promises behavior that the inputs and assertions never exercise.
- **Negative control that passes for the wrong reason.** A "rejects X" test passes because a different check rejects the input, or because the rejection can never happen.
  Run the code with input that only the named check would reject, and see what happens.
- **Capability instead of effect.** The test asserts a flag such as `supportsRetry: true` instead of checking that the retry happens.

## Keep list

Keep a test that matches a pattern above when it protects one of these:

- A promise to outsiders, such as a public API, CLI flags and output, a wire format or protocol, config keys, documented defaults, migrations, storage formats, security and permission checks, platform-specific behavior, promised user-facing text, package and release shape, or observable ordering.
- A regression test for a real past bug, unless a stronger test catches the same bug.
- A rule enforced across the codebase, such as "nothing outside `payments/` imports the payment SDK".
  A source scan that checks a rule everywhere is a lint written as a test, so keep it or replace it with a real lint rule.
  A source scan that looks for the text the author just wrote only repeats the change.
- A fixed value that is a promised contract, such as a documented default.
  Record the contract and the bug that a changed value would cause.

A slow test is not a junk test.
Move it to a slower tier instead.
A test that fails at baseline may be catching a real bug.
Report it and keep it.
