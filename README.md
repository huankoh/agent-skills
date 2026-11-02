# Sync agent setup across machines

Clone this repo and run `sync` to converge the agent setup on macOS and Linux, including aarch64 Spark.
Run the same command on each machine after changing the repo.

The repo manages these six pieces of state.

- The `coding-standards`, `prune-tests`, and vendored `oracle` skills in [skills/](skills/).
- The pinned `huankoh/t3-pstack-science` plugin through its own installer.
- Five pstack skills for tools that do not load the plugin, `grill-me`, `domain-modeling`, `codebase-design`, `improve-codebase-architecture`, and `wizard`.
- The shared pstack model sheet in [config/models.md](config/models.md).
- The private `huankoh/ppt-master-white-sage` clone and its skill link.
- The pinned `@steipete/oracle` CLI from npm.

Your other skills in `~/.agents/skills` stay in place.
Conflicting files, folders, and unrelated links stay untouched and appear as failures in the summary.
A differing model sheet is the exception and gets a timestamped backup before the repo sheet takes its place.

## Set up a machine

Install Git, GitHub CLI, and Node 24 or later, and authenticate `gh` with access to the private presentation repo.
If PATH has an older Node, `sync` selects the newest Node 24 or later under `~/.nvm/versions/node` for its own run.
If no suitable Node exists, the remaining steps run and pstack and Oracle report that they were skipped.

```sh
gh repo clone huankoh/agent-skills ~/code/agent-skills && ~/code/agent-skills/sync
```

The command pulls clean `main` clones with `--ff-only` and leaves dirty trees and other branches in place.
It restarts once if its own pull changes `sync`.
It clones the presentation repo into `~/code/ppt-master-white-sage` and reports a missing `.venv` without creating one.
Follow that skill's setup instructions to prepare its venv.

`sync` links this repo's skills and the presentation skill into `~/.agents/skills`.
[install.sh](install.sh) gives Claude Code a link to each hub skill in `~/.claude/skills`.
Grok Build gets the same links when `~/.grok` exists.
Antigravity's `~/.gemini/config/skills` points to the hub.
Codex, Cursor, Muse Code, OpenCode, and Pi read the hub themselves.

Pstack's installer manages its plugin homes, including Cursor when `~/.cursor` exists and Muse when `muse` is on PATH.
The five ported skills get separate links for detected Pi, OpenCode, Gemini CLI, Antigravity CLI, and T3 Antigravity profiles.
Their source is Cursor's local pstack copy when available, then the highest-versioned default Claude Code cache, then the cache under `CLAUDE_CONFIG_DIR`.
A detected destination tool without a pstack source makes this step fail.
They stay outside the hub because Codex, Cursor, and Muse already load them from the plugin.

## Sync each day

```sh
~/code/agent-skills/sync
~/code/agent-skills/sync --check
```

Every step ends with one summary status, `already right`, `changed`, `would change`, `skipped`, or `failed`.
A failed step does not stop the later steps.
The command exits 1 if a step fails or a check finds something to change.
A second successful sync runs no updater or npm installer when everything matches.

`--check` leaves managed files and links untouched and runs no update or install command.
It fetches Git metadata to count commits behind the upstream and runs pstack's doctor.
Git fetch can update `.git`, and `npx` and doctor can refresh their own caches.

To add your own skill, put it in `~/.agents/skills` and rerun `sync` so Claude Code gets its link.
Use `install.sh --remove` only to remove the links that installer owns.
It leaves the pstack plugin, ported links, model sheet, presentation clone, and Oracle CLI in place.

## Change a pin

Edit [sync.conf](sync.conf), review the diff, and commit the change.
`PSTACK_TAG` selects the pstack release, and `ORACLE_VERSION` selects the npm CLI release.
`PPT_MASTER_REPO` selects the private presentation repository.
Run `sync` on every machine after the change lands on `main`.

## Edit the model sheet

Edit [config/models.md](config/models.md), commit the change, and run `sync` on each machine.
The machine sheet at `${XDG_CONFIG_HOME:-$HOME/.config}/t3-pstack-science/models.md` is a symlink into the clone.
An edit through that machine path also appears as a git diff in the repo.

