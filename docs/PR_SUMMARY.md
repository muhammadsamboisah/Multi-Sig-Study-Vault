# PR: Finishing-Line Consensus + DAO Forfeit (MVP)

## Purpose & Scope
Implements core on-chain logic for study groups:
- Deadline-based consensus signaling for refunds
- Accounting-only deposits and refunds
- Post-deadline forfeiture path
- Initial test suite (happy path + negative cases)

## Technical Decisions
- Accounting-only MVP to unblock flows; actual STX/SIP-010 transfers and GRAFT bridges are follow-ups.
- Idempotent signal() with a simple signal counter per group.
- Deno-based tests (Clarinet 3.x).

## Changes
- contracts/Clarinet.toml (project config)
- contracts/src/finishing-line.clar (public: create-group, deposit, signal, claim-refund, forfeit-self; ro: get-group, has-consensus)
- contracts/src/dao-pool.clar (minimal accounting)
- contracts/tests/finishing-line_test.ts (happy paths + negatives)
- .github/workflows/contracts-tests.yml (CI for tests)
- README.md (updated test instructions)

## Follow-ups
- Implement real STX or SIP-010 transfers and GRAFT multisig calls
- Add DAO accounting hook to forfeit-self
- Minimal SvelteKit pages and contract wrappers for user flows
