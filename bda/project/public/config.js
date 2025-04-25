// Configuration for the dApp
const appConfig = {
    // Network configuration for local testing, needs to be set up in MetaMask as well
    networks: {
        // Anvil local blockchain
        anvil: {
            contractAddress: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
            name: "Anvil Local",
            chainId: 31337,  // Default Anvil chain ID
            rpcUrl: "http://localhost:8545",
            blockExplorer: "",
            isTestnet: true
        },
        sepolia: {
            contractAddress: "0x282702f51854B71C7083af2932888B95A47fe265",
            name: "Sepolia Testnet",
            chainId: 11155111,
            rpcUrl: "https://eth-sepolia.g.alchemy.com/v2/dIG9Kp4nWgOenq87EKoiB_eeq8xCxem-",
            blockExplorer: "https://sepolia.etherscan.io/",
            isTestnet: true
        }
    },
    
    // Default network to use
    defaultNetwork: "sepolia"
};

// Export the configuration
if (typeof module !== 'undefined' && module.exports) {
    module.exports = appConfig;
} 