An identical regular file becomes a link without a backup.
A differing file or a link elsewhere moves to `models.md.bak-<UTC yyyymmddThhmmssZ>` beside the sheet.
`sync` prints the backup path and a `diff` command so you can fold local choices into the repo.
If a backup name already exists, a numeric suffix preserves both copies.

When the installed pstack sheet validator exists, `sync` uses its exported checker to validate the repo sheet offline.
The checker validates syntax and pstack role rules without requiring a live T3 provider catalog.
Pstack doctor checks the sheet again during the plugin step.

## Update the vendored Oracle skill

```sh
cd ~/code/agent-skills
./scripts/vendor-oracle-skill.sh
```

Pass a tag, branch, or commit as the optional argument to select another upstream ref.
The script resolves the ref to a full commit through `gh api`, downloads the skill and license verbatim, and updates `ORACLE_SKILL_COMMIT` in `sync.conf`.
Review the diff in a PR, then run `sync` on each machine after it lands.
The skill commit and the npm CLI version are separate pins.

The validator keeps Agent Skills frontmatter checks for Oracle but exempts its upstream text from house writing rules.
The exemption requires its upstream repository pin, full commit pin, and license file.

## Log in to Oracle once per machine

```sh
oracle --engine browser --browser-manual-login --browser-keep-browser -p "HI"
```

`sync` prints this reminder when `~/.oracle/browser-profile` is missing and never starts an Oracle run itself.
If an old Oracle shim shadows npm's global binary and fails the version check, `sync` reports the shim's path for you to fix.

Oracle's browser engine uses your ChatGPT plan.
API mode bills per call.
Use Oracle after `/architect` has agreed a design, as a one-shot challenge of the chosen sketch with the files it touches.

## Check changes locally

```sh
/bin/bash checks/test_sync.sh
/bin/bash checks/test_install.sh
shellcheck --severity=warning sync install.sh scripts/*.sh checks/*.sh
python3 -I checks/validate_skills.py .
```

