# TODO List for BDA Project 2024/25

## Smart Contract Tasks
- [x] **Task 1.1** (Mandatory, 2 points): Implement a smart contract that extends the ERC20 token and restricts the maximum amount of tokens in circulation to the maxSupply value specified in the constructor.
- [x] **Task 1.2** (2 points): Implement the mintingAdmin role. Initial members of the role will be defined by the constructor argument (array of addresses). Members of the role will be able to mint new tokens to a chosen address, but the total minted tokens per day must not exceed the maxDailyMint parameter defined in the constructor.
- [ ] **Task 1.3** (2 points): Implement the restrAdmin role. Initial members of the role will be defined by the constructor argument (array of addresses). Members of the role will be able to set a daily limit on token transfers for selected addresses. Each address can have a different limit.
- [x] **Task 1.4** (3 points): Implement identity verification for token holders. Tokens can only be held by addresses that have been verified by one of the centralized identity providers (IDP), identified by their address. The initial list of IDPs will be defined by the constructor argument (array of addresses). Add a script to simulate a centralized identity provider.
- [x] **Task 1.5** (After 1.4, 2 points): Implement the idpAdmin role. Initial members of the role will be defined by the constructor argument (array of addresses). Members of the role will be able to add or remove items from the list of centralized identity providers.
- [ ] **Task 1.6** (After 1.4, 2 points): Implement expiration of identity validity for individual addresses with verified identity. The expirationTime value will be defined in the constructor and will indicate the number of hours from obtaining confirmation from the centralized identity provider after which verification expires.
- [ ] **Task 1.7** (After 1.5, 2 points): Extend the idpAdmin role. Each member will be able to manually verify any address without using a centralized identity provider or revoke the verification of an address.
- [x] **Task 1.8** (1 point): Smart contracts will emit events during important occurrences, such as TokensMinted, TokensTransferred, TransferRestrictionCreated.
- [ ] **Task 1.9** (3 points): Allow all implemented roles to add or remove members of their role by a majority vote (threshold scheme).

## dApp Tasks
- [x] **Task 2.1** (4 points): Implement a dApp that allows the user to connect a MetaMask wallet application and provides a graphical user interface showing the address of the currently selected connected address, the current amount of tokens, and allows the transfer of a specified amount of tokens to a specified address.
- [ ] **Task 2.2** (1 point): The dApp provides a graphical user interface allowing approval of spending a specified amount by a specified address (approve functionality of ERC20).
- [x] **Task 2.3** (After 1.2, 1 point): The dApp provides a graphical user interface allowing minting of new tokens for members of the mintingAdmin role and shows how many tokens can still be minted that day.
- [ ] **Task 2.4** (After 1.3, 1 point): The dApp provides a graphical user interface allowing the creation and subsequent removal of transfer restrictions for members of the transferAdmin role.
- [x] **Task 2.5** (After 1.4, 2 points): The dApp provides a graphical user interface allowing identity verification of the owner of the currently selected address. If the currently selected address is not verified, the dApp interface will not allow token manipulation.
- [x] **Task 2.6** (After 1.5, 1 point): The dApp provides a graphical user interface allowing the addition or removal of trusted IDP addresses by members of the idpAdmin role.
- [ ] **Task 2.7** (After 1.6, 1 point): The dApp provides a graphical user interface showing the remaining time until the expiration of identity validity and allows (even preliminary) re-verification of identity.
- [ ] **Task 2.8** (After 1.7, 2 points): The dApp provides a graphical user interface allowing members of the idpAdmin role to manually verify addresses, revoke address expiration, block addresses, and unblock addresses.
- [x] **Task 2.9** (After 1.8, 2 points): The dApp will listen for events emitted by the smart contract and update the displayed data in the dApp upon receiving an event.
- [ ] **Task 2.10** (After 1.9, 2 points): The dApp allows all implemented roles to create votes on adding or removing role members and add votes in existing votes.

## Documentation Tasks
- [ ] **Task 3.1** (1 to 4 points): Briefly describe the chosen implementation technologies and libraries used. Describe the steps needed to start the local environment. Describe the main parts of your solution and justify the decisions you made during implementation.
- [x] **Task 3.2** (1 point): Create a Makefile for easier manipulation with the project with the following goals: network, deploy, dapp, test.
- [ ] **Task 3.3** (After 1.2, 1 point): Describe how you implemented the reset of daily limits at midnight, describe the advantages and disadvantages of your chosen approach compared to others.
- [ ] **Task 3.4** (2 points): Analyze the amount of gas consumed to perform basic contract operations. Focus on the most expensive operation you find and explain why it uses so much gas.
- [ ] **Task 3.5** (1 point): Describe your strategies and overcome problems during testing. Describe techniques you used; describe how your tests are divided into smaller units; describe how you intervened in the EVM; describe how you captured errors and what types of errors you discovered during testing.
- [ ] **Task 3.6** (After 1.7, 1 point): Model with a finite automaton the states that an address can achieve during its lifetime regarding verification, revocation, and blocking.

## Testing Tasks
- [x] **Task 4.1** (1 to 4 points): Verify the implementation of tasks from the smart contract category using tests. Focus not only on testing successful execution but also on testing proper error handling and edge cases.
- [ ] **Task 4.2** (2 points): Find a suitable place where fuzzing could be used in smart contract tests and add it. Describe in the documentation why fuzzing is appropriate there.
- [ ] **Task 4.3** (1 point): Check your smart contract code using a static analysis tool for Solidity and document any errors you uncover.
- [ ] **Task 4.4** (4 points): Create E2E (end-to-end) tests that locally start the blockchain, deploy smart contracts on it, and automatically test the basic functionality of the dApp user interface.

## Summary
| Task ID | Points | Done | _note_   |
| ------- | ------ | ---- | -------- |
| 1.1     | 2      | Y    |          |
| 1.2     | 2      | Y    |          |
| 1.3     | 2      |      |          |
| 1.4     | 3      | Y    |          |
| 1.5     | 2      | Y    |          |
| 1.6     | 2      |      |          |
| 1.7     | 2      |      |          |
| 1.8     | 1      | Y    | 10       |
| 1.9     | 3      |      |          |
| 2.1     | 4      | Y    |          |
| 2.2     | 1      |      |          |
| 2.3     | 1      | Y    |          |
| 2.4     | 1      |      |          |
| 2.5     | 2      | Y    |          |
| 2.6     | 1      | Y    |          |
| 2.7     | 1      |      |          |
| 2.8     | 2      |      |          |
| 2.9     | 2      | Y    | 20       |
| 2.10    | 2      |      |          |
| 3.1     | 1-4    |      | can do   |
| 3.2     | 1      | Y    |          |
| 3.3     | 1      |      |          |
| 3.4     | 2      |      | todo     |
| 3.5     | 1      |      | can do   |
| 3.6     | 1      |      |          |
| 4.1     | 1-4    | Y    | re-check |
| 4.2     | 2      |      |          |
| 4.3     | 1      |      | can do   |
| 4.4     | 4      |      | can do   |
25pts + 9-12pts\_todo = 34-37