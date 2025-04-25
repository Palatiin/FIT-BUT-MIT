const fs = require('fs');
const path = require('path');

// Foundry typically outputs compiled contracts to the out directory
const contractPath = path.join(__dirname, '..', 'out', 'Token.sol', 'Token.json');

try {
  // Read the compiled contract JSON
  const contractJson = JSON.parse(fs.readFileSync(contractPath, 'utf8'));
  
  // Extract the ABI
  const abi = contractJson.abi;
  
  // Write the ABI to a separate file
  fs.writeFileSync(
    path.join(__dirname, '..', 'public', 'contract-abi.json'),
    JSON.stringify(abi, null, 2)
  );
  
  console.log('ABI extracted and saved to public/contract-abi.json');
} catch (error) {
  console.error('Error extracting ABI:', error.message);
  console.error('Make sure the contract is compiled with Foundry (forge build)');
} 