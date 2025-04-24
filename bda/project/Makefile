MY_WALLET_ADDRESS=0xFc5bA757d1508506198cff41309BC0E3a577895c

ANVIL_FIRST_TEST_WALLET_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
ANVIL_FIRST_TEST_WALLET_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
MAX_SUPPLY=1000
MAX_DAILY_MINT=100

LOCAL_CONTRACT_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3

network:
	anvil &

deploy:
	export MINTING_ADMINS=$(ANVIL_FIRST_TEST_WALLET_ADDRESS),$(MY_WALLET_ADDRESS) && \
	export TRUSTED_IDPS=0x3f176887Ac19bbCcA11052E79BcF1533BD7CFFf9 && \
	export IDP_ADMINS=$(ANVIL_FIRST_TEST_WALLET_ADDRESS),$(MY_WALLET_ADDRESS) && \
	forge create src/Token.sol:Token \
		--private-key $(ANVIL_FIRST_TEST_WALLET_PRIVATE_KEY) \
		--broadcast \
		--constructor-args $(MAX_SUPPLY) [$${MINTING_ADMINS}] $(MAX_DAILY_MINT) [$${TRUSTED_IDPS}] [$${IDP_ADMINS}]

deploy-sepolia:
	forge script scripts/Deploy.s.sol:DeployScript \
		--rpc-url https://eth-sepolia.g.alchemy.com/v2/dIG9Kp4nWgOenq87EKoiB_eeq8xCxem-

dapp:
	node scripts/extract-abi.js && node server.js

test:
	forge test

# Local testing setup:
# - Start local network
# - Deploy the contract
# - Deploy the dApp
# - Send 1 eth to the test metamask wallet - for fees
# - Verify the identity of the first test account made by anvil
setup:
	anvil &
	make deploy
	make dapp &
	cast send --private-key $(ANVIL_FIRST_TEST_WALLET_PRIVATE_KEY) --value 1000000000000000000 $(MY_WALLET_ADDRESS)
	cast send $(LOCAL_CONTRACT_ADDRESS) \
		--private-key $(ANVIL_FIRST_TEST_WALLET_PRIVATE_KEY) \
		"verifyIdentity(uint256, bytes memory)" \
		1744886366 \
		"0x4cfb5df9b35b5885c712670af2df9157c5284821351ee296763e1e4cd13aaee154d85b235da0fe3caad8270e0d4f828f563f0f8c0dfeab45149e7f2f68aec73c1b"


.PHONY: network deploy dapp test setup
