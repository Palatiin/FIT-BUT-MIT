// Generate random IDP - private key + address

const ethers = require('ethers');

const idpWallet = ethers.Wallet.createRandom();

console.log(`Private Key: ${idpWallet.privateKey}`);
console.log(`Address: ${idpWallet.address}`);
