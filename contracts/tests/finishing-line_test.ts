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

Clarinet.test({
  name: "claim before consensus should fail",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const w1 = accounts.get("wallet_1")!;
    const w2 = accounts.get("wallet_2")!;

    chain.mineBlock([
      Tx.contractCall("finishing-line", "create-group", [types.uint(3), types.uint(100), types.uint(2), types.principal(deployer.address)], deployer.address),
      Tx.contractCall("finishing-line", "deposit", [types.uint(3), types.uint(50)], w1.address),
      Tx.contractCall("finishing-line", "signal", [types.uint(3)], w1.address)
    ]);

    const b = chain.mineBlock([
      Tx.contractCall("finishing-line", "claim-refund", [types.uint(3), types.principal(w1.address)], w1.address)
    ]);
    b.receipts[0].result.expectErr();
  }
});

Clarinet.test({
  name: "double-claim is rejected",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const w1 = accounts.get("wallet_1")!;
    const w2 = accounts.get("wallet_2")!;

    chain.mineBlock([
      Tx.contractCall("finishing-line", "create-group", [types.uint(4), types.uint(100), types.uint(2), types.principal(deployer.address)], deployer.address),
      Tx.contractCall("finishing-line", "deposit", [types.uint(4), types.uint(50)], w1.address),
      Tx.contractCall("finishing-line", "deposit", [types.uint(4), types.uint(50)], w2.address),
      Tx.contractCall("finishing-line", "signal", [types.uint(4)], w1.address),
      Tx.contractCall("finishing-line", "signal", [types.uint(4)], w2.address)
    ]);

    const b1 = chain.mineBlock([
      Tx.contractCall("finishing-line", "claim-refund", [types.uint(4), types.principal(w1.address)], w1.address)
    ]);
    b1.receipts[0].result.expectOk();

    const b2 = chain.mineBlock([
      Tx.contractCall("finishing-line", "claim-refund", [types.uint(4), types.principal(w1.address)], w1.address)
    ]);
    b2.receipts[0].result.expectErr();
  }
});
