// Clarinet tests (placeholder). Will be expanded for deposit, consensus, refund, forfeit scenarios.
import { Clarinet, Tx, Chain, Account, types } from "https://deno.land/x/clarinet/index.ts";

Clarinet.test({ name: "create group and signal consensus before deadline", async (chain: Chain, accounts: Map<string,Account>) => {
  const deployer = accounts.get("deployer")!;

  let block = chain.mineBlock([
    Tx.contractCall("finishing-line", "create-group", [types.uint(1), types.uint(100), types.uint(2), types.principal(deployer.address)], deployer.address),
    Tx.contractCall("finishing-line", "signal-consensus", [types.uint(1)], deployer.address)
  ]);
  block.receipts[0].result.expectOk();
  block.receipts[1].result.expectOk();
}});
