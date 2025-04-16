// Configuration for the dApp
const appConfig = {
    // Replace with your deployed contract address
    contractAddress: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
    
    // Network configuration
    networks: {
        // Anvil local blockchain
        anvil: {
            name: "Anvil Local",
            chainId: 31337,  // Default Anvil chain ID
            rpcUrl: "http://localhost:8545",
            blockExplorer: "",
            isTestnet: true
        }
    },
    
    // Default network to use
    defaultNetwork: "anvil"
};

// Export the configuration
if (typeof module !== 'undefined' && module.exports) {
    module.exports = appConfig;
} 