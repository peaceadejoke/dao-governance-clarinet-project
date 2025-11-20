import { Clarinet, Tx, Chain, Account } from "https://deno.land/x/clarinet@v1.0.0/index.ts";
import { assertEquals } from "https://deno.land/std@0.114.0/testing/asserts.ts";


Clarinet.test("create a proposal, vote and execute", async (chain: Chain, accounts: Map<string, Account>) => {
const deployer = accounts.get("deployer")!;
// create proposal with duration 10 blocks
let block = chain.mineBlock([
Tx.contractCall("governance", "create-proposal", ["\"Buy new servers\"", 10], deployer.address),
]);
// check tx success
assertEquals(block.receipts[0].result.success, true);
});
