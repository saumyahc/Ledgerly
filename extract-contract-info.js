const fs = require('fs');
const path = require('path');

// Read the contract artifact
const contractPath = path.join(__dirname, 'build', 'contracts', 'EmailPaymentRegistry.json');
const contractArtifact = JSON.parse(fs.readFileSync(contractPath, 'utf8'));

// Extract deployment information
const networkId = '5777'; // Local development network
const deployment = contractArtifact.networks[networkId];

if (!deployment) {
    console.error('Contract not deployed to local network');
    process.exit(1);
}

const contractData = {
    contract_name: 'EmailPaymentRegistry',
    contract_address: deployment.address,
    chain_id: parseInt(networkId),
    abi: JSON.stringify(contractArtifact.abi),
    deployment_tx: deployment.transactionHash
};

console.log('📋 Contract Deployment Details:');
console.log('================================');
console.log(`Contract Name: ${contractData.contract_name}`);
console.log(`Contract Address: ${contractData.contract_address}`);
console.log(`Chain ID: ${contractData.chain_id}`);
console.log(`Transaction Hash: ${contractData.deployment_tx}`);
console.log('');

// Save to JSON file for easy access
const outputFile = path.join(__dirname, 'contract-deployment.json');
fs.writeFileSync(outputFile, JSON.stringify(contractData, null, 2));
console.log(`✅ Contract details saved to: ${outputFile}`);

// Also create a script for backend API call
const backendScript = `
// Script to save contract to backend database
// Run this in a browser console or use curl/postman

const contractData = ${JSON.stringify(contractData, null, 2)};

fetch('https://ledgerly.hivizstudios.com/backend_example/save_contract.php', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json'
    },
    body: JSON.stringify(contractData)
})
.then(response => response.json())
.then(data => console.log('Backend response:', data))
.catch(error => console.error('Error:', error));
`;

fs.writeFileSync(path.join(__dirname, 'save-to-backend.js'), backendScript);
console.log('📤 Backend script saved to: save-to-backend.js');
console.log('');
console.log('🚀 Next Steps:');
console.log('1. Update your Flutter app to use LOCAL_RPC_URL from .env.local');
console.log('2. Run your Flutter app to test wallet creation');
console.log('3. Test email registration with the contract');
console.log('4. Try sending payments between test accounts');
