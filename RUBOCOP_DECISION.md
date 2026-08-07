# RuboCop Backlog Decision

## Decision

Defer the full backlog as a separate maintenance campaign. Do not run a
repository-wide autocorrect during the hosting migration or Android work.

## Baseline

- 685 offenses across 204 files from `bundle exec rubocop --format json`.
- The existing backlog is broader than the current deployment scope and would
  produce a large, difficult-to-review diff.
- Dependency audits are clean, so the backlog is not currently a release
  blocker.

## Follow-up campaign

When scheduled separately:

1. Freeze the baseline and group offenses by cop and risk.
2. Fix security/correctness cops first, then high-volume mechanical cops in
   small commits.
3. Run the full Rails suite after each group.
4. Add a CI rule preventing new offenses without requiring an immediate
   repository-wide cleanup.

Until that campaign is approved, RuboCop remains an explicitly tracked debt,
not a reason to mix unrelated changes into the migration.
