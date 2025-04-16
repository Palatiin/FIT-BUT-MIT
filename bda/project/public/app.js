// Contract ABI (simplified for the functions we need)
// This is a fallback in case we don't have the full ABI
let tokenABI = [
    // Read functions
    "function balanceOf(address) view returns (uint256)",
    // Write functions
    "function verifyIdentity(uint256 timestamp, bytes memory signature)",
    "function transfer(address to, uint256 value) returns (bool)",
    // Events
    "event IdentityVerified(address indexed user, uint256 timestamp)",
    "event TokensTransferred(address indexed from, address indexed to, uint256 amount)",
    "event TokensMinted(address indexed minter, address indexed to, uint256 amount)"
];

// App state
const state = {
    provider: null,
    signer: null,
    tokenContract: null,
    userAddress: null,
    userStatus: {
        isVerified: false,
        isMintingAdmin: false,
        isIDPAdmin: false
    },
    tokenBalance: 0,
    contractAddress: appConfig ? appConfig.contractAddress : "", // Get from config if available
    currentNetwork: appConfig ? appConfig.defaultNetwork : null, // Current selected network
    customProvider: null // For non-MetaMask providers (like Anvil)
};

// DOM elements
const connectWalletCard = document.getElementById('connectWalletCard');
const walletInfoCard = document.getElementById('walletInfoCard');
const verifyIdentityCard = document.getElementById('verifyIdentityCard');
const transferTokensCard = document.getElementById('transferTokensCard');
const mintTokensCard = document.getElementById('mintTokensCard');
const idpAdminCard = document.getElementById('idpAdminCard');
const userAddressElement = document.getElementById('userAddress');
const verificationStatusElement = document.getElementById('verificationStatus');
const mintingAdminStatusElement = document.getElementById('mintingAdminStatus');
const idpAdminStatusElement = document.getElementById('idpAdminStatus');
const tokenBalanceElement = document.getElementById('tokenBalance');
const statusMessageElement = document.getElementById('statusMessage');
const logContainerElement = document.getElementById('logContainer');
const networkSelectElement = document.getElementById('networkSelect');

// Buttons
const connectWalletBtn = document.getElementById('connectWalletBtn');
const verifyIdentityBtn = document.getElementById('verifyIdentityBtn');
const transferTokensBtn = document.getElementById('transferTokensBtn');
const mintTokensBtn = document.getElementById('mintTokensBtn');
const addTrustedIDPBtn = document.getElementById('addTrustedIDPBtn');
const removeTrustedIDPBtn = document.getElementById('removeTrustedIDPBtn');

// Initialize the app
async function init() {
    // Check if ethers is loaded properly
    if (typeof ethers === 'undefined') {
        console.error('Ethers.js library not loaded properly');
        updateStatus('Failed to load Ethereum library. Please refresh the page or check console for errors.', 'danger');
        return;
    } else {
        console.log('Ethers.js loaded successfully:', ethers.version);
    }
    
    // Populate network selector if it exists
    if (networkSelectElement && appConfig && appConfig.networks) {
        for (const [key, network] of Object.entries(appConfig.networks)) {
            const option = document.createElement('option');
            option.value = key;
            option.textContent = network.name;
            if (key === appConfig.defaultNetwork) {
                option.selected = true;
            }
            networkSelectElement.appendChild(option);
        }
        
        // Add event listener for network changes
        networkSelectElement.addEventListener('change', handleNetworkChange);
    }
    
    // Initialize provider based on selected network
    initializeProvider();
    
    // Check if MetaMask is installed
    if (typeof window.ethereum === 'undefined') {
        // Even if MetaMask is not available, we can still use a custom provider
        // for local networks like Anvil
        if (state.currentNetwork === 'anvil') {
            logToConsole('MetaMask not detected, but using Anvil local provider');
        } else {
            updateStatus('MetaMask is not installed. Please install MetaMask or use a local network.', 'warning');
        }
    } else {
        // Add event listener for account changes
        window.ethereum.on('accountsChanged', handleAccountsChanged);
    }

    // Try to load the full ABI from the JSON file if available
    try {
        const response = await fetch('./contract-abi.json');
        if (response.ok) {
            tokenABI = await response.json();
            logToConsole('Loaded full ABI from JSON file');
        } else {
            logToConsole('Using fallback ABI (simplified)');
        }
    } catch (error) {
        logToConsole('Error loading ABI, using fallback: ' + error.message);
    }

    // Add event listeners
    connectWalletBtn.addEventListener('click', connectWallet);
    verifyIdentityBtn.addEventListener('click', verifyIdentity);
    transferTokensBtn.addEventListener('click', transferTokens);

    // Check if already connected through MetaMask
    if (window.ethereum && window.ethereum.selectedAddress) {
        connectWallet();
    }
}

