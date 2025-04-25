// IDP data used for local testing:
// Private key: 0x19cfa6079c94c889a2b68223ec9a2e4170b7c977db7319c0e2cc7f82040297eb
// - Address: 0x3f176887Ac19bbCcA11052E79BcF1533BD7CFFf9

const ethers = require('ethers');
const fs = require('fs');

async function main() {
  // Get IDP private key from command line arguments
  const idpPrivateKey = process.argv[2];
  
  // Check if private key was provided
  if (!idpPrivateKey) {
    console.error('Please provide an IDP private key as an argument:');
    console.error('node scripts/simulate_idp.js <private_key>');
    process.exit(1);
  }
  
  // Create wallet from the provided private key
  const idpWallet = new ethers.Wallet(idpPrivateKey);
  console.log(`Using IDP Address: ${idpWallet.address}`);
  
  // Sample user addresses to verify
  const usersToVerify = [
    "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", // anvil test user address 0
    "0xfc5ba757d1508506198cff41309bc0e3a577895c", // my test metamask address
    "0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf", // anvil test user address 1
    "0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF", // anvil test user address 2
    "0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69"  // anvil test user address 3
  ];
  
  const verificationData = [];
  for (const userAddress of usersToVerify) {
    // Current timestamp for verification
    const timestamp = Math.floor(Date.now() / 1000);
    
    // Create the message string exactly as the smart contract does
    const message = `User with address ${userAddress} has verified their identity at ${timestamp}`;
    
    // Hash the message
    const messageHash = ethers.utils.keccak256(
      ethers.utils.solidityPack(
        ['string', 'address', 'string', 'uint256'],
        ['User with address ', userAddress, ' has verified their identity at ', timestamp]
      )
    );
    
    // Sign the message hash
    const messageArray = ethers.utils.arrayify(messageHash);
    const signature = await idpWallet.signMessage(messageArray);
    
    // Store verification data
    verificationData.push({
      userAddress,
      timestamp,
      signature,
      message
    });
    
    console.log(`\nVerified user: ${userAddress}`);
    console.log(`Timestamp: ${timestamp}`);
    console.log(`Message: ${message}`);
    console.log(`Signature: ${signature}`);
  }
  
  // Save verification data to file for later use
  fs.writeFileSync('idp_verification_data.json', JSON.stringify(verificationData, null, 2));
  console.log('\nVerification data saved to idp_verification_data.json');
  
  // Demonstration of signature verification (this simulates what the contract will do)
  console.log('\n--- Verification Demo ---');
  
  const userData = verificationData[0];
  
  // Create message hash as the contract would
  const messageHash = ethers.utils.keccak256(
    ethers.utils.solidityPack(
      ['string', 'address', 'string', 'uint256'],
      ['User with address ', userData.userAddress, ' has verified their identity at ', userData.timestamp]
    )
  );
  
  // Convert to Ethereum signed message hash
  const ethSignedMessageHash = ethers.utils.hashMessage(ethers.utils.arrayify(messageHash));
  
  // Recover signer from signature
  const recoveredSigner = ethers.utils.recoverAddress(ethSignedMessageHash, userData.signature);
  
  console.log(`IDP address: ${idpWallet.address}`);
  console.log(`Recovered signer address: ${recoveredSigner}`);
  console.log(`Signature verification: ${recoveredSigner === idpWallet.address ? 'SUCCESS' : 'FAILED'}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 