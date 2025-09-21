/**
 * MetaMask Contract Deployment Guide
 * ==================================
 * 
 * This file provides instructions for deploying smart contracts using MetaMask.
 * Follow these steps to deploy your EmailPaymentRegistry contract:
 * 
 * 1. Prerequisites:
 * ----------------
 * - Install Node.js and npm
 * - Install Truffle: npm install -g truffle
 * - Install Solidity compiler: npm install -g solc
 * 
 * 2. Configure your Network:
 * -------------------------
 * - Update truffle-config.js with appropriate network configurations
 * - For MetaMask integration, configure the network to use a provider like Infura
 * 
 * 3. Generate Contract Artifacts:
 * -----------------------------
 * - Run: truffle compile
 * - This generates the ABI and bytecode in the build/contracts directory
 * 
 * 4. Prepare Contract Assets for Flutter:
 * ------------------------------------
 * - Create a contracts directory in your Flutter assets folder:
 *   mkdir -p assets/contracts
 * 
 * - Extract the ABI and bytecode into a JSON file:
 *   node extract-contract-data.js
 * 
 * 5. Deploy Using MetaMask (In-App):
 * --------------------------------
 * - Use the Contract Deployment page in the Flutter app
 * - Connect your MetaMask wallet
 * - Click "Deploy Contract"
 * - Confirm the transaction in MetaMask
 * 
 * 6. Manual Deployment Option:
 * -------------------------
 * - Use Remix IDE (https://remix.ethereum.org/)
 * - Copy your contract code
 * - Compile using Solidity compiler
 * - Deploy using "Injected Web3" environment with MetaMask
 * - Save the deployed contract address
 * 
 * 7. Update Your App:
 * ----------------
 * - Update constants.dart with the deployed contract address
 * - Restart the app to use the deployed contract
 */

const fs = require('fs');
const path = require('path');

// Function to extract ABI and bytecode from Truffle artifacts
function extractContractData() {
  try {
    // Path to the Truffle artifact
    const artifactPath = path.join(__dirname, 'build/contracts/EmailPaymentRegistry.json');
    
    // Read the artifact file
    const artifact = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
    
    // Extract the needed data
    const contractData = {
      abi: artifact.abi,
      bytecode: artifact.bytecode,
    };
    
    // Create the assets directory if it doesn't exist
    const assetsDir = path.join(__dirname, 'assets/contracts');
    if (!fs.existsSync(assetsDir)) {
      fs.mkdirSync(assetsDir, { recursive: true });
    }
    
    // Write the data to a file in the assets directory
    const outputPath = path.join(assetsDir, 'EmailPaymentRegistry.json');
    fs.writeFileSync(outputPath, JSON.stringify(contractData, null, 2));
    
    console.log(`Contract data extracted successfully to ${outputPath}`);
  } catch (error) {
    console.error('Error extracting contract data:', error);
  }
}

// Run the extraction function
extractContractData();
