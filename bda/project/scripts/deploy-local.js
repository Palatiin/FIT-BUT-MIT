const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');

// Load contract artifact
const contractFile = path.join(__dirname, '..', 'out', 'Token.sol', 'Token.json');
const contractJson = JSON.parse(fs.readFileSync(contractFile, 'utf8'));
const abi = contractJson.abi;
const bytecode = contractJson.bytecode;

// Connect to local Anvil network
const provider = new ethers.JsonRpcProvider('http://localhost:8545');

// First account in Anvil with private key
const wallet = new ethers.Wallet('0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80', provider);

async function deploy() {
    try {
        console.log('Deploying Token contract to local Anvil network...');
        
        // Get the Factory
        const factory = new ethers.ContractFactory(abi, bytecode, wallet);
        
        // Configuration for the token
        const maxSupply = ethers.parseEther('1000000'); // 1 million tokens
        const mintingAdmins = [wallet.address]; // First account as minting admin
        const maxDailyMint = ethers.parseEther('10000'); // 10k per day
        const trustedIdentityProviders = [wallet.address]; // First account as trusted IDP for testing
        const idpAdmins = [wallet.address]; // First account as IDP admin
        
        // Deploy the contract with constructor arguments
        const contract = await factory.deploy(
            maxSupply,
            mintingAdmins,
            maxDailyMint,
            trustedIdentityProviders,
            idpAdmins
        );
        
        await contract.waitForDeployment();
        const deployedAddress = await contract.getAddress();
        
        console.log(`Token contract deployed to: ${deployedAddress}`);
        
        // Update config file with contract address
        const configPath = path.join(__dirname, '..', 'public', 'config.js');
        let configContent = fs.readFileSync(configPath, 'utf8');
        
        // Replace the contract address in the config
        configContent = configContent.replace(
            /contractAddress: "(.*?)"/,
            `contractAddress: "${deployedAddress}"`
        );
        
        fs.writeFileSync(configPath, configContent);
        console.log(`Updated config.js with contract address: ${deployedAddress}`);
        
        // Extract ABI to a separate file for the dApp
        fs.writeFileSync(
            path.join(__dirname, '..', 'public', 'contract-abi.json'),
            JSON.stringify(abi, null, 2)
        );
        console.log('ABI extracted to public/contract-abi.json');
        
        // Mint some tokens to the deployer for testing
        console.log('Minting tokens to the deployer for testing...');
        
        // This account is already verified as we added it as a trusted IDP
        // Let's verify the identity first
        const timestamp = Math.floor(Date.now() / 1000);
        const message = ethers.solidityKeccak256(
            ["string", "address", "string", "uint256"],
            ["User with address ", wallet.address, " has verified their identity at ", timestamp]
        );
        
        // Sign the message
        const messageBytes = ethers.getBytes(message);
        const signature = await wallet.signMessage(messageBytes);
        
        console.log(`Generated verification signature: ${signature}`);
        
        // Verify identity and mint tokens
        await contract.verifyIdentity(timestamp, signature);
        console.log('Successfully verified identity');
        
        // Mint tokens to our account
        const mintAmount = ethers.parseEther('10000');
        await contract.mint(wallet.address, mintAmount);
        console.log(`Successfully minted ${ethers.formatEther(mintAmount)} tokens to ${deployedAddress}`);
        
        return {
            contractAddress: deployedAddress,
            ownerAddress: wallet.address
        };
    } catch (error) {
        console.error('Deployment failed:', error);
        throw error;
    }
}

// Run deployment if this script is run directly
if (require.main === module) {
    deploy()
        .then(() => process.exit(0))
        .catch(error => {
            console.error(error);
            process.exit(1);
        });
} else {
    module.exports = { deploy };
} 