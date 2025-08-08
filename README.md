# Multi-Sig Study Vault

A SvelteKit + Stacks.js dApp enabling study groups to form GRAFT-powered multi-sig wallets with a finishing-line contract. Members deposit STX up front; on-time completion triggers refunds by group consensus. Missed deadlines route funds to a community DAO pool. Contracts are written in Clarity; off-chain metadata uses Firestore.

## Tech Stack (from PRD)
- Frontend: SvelteKit + Stacks.js (Xverse & Hiro wallets)
- Smart Contracts: GRAFT multi-sig integration, Deadline contract, DAO pool contract (Clarity)
- Database: Firestore for off-chain group metadata

## Repository Layout
- `web/` – SvelteKit app and wallet flows
- `contracts/` – Clarity contracts and tests
- `services/` – Firestore integration and admin scripts
- `docs/` – Additional documentation; see `PRD.md` for full product spec

## Getting Started (Dev Setup)
1. Prerequisites
   - Node.js LTS and pnpm/yarn/npm
   - Clarinet (for Clarity development)
   - Firebase CLI (if using local emulators)

2. Install dependencies
   - Web: to be added after SvelteKit init
   - Contracts: managed via Clarinet
   - Services: Node/Firebase modules to be added later

3. Environment
   - Copy `.env.example` to `.env` in project root and `web/`
   - Populate Stacks network, wallet config, Firebase credentials (placeholders for now)

## Running Tests
- Contracts (Deno-based Clarinet tests):
   1. Install Deno (winget install -e --id DenoLand.Deno)
   2. Run from contracts/: `deno test -A tests`
- Web: via Playwright/Vitest (to be added)
- Services: via your preferred test runner (to be added)

## CI
- GitHub Actions workflow runs Deno-based Clarinet tests on pull requests.

## Documentation
For detailed product specifications, refer to `PRD.md` at the repository root.
