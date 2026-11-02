# Test pruning and coding standards skills

Two agent skills, a baseline `CODING_STANDARDS.md`, and an installer.
The skills use the open Agent Skills format, which is a folder holding a `SKILL.md`, so any agent that loads skills can run them.
An agent without skill support can follow a `SKILL.md` that you paste into the chat or point it at.

| Path | What it does |
| --- | --- |
| `skills/prune-tests/` | Finds tests that cannot catch a real bug, proves what still covers each behavior, and deletes the rest in reviewable batches. Adapted for any repo from openclaw's `test-audit` skill. |
| `skills/coding-standards/` | Interviews you to write or extend a repo's `CODING_STANDARDS.md`, and runs only when you ask for it. |
| `skills/coding-standards/assets/CODING_STANDARDS.md` | The baseline rules, distilled from Matt Pocock and Andrej Karpathy. Copy it into a repo root as it is, or let the interview tailor it. |
| `install.sh` | Makes `~/.agents/skills/` the one skill folder that every agent on the machine reads. |
| `checks/test_install.sh` | Runs `install.sh` in throwaway home folders and checks each case it must handle. Run it after changing the installer. |

## Install on a machine

Keep this folder in a git repo, so every machine runs the same copy.
On each machine, clone the repo and run the installer:

```sh
git clone <your-repo-url> ~/code/agent-skills
~/code/agent-skills/install.sh
```

The installer makes `~/.agents/skills/` the one folder for every skill on the machine, this repo's and your own.
It links this repo's skills into `~/.agents/skills/`, and the links point back into the clone, so `git pull` updates every agent at once.
Codex, Cursor, Muse Code, OpenCode, and Pi read `~/.agents/skills/` themselves.
Claude Code reads only `~/.claude/skills/`, so the installer gives it a link to every skill in `~/.agents/skills/`.
Grok Build gets the same links in `~/.grok/skills/` when it is installed.
Antigravity reads `~/.gemini/config/skills/`, so the installer makes that folder a link to `~/.agents/skills/`.

To add a skill of your own, put its folder in `~/.agents/skills/` and run the installer again, so Claude Code gets its link.
Run `install.sh --check` to see what is out of date without changing anything, and `install.sh --remove` to take the links out.
The installer never replaces a file, folder, or link it did not make, and reports it instead.
A broken link to another clone's `skills/<name>` folder counts as its own, so moving the clone and rerunning the installer repoints it.
A link you made yourself that already reaches the same skill is left as it is.
An agent reads the folders of the machine it runs on, so a T3 thread running on another machine needs the installer run there too.

Keep a skill out of `~/.agents/skills/` when it only works in one agent.
For example, a Codex copy of a Claude Code command belongs in `~/.codex/skills/`, because in `~/.claude/skills/` it would replace Claude Code's own command of the same name.

| Agent | Reads user skills from | Checked |
| --- | --- | --- |
| Claude Code | `~/.claude/skills/` only | `claude -p` startup list showed a probe linked there and not one in `~/.agents/skills/` |
| Codex | `~/.agents/skills/` and `~/.codex/skills/` | `codex app-server` `skills/list` showed the probes |
| Cursor | `~/.agents/skills/`, `~/.claude/skills/`, and `~/.codex/skills/`, listing each name once | A Cursor agent in T3 listed each probe once |
| OpenCode | `~/.agents/skills/` and `~/.claude/skills/`, listing each name once | `opencode run` listed each probe once |
| Muse Code | `~/.agents/skills/`, `~/.claude/skills/`, and `~/.codex/skills/`, listing each name once | `muse skills list` showed each probe once |
| Pi | `~/.agents/skills/` | The `get_commands` RPC listed the probes |
| Grok Build | `~/.grok/skills/` | Not installed here, so not checked |
| Antigravity | `~/.gemini/config/skills/` | T3's Antigravity driver and Google's docs name this folder |

The checks ran on macOS on 2026-10-22.
Each probe was a skill in `~/.agents/skills/`, one of them also linked into `~/.claude/skills/`, and both were removed afterwards.

## Give a repo its standards

