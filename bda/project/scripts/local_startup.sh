# Send 1 eth to the test metamask wallet - for fees
cast send --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --value 1000000000000000000 0xFc5bA757d1508506198cff41309BC0E3a577895c

# Verify the identity of the mintAdmin (first test account from anvil)
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 "verifyIdentity(uint256, bytes memory)" 1744648020 "0xa0a797df11e6e86c7a05dd0124886b3be54320b9f90b30bd17bfada1a9a85b5719baa9e9555a6ced763d07478bbd1f2e47cc6b82cf9a76f8a6f51805428c08f61c"

# Next: verify test metamask wallet identity, mint tokens to test metamask wallet, ...
