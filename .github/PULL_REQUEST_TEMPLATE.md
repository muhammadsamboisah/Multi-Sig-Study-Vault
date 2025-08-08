# Pull Request: Implement Finishing-Line Consensus and DAO Forfeit Contracts

## Purpose & Scope
Implements core on-chain logic per PRD:
- Finishing-line contract for group deadlines, deposits, and consensus-driven refunds.
- DAO pool contract stub to receive forfeited funds when deadlines are missed.
- Adds initial Clarinet project wiring and a basic test scaffold.

## Technical Decisions & Rationale
- Clarity v2 targeted via Clarinet.toml for modern syntax.
- Map-based storage for groups, deposits, and consensus to keep MVP flexible.
- DAO pool interaction stubbed to allow incremental integration.

## Key Changes
- contracts/Clarinet.toml: Clarinet project config
- contracts/src/finishing-line.clar: create-group, deposit, signal-consensus, claim-refund, forfeit-to-dao
- contracts/src/dao-pool.clar: record-forfeit stub
- contracts/tests/finishing-line_test.ts: initial Clarinet test scaffold

## Follow-ups
- Implement actual STX/SIP-010 transfers and GRAFT multisig bridge calls
- Expand tests for deposit/claim/forfeit happy paths and edge cases
- Integrate UI calls from web app flows
