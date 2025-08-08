// @ts-nocheck
import { Clarinet, Tx, Chain, Account, types } from "https://deno.land/x/clarinet@v1.7.0/index.ts";

Clarinet.test({
  name: "happy path: create group, deposit, reach consensus, claim refund",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet1 = accounts.get("wallet_1")!;
    const wallet2 = accounts.get("wallet_2")!;

    const block1 = chain.mineBlock([
      Tx.contractCall(
        "finishing-line",
        "create-group",
        [types.uint(1), types.uint(100), types.uint(2), types.principal(deployer.address)],
        deployer.address
      ),
      Tx.contractCall("finishing-line", "deposit", [types.uint(1), types.uint(50)], wallet1.address),
      Tx.contractCall("finishing-line", "deposit", [types.uint(1), types.uint(50)], wallet2.address),
      Tx.contractCall("finishing-line", "signal", [types.uint(1)], wallet1.address),
      Tx.contractCall("finishing-line", "signal", [types.uint(1)], wallet2.address)
    ]);
    block1.receipts.forEach((r) => r.result.expectOk());

    const block2 = chain.mineBlock([
      Tx.contractCall("finishing-line", "claim-refund", [types.uint(1), types.principal(wallet1.address)], wallet1.address),
      Tx.contractCall("finishing-line", "claim-refund", [types.uint(1), types.principal(wallet2.address)], wallet2.address)
    ]);
    block2.receipts.forEach((r) => r.result.expectOk());
  }
});

Clarinet.test({
  name: "forfeit path: after deadline without consensus, member can forfeit",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet1 = accounts.get("wallet_1")!;

    const b1 = chain.mineBlock([
      Tx.contractCall(
        "finishing-line",
        "create-group",
        [types.uint(2), types.uint(3), types.uint(2), types.principal(deployer.address)],
        deployer.address
      ),
      Tx.contractCall("finishing-line", "deposit", [types.uint(2), types.uint(100)], wallet1.address)
    ]);
    b1.receipts.forEach((r) => r.result.expectOk());

    // advance beyond deadline
    chain.mineEmptyBlock(5);

    const b2 = chain.mineBlock([
      Tx.contractCall("finishing-line", "forfeit-self", [types.uint(2)], wallet1.address)
    ]);
    b2.receipts[0].result.expectOk();
  }
});
