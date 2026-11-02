# pstack model configuration (T3). One line per role and column. Delete a line to fall back to the skill default.
# `<role>:` sets the general column, as in every sheet before domains. `science <role>:` sets the science column.
# `inherit-parent` or `auto` as a value: the role runs on the parent chat's model (`delegate_task` omits `target`). Alias entries in a panel list still count toward its fan-out.
# budget: large (xhigh)
# Routing since 2026-10-28: Sol codes, Terra writes, edits, searches and verifies, Astra plans, reviews last and takes the hardest work. DeepSeek and Muse are off until further notice; Interrogate reviewers are Sol and Astra; Opus pairs with GPT on the architect, arena and judge panels and falls back to Astra high. Terra runs max on single high-stakes seats, xhigh on fan-out search, high on fully specified work.
feature, refactoring: codex/gpt-6.1-sol reasoningEffort=xhigh serviceTier=default
bug-fix: codex/gpt-6.1-sol reasoningEffort=xhigh serviceTier=default
perf-issue: codex/gpt-6.1-sol reasoningEffort=xhigh serviceTier=default
hillclimb: codex/gpt-6.1-sol reasoningEffort=xhigh serviceTier=default
judgment and prose: codex/gpt-6.1-terra reasoningEffort=max serviceTier=default
hardest tasks: codex/gpt-6-astra reasoningEffort=high serviceTier=default
mechanical code: codex/gpt-6.1-terra reasoningEffort=high serviceTier=default
final review: codex/gpt-6-astra reasoningEffort=high serviceTier=default
how explorer: codex/gpt-6.1-terra reasoningEffort=xhigh serviceTier=default
how explainer: codex/gpt-6.1-terra reasoningEffort=max serviceTier=default
why investigators: codex/gpt-6.1-terra reasoningEffort=xhigh serviceTier=default
why synthesizer: codex/gpt-6.1-terra reasoningEffort=max serviceTier=default
reflect tooling: codex/gpt-6.1-terra reasoningEffort=high serviceTier=default
reflect judgment, divergent, synthesizer: codex/gpt-6-astra reasoningEffort=high serviceTier=default
arena runners: codex/gpt-6.1-sol reasoningEffort=xhigh serviceTier=default, claudeAgent/claude-opus-5-5 effort=xhigh fastMode=false
arena cross-judge pool: codex/gpt-6-astra reasoningEffort=high serviceTier=default, claudeAgent/claude-opus-5-5 effort=xhigh fastMode=false
swarm workers: codex/gpt-6.1-terra reasoningEffort=max serviceTier=default
architect runners: codex/gpt-6-astra reasoningEffort=high serviceTier=default, claudeAgent/claude-opus-5-5 effort=xhigh fastMode=false
interrogate reviewers: codex/gpt-6.1-sol reasoningEffort=xhigh serviceTier=default, codex/gpt-6-astra reasoningEffort=high serviceTier=default
science feature, refactoring: codex/gpt-6.1-sol reasoningEffort=xhigh serviceTier=default
science bug-fix: codex/gpt-6.1-sol reasoningEffort=xhigh serviceTier=default
science perf-issue: codex/gpt-6.1-sol reasoningEffort=xhigh serviceTier=default
science hillclimb: codex/gpt-6.1-sol reasoningEffort=xhigh serviceTier=default
science judgment and prose: codex/gpt-6.1-terra reasoningEffort=max serviceTier=default
science hardest tasks: codex/gpt-6-astra reasoningEffort=high serviceTier=default
science mechanical code: codex/gpt-6.1-terra reasoningEffort=high serviceTier=default
science final review: codex/gpt-6-astra reasoningEffort=high serviceTier=default
science how explorer: codex/gpt-6.1-terra reasoningEffort=xhigh serviceTier=default
science how explainer: codex/gpt-6.1-terra reasoningEffort=max serviceTier=default
science why investigators: codex/gpt-6.1-terra reasoningEffort=xhigh serviceTier=default
science why synthesizer: codex/gpt-6.1-terra reasoningEffort=max serviceTier=default
science reflect tooling: codex/gpt-6.1-terra reasoningEffort=high serviceTier=default
science reflect judgment, divergent, synthesizer: codex/gpt-6-astra reasoningEffort=high serviceTier=default
science arena runners: codex/gpt-6.1-sol reasoningEffort=xhigh serviceTier=default, claudeAgent/claude-opus-5-5 effort=xhigh fastMode=false
science arena cross-judge pool: codex/gpt-6-astra reasoningEffort=high serviceTier=default, claudeAgent/claude-opus-5-5 effort=xhigh fastMode=false
science swarm workers: codex/gpt-6.1-terra reasoningEffort=max serviceTier=default
science architect runners: codex/gpt-6-astra reasoningEffort=high serviceTier=default, claudeAgent/claude-opus-5-5 effort=xhigh fastMode=false
science interrogate reviewers: codex/gpt-6.1-sol reasoningEffort=xhigh serviceTier=default, codex/gpt-6-astra reasoningEffort=high serviceTier=default
session hook: on
