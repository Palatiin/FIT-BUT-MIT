network:
	anvil &

deploy:
	export MAX_SUPPLY=1000 && \
	export MINTING_ADMINS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,0xFc5bA757d1508506198cff41309BC0E3a577895c && \
	export MAX_DAILY_MINT=100 && \
	export TRUSTED_IDPS=0x3f176887Ac19bbCcA11052E79BcF1533BD7CFFf9 && \
	export IDP_ADMINS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,0xFc5bA757d1508506198cff41309BC0E3a577895c && \
	forge create src/Token.sol:Token \
		--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
		--broadcast \
		--constructor-args $${MAX_SUPPLY} [$${MINTING_ADMINS}] $${MAX_DAILY_MINT} [$${TRUSTED_IDPS}] [$${IDP_ADMINS}]

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
	cast send --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
		--value 1000000000000000000 0xFc5bA757d1508506198cff41309BC0E3a577895c
	cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
		--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
		"verifyIdentity(uint256, bytes memory)" \
		1744648020 \
		"0xa0a797df11e6e86c7a05dd0124886b3be54320b9f90b30bd17bfada1a9a85b5719baa9e9555a6ced763d07478bbd1f2e47cc6b82cf9a76f8a6f51805428c08f61c"


.PHONY: network deploy dapp test setup