// Initialize provider based on selected network
function initializeProvider() {
    if (!appConfig || !appConfig.networks || !state.currentNetwork) {
        logToConsole('No network configuration found');
        return;
    }
    
    const networkConfig = appConfig.networks[state.currentNetwork];
    if (!networkConfig) {
        logToConsole(`Network configuration not found for: ${state.currentNetwork}`);
        return;
    }
    
    // For Anvil or other local networks, create a JSON-RPC provider
    if (state.currentNetwork === 'anvil') {
        state.customProvider = new ethers.providers.JsonRpcProvider(networkConfig.rpcUrl);
        logToConsole(`Connected to local Anvil network at ${networkConfig.rpcUrl}`);
        
        // Enable the connect button even without MetaMask for local testing
        updateStatus('Ready to connect to local Anvil network', 'info');
    }
}

// Handle network change
function handleNetworkChange(event) {
    state.currentNetwork = event.target.value;
    logToConsole(`Network changed to: ${state.currentNetwork}`);
    
    // Reset the app state
    resetApp();
    
    // Initialize the new provider
    initializeProvider();
}

// Connect wallet function
async function connectWallet() {
    console.log('Connecting wallet...');
    try {
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        
        // Set up ethers provider and signer
        state.provider = new ethers.providers.Web3Provider(window.ethereum);
        state.signer = state.provider.getSigner();
        state.userAddress = accounts[0];
        
        // Initialize contract
        if (state.contractAddress) {
            state.tokenContract = new ethers.Contract(
                state.contractAddress,
                tokenABI,
                state.signer
            );
            
            // Get user verification status and balance
            await updateUserInfo();
        } else {
            updateStatus('Contract address is not set. Please deploy your contract and set the address in config.js.', 'warning');
        }
        
        // Update UI
        userAddressElement.textContent = state.userAddress;
        connectWalletCard.classList.add('hidden');
        walletInfoCard.classList.remove('hidden');
        
        // Show appropriate cards based on user roles
        if (state.userStatus.isVerified) {
            verifyIdentityCard.classList.add('hidden');
            transferTokensCard.classList.remove('hidden');
            updateStatus('Wallet connected! You are verified and can transfer tokens.', 'success');
        } else {
            verifyIdentityCard.classList.remove('hidden');
            transferTokensCard.classList.add('hidden');
            updateStatus('Wallet connected! Please verify your identity to transfer tokens.', 'warning');
        }
        
        // Add event listeners for contract events if using MetaMask
        if (state.tokenContract) {
            state.tokenContract.on('IdentityVerified', handleIdentityVerified);
            state.tokenContract.on('TokensTransferred', handleTokensTransferred);
            state.tokenContract.on('TokensMinted', handleTokensMinted);
            state.tokenContract.on('TrustedIDPAdded', handleTrustedIDPListChanged);
            state.tokenContract.on('TrustedIDPRemoved', handleTrustedIDPListChanged);
        }
        
        logToConsole('Wallet connected: ' + state.userAddress);
    } catch (error) {
        updateStatus('Failed to connect wallet: ' + error.message, 'danger');
        logToConsole('Error: ' + error.message);
    }
}

// Update user information
async function updateUserInfo() {
    if (!state.tokenContract) return;
    
    try {
        // Check verification status
        console.log('User address:', state.userAddress);
        state.userStatus = await state.tokenContract.getUserStatus(state.userAddress);
        console.log('User status:', state.userStatus);
        verificationStatusElement.textContent = state.userStatus.isVerified ? 'Yes' : 'No';
        mintingAdminStatusElement.textContent = state.userStatus.isMintingAdmin ? 'Yes' : 'No';
        idpAdminStatusElement.textContent = state.userStatus.isIDPAdmin ? 'Yes' : 'No';
        
        // Get token balance
        state.tokenBalance = await state.tokenContract.balanceOf(state.userAddress);
        tokenBalanceElement.textContent = state.tokenBalance;
        
        // Update UI based on user roles
        if (state.userStatus.isVerified) {
            verifyIdentityCard.classList.add('hidden');
            transferTokensCard.classList.remove('hidden');
        } else {
            verifyIdentityCard.classList.remove('hidden');
            transferTokensCard.classList.add('hidden');
        }

        if (state.userStatus.isMintingAdmin) {
            mintTokensCard.classList.remove('hidden');
        } else {
            mintTokensCard.classList.add('hidden');
        }

        if (state.userStatus.isIDPAdmin) {
            // Clear the trustedIDPList
            const trustedIDPListElement = document.getElementById('trustedIDPList');
            trustedIDPListElement.innerHTML = '';
            // Populate the trustedIDPList with the trusted IDPs
            const trustedIDPList = await state.tokenContract.getTrustedIDPList();
            // Display one idp address per line
            trustedIDPListElement.innerHTML = trustedIDPList.map(idp => `<p>${idp}</p>`).join('');
            idpAdminCard.classList.remove('hidden');
        } else {
            idpAdminCard.classList.add('hidden');
            // Clear the trustedIDPList
            const trustedIDPListElement = document.getElementById('trustedIDPList');
            trustedIDPListElement.innerHTML = '';
        }
    } catch (error) {
        updateStatus('Failed to update user info: ' + error.message, 'danger');
        logToConsole('Error: ' + error.message);
    }
}