The sync suite uses isolated HOME folders, local Git remotes, and fake external tools.
It tests the actual command without installing packages or changing the machine setup.

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
| The opening paragraph | Matt, [course-video-manager standards](https://github.com/mattpocock/course-video-manager/blob/main/CODING_STANDARDS.md), existing violations sit in "a shrink-only allowlist", and rules end with "Enforced by". Matt, [retro](https://github.com/mattpocock/skills/blob/main/skills/engineering/retro/SKILL.md), mechanical violations get a check, and `CODING_STANDARDS.md` is for "genuine judgement calls". |
| Every changed line serves the task | Karpathy, [January 2026 notes](https://x.com/karpathy/status/2015883857489522876), agents "change/remove comments and code they don't like or don't sufficiently understand as side effects". The heading follows the community Karpathy file, "Every changed line should trace directly to the user's request". The sentence about putting unrelated fixes in their own commits was added so that the rule fits Huan's CLAUDE.md instruction to fix what you see. |
| Delete what the change makes unused | Karpathy, January 2026 notes, "they don't clean up dead code after themselves". The community Karpathy file, "Remove imports/variables/functions that YOUR changes made unused". |
| Name the assumptions | Karpathy, January 2026 notes, "the models make wrong assumptions on your behalf and just run along with them without checking". Putting the assumptions in the pull request description was added so that a reviewer can check them. |
| Write the least code that does the job | The first sentence restates Karpathy's January 2026 notes as a rule, from his account of agents writing "an inefficient, bloated, brittle construction over 1000 lines of code" that they "immediately cut it down to 100 lines" when asked. The community Karpathy file has the same idea, "If you write 200 lines and it could be 50, rewrite it". "Prefer deleting code to adding it" comes from the pstack Laziness Protocol skill ("Prefer deletion"), not from Matt or Karpathy. |
| Build only what is needed now | Karpathy, [nanochat](https://github.com/karpathy/nanochat), "no giant configuration objects, model factories, or if-then-else monsters". Matt, [codebase-design](https://github.com/mattpocock/skills/blob/main/skills/engineering/codebase-design/SKILL.md), "One adapter means a hypothetical seam. Two adapters means a real one." |
| Start from the obviously correct version | Karpathy, January 2026 notes, "Write the naive algorithm that is very likely correct first, then ask it to optimize it while preserving correctness". [A Recipe for Training Neural Networks](https://karpathy.github.io/2019/04/25/recipe/), "Don't be a hero". Optimizing only when measurements show a need was added here. |
| Keep functions small enough to read | Matt, course-video-manager, "No function has a cyclomatic complexity over 15". |
| Names say what things do | Matt, [code-review](https://github.com/mattpocock/skills/blob/main/skills/engineering/code-review/SKILL.md) smell baseline, "if no honest name comes, the design's murky". |
| Small interface, deep implementation | Matt, codebase-design and course-video-manager, on deep modules, and the Middle Man smell, "cut it, call the real target direct". |
| Self-contained units | Karpathy, [bacterial code](https://x.com/karpathy/status/1941616674094170287), "can you imagine someone going 'yoink' without knowing the rest of your code or having to import anything new". |
| Accept dependencies and return results | Matt, codebase-design, "Accept dependencies, don't create them" and "Return results, don't produce side effects". |
| Derive state instead of copying it | Generalized from Matt's React rules in course-video-manager, which derive optimistic UI from form data instead of mirroring it into state. |
| Make parameters required by default | Matt, course-video-manager and [sandcastle](https://github.com/mattpocock/sandcastle/blob/main/.sandcastle/CODING_STANDARDS.md), optional parameters "are a huge source of bugs (by omission)". |
| One helper per shared job | Matt, course-video-manager, one duration formatter and one toast, each guarded by a script that fails hand-rolled copies. |
| Code smells are flags | Matt, code-review smell baseline, each smell is "never a hard violation". |
| Every escape from the type checker is a leak | Matt, course-video-manager, "Every `any` is a leak". |
| Check inputs where they enter | The first sentence is Matt's course-video-manager rule, "Read every environment variable a run needs at its start". Validating user, file, and network data where it enters is general practice, added here. |
| Link records by stable IDs | Karpathy, [Sequoia Ascent 2026](https://karpathy.bearblog.dev/sequoia-ascent-2026/), on matching payments by email when "the Stripe email and Google login email can differ". |
| Handle every case of a closed set | Matt, course-video-manager, "A switch over a union names every member". |
| Fail loudly | Matt, course-video-manager, "Never swallow a failure silently". Karpathy, Recipe, "Neural net training fails silently". |
| Throw error objects | Matt, course-video-manager, "Throw Errors, not values". |
| Await or handle every async operation | Matt, course-video-manager, "Every promise is awaited, handled or marked void". |
| Every test can fail for a real bug | Matt, course-video-manager, word for word. |
| Test behavior through the public interface | Matt, [tdd](https://github.com/mattpocock/skills/blob/main/skills/engineering/tdd/SKILL.md) and course-video-manager. |
| No tautological tests | Matt, [tweet](https://x.com/mattpocockuk/status/2093068185830347088), "Tautological tests considered harmful." Matt, tdd, "Expected values must come from an independent source of truth". Karpathy, January 2026 notes, on keeping the naive version as the reference. |
| Mock only at system boundaries | Matt, tdd and course-video-manager. |
| One test per behavior, at the strongest boundary | Matt, [testing standards](https://github.com/mattpocock/course-video-manager/blob/main/docs/TESTING_STANDARDS.md), "Prefer one test at the right seam". openclaw, [test-audit](https://github.com/openclaw/openclaw/blob/main/.agents/skills/test-audit/SKILL.md), "one primary owner at strongest boundary". |
| A regression test fails before the fix | Karpathy, January 2026 notes, "Get it to write tests first and then pass them". Matt, tdd, "Red before green". |
| Tests are deterministic | Karpathy, Recipe, "Always use a fixed random seed". Matt, tdd, on mocking time and randomness. openclaw, [proof policy](https://github.com/openclaw/openclaw/blob/main/.agents/skills/openclaw-testing/SKILL.md), "Never rerun or re-push just for green". Treating a flaky test as a bug also follows Huan's CLAUDE.md. |
| Some things are not worth a test | Matt, testing standards, "Not worth a test". |
| UI logic lives outside components | Matt, testing standards, on component tests for wiring and browser-only behavior. |
| Every manual step can be scripted | Matt, sandcastle, every interactive prompt is "paired with a non-interactive CLI flag". Karpathy, Sequoia Ascent 2026, his objection to interactive instructions such as "go to this URL" or "click here" |
