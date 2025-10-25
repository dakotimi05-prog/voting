import { Clarinet, Tx, Chain, Account, types } from "clarinet";

Clarinet.test({
  name: "GodisGood Karma Raffle: create campaign, add acts, votes, close and select winner",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const alice = accounts.get("wallet_1")!; // campaign creator
    const bob = accounts.get("wallet_2")!;   // another actor
    const voter1 = accounts.get("wallet_3")!;
    const voter2 = accounts.get("wallet_4")!;
    const voter3 = accounts.get("wallet_5")!;

    // 1) Alice creates a campaign
    let block = chain.mineBlock([
      Tx.contractCall("godisgood", "create-campaign", [types.ascii("Acts of Kindness")], alice.address),
    ]);
    block.receipts[0].result.expectOk().expectUint(1);

    // 2) Alice adds an act (id = 1)
    block = chain.mineBlock([
      Tx.contractCall("godisgood", "add-act", [types.uint(1), types.ascii("Helped neighbors carry groceries")], alice.address),
    ]);
    block.receipts[0].result.expectOk().expectUint(1);

    // 3) Bob adds an act (id = 2)
    block = chain.mineBlock([
      Tx.contractCall("godisgood", "add-act", [types.uint(1), types.ascii("Donated clothes to shelter")], bob.address),
    ]);
    block.receipts[0].result.expectOk().expectUint(2);

    // 4) voter1 votes for Alice's act (1)
    block = chain.mineBlock([
      Tx.contractCall("godisgood", "vote", [types.uint(1), types.uint(1)], voter1.address),
    ]);
    block.receipts[0].result.expectOk().expectBool(true);

    // 5) voter2 votes for Alice's act (1) -> Alice leads with 2 votes
    block = chain.mineBlock([
      Tx.contractCall("godisgood", "vote", [types.uint(1), types.uint(1)], voter2.address),
    ]);
    block.receipts[0].result.expectOk().expectBool(true);

    // 6) voter3 votes for Bob's act (2)
    block = chain.mineBlock([
      Tx.contractCall("godisgood", "vote", [types.uint(1), types.uint(2)], voter3.address),
    ]);
    block.receipts[0].result.expectOk().expectBool(true);

    // 7) Check leading act (should be Alice's act id=1 and actor=alice)
    const leading = chain.callReadOnlyFn("godisgood", "get-leading", [types.uint(1)], deployer.address);
    const leaderTuple = leading.result.expectSome().expectTuple();
    leaderTuple["actor"].expectPrincipal(alice.address);
    leaderTuple["votes"].expectUint(2);

    // 8) Close campaign (creator only)
    block = chain.mineBlock([
      Tx.contractCall("godisgood", "close-campaign", [types.uint(1)], alice.address),
    ]);
    block.receipts[0].result.expectOk().expectBool(true);

    // 9) Select winner (creator triggers selection)
    block = chain.mineBlock([
      Tx.contractCall("godisgood", "select-winner", [types.uint(1)], alice.address),
    ]);
    // should return winner principal (alice) in ok
    block.receipts[0].result.expectOk();

    // 10) Verify the winner stored on-chain equals alice
    const winner = chain.callReadOnlyFn("godisgood", "get-winner", [types.uint(1)], deployer.address);
    winner.result.expectSome().expectPrincipal(alice.address);
  },
});
