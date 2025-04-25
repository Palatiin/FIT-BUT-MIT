// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
// Import your contract - replace with your actual contract path
import "../src/Token.sol";

contract DeployScript is Script {
    function run() external returns (Token) {
        // Read private key from environment variable for deployment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Start broadcasting transactions from the deployer account
        vm.startBroadcast(deployerPrivateKey);

        address[] memory mintingAdmins = new address[](1);
        mintingAdmins[0] = deployer;

        address[] memory trustedIDPList = new address[](1);
        trustedIDPList[0] = 0x3f176887Ac19bbCcA11052E79BcF1533BD7CFFf9;

        address[] memory idpAdmins = new address[](1);
        idpAdmins[0] = deployer;

        Token token = new Token(10000, mintingAdmins, 500, trustedIDPList, idpAdmins);
        
        // Stop broadcasting transactions
        vm.stopBroadcast();
        
        // Log the deployed contract address
        console.log("YourContract deployed at:", address(token));
        
        return token;
    }
}