Copy `skills/coding-standards/assets/CODING_STANDARDS.md` to the repo root, or run the interview inside the repo.
Then add one line to the repo's `AGENTS.md` so every reviewer finds the file:

```md
Reviewers check every change against [CODING_STANDARDS.md](CODING_STANDARDS.md).
```

Codex, Cursor, OpenCode, and Muse Code read `AGENTS.md`.
Claude Code reads `CLAUDE.md`, so make `CLAUDE.md` a symlink to `AGENTS.md` or a file containing `@AGENTS.md`.
Keep the standards out of `AGENTS.md` itself, because that file loads into every session and the standards matter at review time.

## Use

- Ask "prune the tests in this repo" or run `/prune-tests` (`$prune-tests` in Codex).
  It builds a read-only ledger first and waits for your approval before deleting anything.
  Say "go ahead without checking with me" to skip the approval.
- Ask "interview me for coding standards" or run `/coding-standards`.
  It asks numbered rounds of questions, each with a recommended answer you can accept with "yes".
- Ask "add a coding standard that ..." to turn one recurring mistake into one rule.

Matt Pocock's `/code-review` skill reads `CODING_STANDARDS.md` on its own.
Point any other reviewer at the file.

## Where the baseline rules come from

Most rules restate Matt or Karpathy in imperative form.
Where a sentence came from somewhere else, or was added here, the table says so.
"Community Karpathy file" means the [Karpathy-inspired CLAUDE.md](https://github.com/multica-ai/andrej-karpathy-skills/blob/main/CLAUDE.md), which is a community distillation and not Karpathy's own writing.
The Sequoia Ascent 2026 quotes come from the summary and cleaned-up transcript on Karpathy's blog, which the post says were AI-generated from the talk.

| Rule | Source |
| --- | --- |
| The opening paragraph | Matt, [course-video-manager standards](https://github.com/mattpocock/course-video-manager/blob/main/CODING_STANDARDS.md): existing violations sit in "a shrink-only allowlist", and rules end with "Enforced by". Matt, [retro](https://github.com/mattpocock/skills/blob/main/skills/engineering/retro/SKILL.md): mechanical violations get a check, and `CODING_STANDARDS.md` is for "genuine judgement calls". |
| Every changed line serves the task | Karpathy, [January 2026 notes](https://x.com/karpathy/status/2015883857489522876): agents "change/remove comments and code they don't like or don't sufficiently understand as side effects". The heading follows the community Karpathy file: "Every changed line should trace directly to the user's request". The sentence about putting unrelated fixes in their own commits was added so that the rule fits Huan's CLAUDE.md instruction to fix what you see. |
| Delete what the change makes unused | Karpathy, January 2026 notes: "they don't clean up dead code after themselves". The community Karpathy file: "Remove imports/variables/functions that YOUR changes made unused". |
| Name the assumptions | Karpathy, January 2026 notes: "the models make wrong assumptions on your behalf and just run along with them without checking". Putting the assumptions in the pull request description was added so that a reviewer can check them. |
| Write the least code that does the job | The first sentence restates Karpathy's January 2026 notes as a rule, from his account of agents writing "an inefficient, bloated, brittle construction over 1000 lines of code" that they "immediately cut it down to 100 lines" when asked. The community Karpathy file has the same idea: "If you write 200 lines and it could be 50, rewrite it". "Prefer deleting code to adding it" comes from the pstack Laziness Protocol skill ("Prefer deletion"), not from Matt or Karpathy. |
| Build only what is needed now | Karpathy, [nanochat](https://github.com/karpathy/nanochat): "no giant configuration objects, model factories, or if-then-else monsters". Matt, [codebase-design](https://github.com/mattpocock/skills/blob/main/skills/engineering/codebase-design/SKILL.md): "One adapter means a hypothetical seam. Two adapters means a real one." |
| Start from the obviously correct version | Karpathy, January 2026 notes: "Write the naive algorithm that is very likely correct first, then ask it to optimize it while preserving correctness". [A Recipe for Training Neural Networks](https://karpathy.github.io/2019/04/25/recipe/): "Don't be a hero". Optimizing only when measurements show a need was added here. |
| Keep functions small enough to read | Matt, course-video-manager: "No function has a cyclomatic complexity over 15". |
| Names say what things do | Matt, [code-review](https://github.com/mattpocock/skills/blob/main/skills/engineering/code-review/SKILL.md) smell baseline: "if no honest name comes, the design's murky". |
| Small interface, deep implementation | Matt, codebase-design and course-video-manager, on deep modules, and the Middle Man smell: "cut it, call the real target direct". |
| Self-contained units | Karpathy, [bacterial code](https://x.com/karpathy/status/1941616674094170287): "can you imagine someone going 'yoink' without knowing the rest of your code or having to import anything new". |
| Accept dependencies and return results | Matt, codebase-design: "Accept dependencies, don't create them" and "Return results, don't produce side effects". |
| Derive state instead of copying it | Generalized from Matt's React rules in course-video-manager, which derive optimistic UI from form data instead of mirroring it into state. |
| Make parameters required by default | Matt, course-video-manager and [sandcastle](https://github.com/mattpocock/sandcastle/blob/main/.sandcastle/CODING_STANDARDS.md): optional parameters "are a huge source of bugs (by omission)". |
| One helper per shared job | Matt, course-video-manager: one duration formatter and one toast, each guarded by a script that fails hand-rolled copies. |
| Code smells are flags | Matt, code-review smell baseline: each smell is "never a hard violation". |
| Every escape from the type checker is a leak | Matt, course-video-manager: "Every `any` is a leak". |
| Check inputs where they enter | The first sentence is Matt's course-video-manager rule: "Read every environment variable a run needs at its start". Validating user, file, and network data where it enters is general practice, added here. |
| Link records by stable IDs | Karpathy, [Sequoia Ascent 2026](https://karpathy.bearblog.dev/sequoia-ascent-2026/), on matching payments by email when "the Stripe email and Google login email can differ". |
| Handle every case of a closed set | Matt, course-video-manager: "A switch over a union names every member". |
| Fail loudly | Matt, course-video-manager: "Never swallow a failure silently". Karpathy, Recipe: "Neural net training fails silently". |
| Throw error objects | Matt, course-video-manager: "Throw Errors, not values". |
| Await or handle every async operation | Matt, course-video-manager: "Every promise is awaited, handled or marked void". |
| Every test can fail for a real bug | Matt, course-video-manager, word for word. |
| Test behavior through the public interface | Matt, [tdd](https://github.com/mattpocock/skills/blob/main/skills/engineering/tdd/SKILL.md) and course-video-manager. |
| No tautological tests | Matt, [tweet](https://x.com/mattpocockuk/status/2093068185830347088): "Tautological tests considered harmful." Matt, tdd: "Expected values must come from an independent source of truth". Karpathy, January 2026 notes, on keeping the naive version as the reference. |
| Mock only at system boundaries | Matt, tdd and course-video-manager. |
| One test per behavior, at the strongest boundary | Matt, [testing standards](https://github.com/mattpocock/course-video-manager/blob/main/docs/TESTING_STANDARDS.md): "Prefer one test at the right seam". openclaw, [test-audit](https://github.com/openclaw/openclaw/blob/main/.agents/skills/test-audit/SKILL.md): "one primary owner at strongest boundary". |
| A regression test fails before the fix | Karpathy, January 2026 notes: "Get it to write tests first and then pass them". Matt, tdd: "Red before green". |
| Tests are deterministic | Karpathy, Recipe: "Always use a fixed random seed". Matt, tdd, on mocking time and randomness. openclaw, [proof policy](https://github.com/openclaw/openclaw/blob/main/.agents/skills/openclaw-testing/SKILL.md): "Never rerun or re-push just for green". Treating a flaky test as a bug also follows Huan's CLAUDE.md. |
| Some things are not worth a test | Matt, testing standards, "Not worth a test". |
| UI logic lives outside components | Matt, testing standards, on component tests for wiring and browser-only behavior. |
| Every manual step can be scripted | Matt, sandcastle: every interactive prompt is "paired with a non-interactive CLI flag". Karpathy, Sequoia Ascent 2026: "Every time I am told 'go to this URL' or 'click here,' I think: no." |
