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
  
  // Sample user addresses to verify (in a real app, these would come from your verification process)
  const usersToVerify = [
    "0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf", // test user address 0 
    "0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF", // test user address 1
    "0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69"  // test user address 2
  ];
  
  // Create the verification data for each user
  const verificationData = [];
  
  for (const userAddress of usersToVerify) {
    // Current timestamp for verification
    const timestamp = Math.floor(Date.now() / 1000);
    
    // Create the message string exactly as the smart contract does
    const message = `User with address ${userAddress} has verified their identity at ${timestamp}`;
    
    // Hash the message (ethers v6 uses keccak256 and solidityPacked)
    const messageHash = ethers.keccak256(
      ethers.solidityPacked(
        ['string', 'address', 'string', 'uint256'],
        ['User with address ', userAddress, ' has verified their identity at ', timestamp]
      )
    );
    
    // Sign the message hash
    const signature = await idpWallet.signMessage(ethers.getBytes(messageHash));
    
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
  const messageHash = ethers.keccak256(
    ethers.solidityPacked(
      ['string', 'address', 'string', 'uint256'],
      ['User with address ', userData.userAddress, ' has verified their identity at ', userData.timestamp]
    )
  );
  
  // Convert to Ethereum signed message hash
  const ethSignedMessageHash = ethers.hashMessage(ethers.getBytes(messageHash));
  
  // Recover signer from signature
  const recoveredSigner = ethers.recoverAddress(ethSignedMessageHash, userData.signature);
  
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