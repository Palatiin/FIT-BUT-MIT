network:
	anvil &

deploy:
	export MAX_SUPPLY=1000
	export MINTING_ADMINS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,0x70997970C51812dc3A010C7d01b50e0d17dc79C8
	export MAX_DAILY_MINT=100
	export TRUSTED_IDPS=0x3f176887Ac19bbCcA11052E79BcF1533BD7CFFf9
	export IDP_ADMINS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
	forge create src/Token.sol:Token \
		--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
		--broadcast \
		--constructor-args $(MAX_SUPPLY) [$(MINTING_ADMINS)] $(MAX_DAILY_MINT) [$(TRUSTED_IDPS)] [$(IDP_ADMINS)]

dapp:
	echo "Dapp is not implemented yet"

test:
	forge test

.PHONY: network deploy dapp test
