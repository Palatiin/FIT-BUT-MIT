Matúš Remeň, xremen01

---
Contract:
https://sepolia.etherscan.io/address/0x282702f51854b71c7083af2932888b95a47fe265
## List of Implemented Tasks
| Smart Contract | dApp | Documentation | Tests |
| -------------- | ---- | ------------- | ----- |
| 1.1            | 2.1  | 3.1           | 4.1   |
| 1.2            | 2.3  | 3.2           | 4.2   |
| 1.4            | 2.5  | 3.3           | 4.3   |
| 1.5            | 2.6  | 3.4           |       |
| 1.8            | 2.9  | 3.5           |       |
## Start Local Env (3.1)
**requirements**
- install foundry
- install solidity libs - forge-std, openzeppelin/contracts
- install js libs - ethers (\^5.7.2), express

**start with adjustments**
- run `node scripts/generate_idp.js` - generate an IDP (private key + address)
- (optional) update list of `usersToVerify` in `simulate_idp.js:24` if you want to create signatures for identity verification
- run `node scripts/simulate_idp.js <idp-private-key>`
- (optional) update `Makefile` if you want:
	- additional roles - mint admin, idp admin
	- change the trusted IDP list
	- change max supply and/or max daily mint limit
- run `make network` - start local network
- run `make deploy` - deploy contract on local network
- open `http://localhost:3000` in browser to access the dApp interface
- connect with Metamask wallet

**start with prepared env**
- generate verification data for your address
	- default private key + idp address are at the beginning of `scripts/simulate_idp.js`
- update `Makefile` - insert your wallet address
- run `make setup` - this will:
	- start local network
	- deploy the contract on local network
	- start dApp
	- send 1eth to your wallet address on local network (for fees)
	- verify identity of the first test (anvil) wallet on local network who is configured as mint admin and IDP admin
## Implementation Technologies, Libraries (3.1)
### Technologies
- Foundry - tooling for development of the smart contract
- Solidity (\^0.8.28) - implementation of the smart contract and tests
- HTML - web interface structure of the dApp
- javascript (Node.js)
	- dApp: communication with the smart contract, web behavior - displaying/hiding HTML elements, populating HTML with data from smart contract
	- (helper) scripts - extraction of ABI, generating IDPs (private key + address pairs), simulation of an IDP (takes a private key and creates verification data for the specified addresses)
	- local server hosting (at `http://localhost:3000`)

### Libraries
#### Solidity
forge-std - collection of helpful contracts and libraries, used for implementation of tests
openzeppelin/contracts - library for secure smart contract development, ERC20 base contract
#### Javascript
ethers - library for interacting with ethereum blockchain and its ecosystem
express - web framework for Node.js
path - built-in module for working with directories and file paths
fs - built-in modle for working with the file system

## Resetting Daily Limits at Midnight (3.3)
I implemented the resetting of daily limits for minting new tokens by using `block.timestamp` as a source of current time and operations with value `1 days` (86400 (sec)). 
```
currentTimestamp = block.timestamp
secondsSinceMidnight = currentTimestamp % 1 days
nextDailyLimitResetTimestamp = currentTimestamp + 1 days - secondsSinceMidnight
```
The daily mint counter resets with call of `mint` function (modifying function), until then function `getDailyMintQuota` (view function) handles outputting of the correct value (if current timestamp greater than the next reset timestamp, display dailyMined as 0).

This solution leads to inconsistency in contract attribute `dailyMinted` until `mint` is called. Because of this, the `dailyMinted` is a private attribute and just function `getDailyMintQuota` should be used for reading the daily limit.

## Gas Consumption (3.4)
| Action           | Gas       |
| ---------------- | --------- |
| Deploy           | `2488384` |
| VerifyIdentity   | `  38521` |
| Mint             | ` 119564` |
| Transfer         | `  58578` |
| AddTrustedIDP    | `  75230` |
| RemoveTrustedIDP | `  32814` |
- checked on local network
## Fuzzing in Tests (4.2)
Fuzzing is used in test `testFuzz_idp_admin_management` and `testFuzz_transfer_preserves_total_supply`. The IDP admin management test uses constraints `newIDP != address(0)` and `newIDP != address(already_trusted_IDP_address)`. Fuzzing helps here to keep the test case easy to read, and tests adding and removing wide range of addresses.

The second test with fuzzing tests whether various mint amounts and subsequent transfers between wallets keep the value of total supply consistent - no new tokens are created or lost.

## Static Analyzer Check (4.3)
For static analysis of the contract I used tool `slither`. It printed a "Weak PRNG" which is high severity detection. The issue is related to the logic for calculating daily mint limit reset time, because it uses modulo operation with `block.timestamp`, which can be manipulated by a miner. Although, that is not used as PRNG, so this detection is irrelevant.

