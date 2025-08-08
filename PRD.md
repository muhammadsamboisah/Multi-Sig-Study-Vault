# PRD: Multi-Sig Study Vault

## 1. Overview
Study groups create a GRAFT multi-sig wallet with a finishing-line contract. Members deposit STX up front; upon group consensus, funds refund. Miss deadlines → funds to community pool DAO.

## 2. Goals & Metrics
- 20 study groups formed  
- 100% on-chain withdrawal accuracy  
- 10 scholarship payouts

## 3. Key Features
- GRAFT multi-sig wallet integration  
- Finishing-line Clarity contract enforcing deadlines  
- DAO pool contract for missed deadlines  
- Frontend group dashboard

## 4. Tech Stack
- Frontend: SvelteKit + Stacks.js  
- Smart Contracts: GRAFT wallet + deadline contract + DAO  
- Database: Firestore for off-chain group metadata  
- Wallets: Xverse & Hiro

## 5. Roadmap
1. Integrate GRAFT multi-sig module  
2. Deadline contract in Clarity  
3. DAO pool contract  
4. SvelteKit dashboard & wallet flows  
5. Test group formations & edge cases

## 6. AI Agent Instructions
- Scaffold GRAFT integration code  
- Generate suite of Clarity contracts  
- Build SvelteKit pages & automated tests  
