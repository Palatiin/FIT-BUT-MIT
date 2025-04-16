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

setup:
	anvil &
	make deploy
	make dapp &
	sh scripts/local_startup.sh

.PHONY: network deploy dapp test
