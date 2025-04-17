// App state
let tokenABI = [];
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
    customProvider: null
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
const dailyMintQuotaElement = document.getElementById('dailyMintQuota');

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
        networkSelectElement.addEventListener('change', handleNetworkChange);
    }
    
    // Initialize provider based on selected network
    initializeProvider();
    
    // Check if MetaMask is installed
    if (typeof window.ethereum === 'undefined') {
        updateStatus('MetaMask is not installed. Please install MetaMask.', 'danger');
    } else {
        // Add event listener for account changes
        window.ethereum.on('accountsChanged', handleAccountsChanged);
    }

    // Try to load the full ABI from the JSON file if available
    try {
        const response = await fetch('./contract-abi.json');
        tokenABI = await response.json();
        logToConsole('ABI loaded successfully');
    } catch (error) {
        logToConsole('Error loading ABI: ' + error.message);
        updateStatus('Error loading ABI: ' + error.message, 'danger');
    }

    // Add event listeners
    connectWalletBtn.addEventListener('click', connectWallet);
    verifyIdentityBtn.addEventListener('click', verifyIdentity);
    transferTokensBtn.addEventListener('click', transferTokens);
    mintTokensBtn.addEventListener('click', mintTokens);
    addTrustedIDPBtn.addEventListener('click', addTrustedIDP);
    removeTrustedIDPBtn.addEventListener('click', removeTrustedIDP);

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
    // TODO check when on sepolia testnet
    if (state.currentNetwork === 'anvil') {
        state.customProvider = new ethers.providers.JsonRpcProvider(networkConfig.rpcUrl);
        logToConsole(`Connected to local Anvil network at ${networkConfig.rpcUrl}`);
    }
}

function handleNetworkChange(event) {
    state.currentNetwork = event.target.value;
    logToConsole(`Network changed to: ${state.currentNetwork}`);
    resetApp();
    initializeProvider();
}

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
            
            // Get user verification status, roles and balance
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
        // Get user verification status, roles and balance
        const userStatusData = await state.tokenContract.userStatus(state.userAddress);
        state.userStatus = {
            isVerified: userStatusData[0],
            isMintingAdmin: userStatusData[1],
            isIDPAdmin: userStatusData[2]
        };
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
            const dailyMintQuota = await state.tokenContract.getDailyMintQuota();
            dailyMintQuotaElement.textContent = `${dailyMintQuota[0]}/${dailyMintQuota[1]}`;
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
        const recipientAddress = document.getElementById('transferRecipientAddress').value;
        const amount = document.getElementById('transferTokenAmount').value;
        
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

// Mint tokens
async function mintTokens() {
    if (!state.tokenContract) return;
    
    try {
        const recipientAddress = document.getElementById('mintRecipientAddress').value;
        const amount = document.getElementById('mintTokenAmount').value;
        
        if (!recipientAddress || !amount) {
            updateStatus('Please provide both recipient address and amount', 'warning');
            return;
        }
        
        updateStatus('Minting tokens...', 'info');
        
        // Call the smart contract function
        const tx = await state.tokenContract.mint(recipientAddress, amount);
        logToConsole('Transaction sent: ' + tx.hash);
        
        updateStatus('Mint transaction submitted. Waiting for confirmation...', 'info');
        
        // Wait for the transaction to be mined
        await tx.wait();
        
        // Update user info
        await updateUserInfo();
        
        updateStatus('Token minting successful!', 'success');
    } catch (error) {
        updateStatus('Failed to mint tokens: ' + error.message, 'danger');
        logToConsole('Error: ' + error.message);
    }
}

// Add trusted IDP
async function addTrustedIDP() {
    if (!state.tokenContract) return;
    
    try {
        const idpAddress = document.getElementById('idpAddress').value;
        
        if (!idpAddress) {
            updateStatus('Please provide an IDP address', 'warning');
            return;
        }
        
        updateStatus('Adding trusted IDP...', 'info');
        
        // Call the smart contract function
        const tx = await state.tokenContract.addTrustedIDP(idpAddress);
        logToConsole('Transaction sent: ' + tx.hash);
        
        updateStatus('Trusted IDP added. Waiting for confirmation...', 'info');
        
        // Wait for the transaction to be mined
        await tx.wait();
        
        // Update user info
        await updateUserInfo();
        
        updateStatus('Trusted IDP added successfully!', 'success');
    } catch (error) {
        updateStatus('Failed to add trusted IDP: ' + error.message, 'danger');
        logToConsole('Error: ' + error.message);
    }
}

async function removeTrustedIDP() {
    if (!state.tokenContract) return;
    
    try {
        const idpAddress = document.getElementById('idpAddress').value;
        
        if (!idpAddress) {
            updateStatus('Please provide an IDP address', 'warning');
            return;
        }
        
        updateStatus('Removing trusted IDP...', 'info');
        
        // Call the smart contract function
        const tx = await state.tokenContract.removeTrustedIDP(idpAddress);
        logToConsole('Transaction sent: ' + tx.hash);
        
        updateStatus('Trusted IDP removed. Waiting for confirmation...', 'info');
        
        // Wait for the transaction to be mined
        await tx.wait();
        
        // Update user info
        await updateUserInfo();
        
        updateStatus('Trusted IDP removed successfully!', 'success');
    } catch (error) {
        updateStatus('Failed to remove trusted IDP: ' + error.message, 'danger');
        logToConsole('Error: ' + error.message);
    }
}

// Event handlers
function handleAccountsChanged(accounts) {
    if (accounts.length === 0) {
        // User disconnected the wallet
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
        logToConsole(`Tokens transferred: ${amount} TKN from ${from} to ${to}`);
        updateUserInfo();
    }
}

function handleTokensMinted(minter, to, amount) {
    if (to.toLowerCase() === state.userAddress.toLowerCase()) {
        logToConsole(`Tokens minted: Address ${minter} minted ${amount} TKN to ${to}`);
        updateUserInfo();
    } else if (state.userStatus.isMintingAdmin) {
        logToConsole(`Tokens minted: Address ${minter} minted ${amount} TKN to ${to}`);
        updateUserInfo();  // Update the daily mint quota
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