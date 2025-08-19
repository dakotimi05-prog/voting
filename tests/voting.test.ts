import { Clarinet, Tx, Chain, Account, types } from "clarinet";

Clarinet.test({
  name: "Users can create a proposal and vote YES/NO",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer")!;
    let alice = accounts.get("wallet_1")!;
    let bob = accounts.get("wallet_2")!;

    // Alice creates a proposal
    let block = chain.mineBlock([
      Tx.contractCall("voting", "create-proposal", [types.ascii("Should we add a community fund?")], alice.address),
    ]);
    block.receipts[0].result.expectOk().expectUint(1);

    // Alice votes YES
    block = chain.mineBlock([
      Tx.contractCall("voting", "vote", [types.uint(1), types.bool(true)], alice.address),
    ]);
    block.receipts[0].result.expectOk().expectBool(true);

    // Bob votes NO
    block = chain.mineBlock([
      Tx.contractCall("voting", "vote", [types.uint(1), types.bool(false)], bob.address),
    ]);
    block.receipts[0].result.expectOk().expectBool(true);

    // Check proposal state
    let proposal = chain.callReadOnlyFn("voting", "get-proposal", [types.uint(1)], deployer.address);
    proposal.result.expectSome().expectTuple({
      creator: types.principal(alice.address),
      title: types.ascii("Should we add a community fund?"),
      yes: types.uint(1),
      no: types.uint(1),
      open: types.bool(true),
    });
  },
});

Clarinet.test({
  name: "Proposal creator can close voting",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let alice = accounts.get("wallet_1")!;
    let bob = accounts.get("wallet_2")!;

    // Alice creates a proposal
    let block = chain.mineBlock([
      Tx.contractCall("voting", "create-proposal", [types.ascii("Close test")], alice.address),
    ]);
    block.receipts[0].result.expectOk().expectUint(1);

    // Alice closes it
    block = chain.mineBlock([
      Tx.contractCall("voting", "close", [types.uint(1)], alice.address),
    ]);
    block.receipts[0].result.expectOk().expectBool(true);

    // Check it's closed
    let proposal = chain.callReadOnlyFn("voting", "get-proposal", [types.uint(1)], alice.address);
    proposal.result.expectSome().expectTuple({
      creator: types.principal(alice.address),
      title: types.ascii("Close test"),
      yes: types.uint(0),
      no: types.uint(0),
      open: types.bool(false),
    });
  },
});