// Verify identity
async function verifyIdentity() {
    if (!state.tokenContract) return;
    
    try {
        const timestamp = document.getElementById('timestampInput').value;
        const signature = document.getElementById('identitySignature').value;
        
        if (!timestamp || !signature) {
            updateStatus('Please provide both timestamp and signature', 'warning');
            return;
        }
        
        updateStatus('Verifying identity...', 'info');
        
        // Call the smart contract function
        const tx = await state.tokenContract.verifyIdentity(timestamp, signature);
        logToConsole('Transaction sent: ' + tx.hash);
        
        updateStatus('Verification transaction submitted. Waiting for confirmation...', 'info');
        
        // Wait for the transaction to be mined
        await tx.wait();
        
        // Update user info
        await updateUserInfo();
        
        updateStatus('Identity verification successful!', 'success');
    } catch (error) {
        updateStatus('Failed to verify identity: ' + error.message, 'danger');
        logToConsole('Error: ' + error.message);
    }
}

// Transfer tokens
async function transferTokens() {
    if (!state.tokenContract) return;
    
    try {
        const recipientAddress = document.getElementById('recipientAddress').value;
        const amount = document.getElementById('tokenAmount').value;
        
        if (!recipientAddress || !amount) {
            updateStatus('Please provide both recipient address and amount', 'warning');
            return;
        }
        
        // Validate address
        if (!ethers.utils.isAddress(recipientAddress)) {
            updateStatus('Invalid recipient address', 'danger');
            return;
        }
        
        updateStatus('Transferring tokens...', 'info');

        // Call the smart contract function
        const tx = await state.tokenContract.transfer(recipientAddress, amount);
        logToConsole('Transaction sent: ' + tx.hash);
        
        updateStatus('Transfer transaction submitted. Waiting for confirmation...', 'info');
        
        // Wait for the transaction to be mined
        await tx.wait();
        
        // Update user info
        await updateUserInfo();
        
        updateStatus('Token transfer successful!', 'success');
    } catch (error) {
        updateStatus('Failed to transfer tokens: ' + error.message, 'danger');
        logToConsole('Error: ' + error.message);
    }
}

// Event handlers
function handleAccountsChanged(accounts) {
    if (accounts.length === 0) {
        // User disconnected their wallet
        resetApp();
        updateStatus('Wallet disconnected', 'info');
    } else if (accounts[0] !== state.userAddress) {
        // User switched accounts
        state.userAddress = accounts[0];
        userAddressElement.textContent = state.userAddress;
        updateUserInfo();
        updateStatus('Account changed to: ' + state.userAddress, 'info');
        logToConsole('Account changed: ' + state.userAddress);
    }
}

function handleIdentityVerified(user, timestamp) {
    if (user.toLowerCase() === state.userAddress.toLowerCase()) {
        updateStatus('Identity verified successfully!', 'success');
        logToConsole('Identity verified for: ' + user + ' at timestamp: ' + timestamp);
        updateUserInfo();
    }
}

function handleTokensTransferred(from, to, amount) {
    if (from.toLowerCase() === state.userAddress.toLowerCase() || 
        to.toLowerCase() === state.userAddress.toLowerCase()) {
        updateStatus('Token transfer completed', 'success');
        logToConsole(`Tokens transferred: ${amount} TKN from ${from} to ${to}`);
        updateUserInfo();
    }
}

function handleTokensMinted(minter, to, amount) {
    if (to.toLowerCase() === state.userAddress.toLowerCase()) {
        updateStatus('Token minted', 'success');
        logToConsole(`Tokens minted: ${amount} TKN to ${to}`);
        updateUserInfo();
    }
}

function handleTrustedIDPListChanged() {
    updateUserInfo();
}

// Utility functions
function updateStatus(message, type = 'info') {
    statusMessageElement.textContent = message;
    statusMessageElement.className = `alert alert-${type}`;
}

function logToConsole(message) {
    const timestamp = new Date().toLocaleTimeString();
    const logEntry = `[${timestamp}] ${message}`;
    logContainerElement.innerHTML += logEntry + '\n';
    logContainerElement.scrollTop = logContainerElement.scrollHeight;
}

function resetApp() {
    // Reset state
    state.provider = null;
    state.signer = null;
    state.tokenContract = null;
    state.userAddress = null;
    state.userStatus = {
        isVerified: false,
        isMintingAdmin: false,
        isIDPAdmin: false
    };
    state.tokenBalance = 0;
    
    // Reset UI
    userAddressElement.textContent = '';
    verificationStatusElement.textContent = 'Unknown';
    tokenBalanceElement.textContent = '0';
    
    // Show/hide cards
    connectWalletCard.classList.remove('hidden');
    walletInfoCard.classList.add('hidden');
    verifyIdentityCard.classList.add('hidden');
    transferTokensCard.classList.add('hidden');
    
    // Clear logs
    // logContainerElement.innerHTML = '';
}

// Initialize the app when the page loads
window.addEventListener('DOMContentLoaded', init); 