# Campaign mode

Use campaign mode when a suite is too large for one ledger.
A campaign prunes one area of production code per pull request.
Every rule in [SKILL.md](../SKILL.md) still applies, and this file sets the order of work.
Finish each step before starting the next.

1. **Baseline.** Record the line counts of tests and of test support code, and every test file's pass or fail result, at one pinned commit.
   Done when every test file in the area has a result.
2. **Lanes.** Split the area into lanes along production code boundaries, not test file names.
   Done when every test file belongs to exactly one lane.
3. **Ledgers.** Build the SKILL.md ledger for each lane.
   When you can run sub-agents, give each lane to its own read-only sub-agent.
   Done when every test in every lane has a mark and an evidence line.
4. **Layer plan.** Read the ledgers together and look for whole layers that repeat each other, such as several suites replaying the same shared code through mocks.
   Name one keeper suite per behavior, and correct the ledger mistakes this pass finds.
   Done when each lane lists the files it retires, the keeper for each behavior, the assertions to move into keepers, and the test-only production code it unlocks.
5. **Cutover.** Apply the plan one lane at a time, following SKILL.md step 4.
   Change shared test helpers through one owner at a time, and update CI test lists and any line-count baselines.
   Done when every lane's plan is applied and its keepers pass.
6. **Preservation review.** Have reviewers who did not write the ledgers compare the deleted coverage against the keepers, one reviewer per group of lanes.
   They look for behaviors that lost their only test, and for new assertions that cannot fail.
   Restore each gap in a keeper and prove it with a mutation.
   Done when every reported gap is restored, or rejected with evidence from the source.
7. **Product bugs.** Report the baseline failures that turned out to be real bugs, with reproductions.
   Fix one only when the user asks, in its own commit, with a test that fails before the fix and passes after it.
8. **Hand-off.** Merge the main branch rather than rebasing a long campaign.
   When main changed a file the campaign deleted, keep the deletion and move the new behavior into the keeper.
   Report what SKILL.md step 5 asks for, plus the lanes and keepers, the gaps the review found, and the line counts at the pinned commit and at the end.
