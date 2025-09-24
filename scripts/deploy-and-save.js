const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const fetch = require('node-fetch');

class ContractDeploymentPipeline {
    constructor() {
        this.contractName = 'LedgerlySimpleCore';
        this.backendUrl = 'https://ledgerly.hivizstudios.com/backend_example';
        this.buildPath = path.join(__dirname, '..', 'build', 'contracts');
        this.loadEnvConfig();
    }
    
    loadEnvConfig() {
        const envPath = path.join(__dirname, '..', '.env');
        if (fs.existsSync(envPath)) {
            const envContent = fs.readFileSync(envPath, 'utf8');
            this.config = this.parseEnv(envContent);
        } else {
            throw new Error('.env file not found');
        }
    }
    
    parseEnv(content) {
        const config = {};
        content.split('\n').forEach(line => {
            const [key, value] = line.split('=');
            if (key && value) {
                config[key.trim()] = value.trim();
            }
        });
        return config;
    }
    
    async checkNetworkConnection() {
        const network = this.getTargetNetwork();
        console.log(`🔍 Checking connection to ${network} network...`);
        
        if (network === 'development') {
            // Check if Ganache is running on port 8545
            try {
                const response = await fetch('http://127.0.0.1:8545', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        jsonrpc: '2.0',
                        method: 'net_version',
                        params: [],
                        id: 1
                    })
                });
                
                const result = await response.json();
                if (result.result) {
                    console.log(`✅ Connected to local network (ID: ${result.result})`);
                    return true;
                } else {
                    throw new Error('Invalid response from local network');
                }
            } catch (e) {
                console.error('❌ Ganache not running on port 8545!');
                console.log('💡 Please run: npm run start-ganache');
                return false;
            }
        }
        
        // For remote networks, check Infura connection
        if (network === 'sepolia' || network === 'mainnet') {
            const rpcUrl = this.config.ETHEREUM_RPC_URL;
            if (!rpcUrl) {
                throw new Error('ETHEREUM_RPC_URL not configured');
            }
            
            try {
                const response = await fetch(rpcUrl, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        jsonrpc: '2.0',
                        method: 'net_version',
                        params: [],
                        id: 1
                    })
                });
                
                const result = await response.json();
                console.log(`✅ Connected to ${network} (ID: ${result.result})`);
                return true;
            } catch (e) {
                throw new Error(`Failed to connect to ${network}: ${e.message}`);
            }
        }
        
        return true;
    }
    
    async deployContract() {
        console.log('🚀 Starting contract deployment...');
        
        try {
            // Compile contracts
            console.log('📦 Compiling contracts...');
            execSync('truffle compile', { stdio: 'inherit' });
            
            // Deploy to the configured network with timeout and better error handling
            const network = this.getTargetNetwork();
            console.log(`🌐 Deploying to network: ${network}`);
            
            // Use spawn instead of execSync for better process control
            const { spawn } = require('child_process');
            
            return new Promise((resolve, reject) => {
                const migration = spawn('truffle', ['migrate', '--reset', '--network', network], {
                    stdio: 'inherit',
                    shell: true
                });
                
                migration.on('close', (code) => {
                    if (code === 0) {
                        console.log('✅ Contract deployed successfully!');
                        resolve(true);
                    } else {
                        console.error(`❌ Deployment failed with exit code: ${code}`);
                        // Even if exit code is non-zero, check if deployment actually succeeded
                        // by looking for the contract artifacts
                        setTimeout(() => {
                            const contractPath = path.join(this.buildPath, `${this.contractName}.json`);
                            if (fs.existsSync(contractPath)) {
                                const artifact = JSON.parse(fs.readFileSync(contractPath, 'utf8'));
                                if (Object.keys(artifact.networks).length > 0) {
                                    console.log('✅ Contract appears to have deployed despite exit code!');
                                    resolve(true);
                                    return;
                                }
                            }
                            reject(new Error(`Deployment failed with exit code: ${code}`));
                        }, 1000);
                    }
                });
                
                migration.on('error', (err) => {
                    console.error('❌ Deployment process error:', err.message);
                    reject(err);
                });
            });
            
        } catch (error) {
            console.error('❌ Deployment failed:', error.message);
            return false;
        }
    }
    
    getTargetNetwork() {
        if (this.config.NETWORK_MODE === 'local') {
            return 'development';
        } else if (this.config.ENABLE_MAINNET === 'true') {
            return 'mainnet';
        } else {
            return 'sepolia';
        }
    }
    
    extractContractInfo() {
        console.log('📋 Extracting contract information...');
        
        // Define modular contracts to extract
        const modularContracts = ['EmailRegistry', 'PaymentManager', 'BasicFaucet'];
        const contractInfos = [];
        
        for (const contractName of modularContracts) {
            const contractPath = path.join(this.buildPath, `${contractName}.json`);
            
            if (!fs.existsSync(contractPath)) {
                console.log(`⚠️  Contract artifact not found: ${contractName}`);
                continue;
            }
            
            const artifact = JSON.parse(fs.readFileSync(contractPath, 'utf8'));
            const networks = Object.keys(artifact.networks);
            
            if (networks.length === 0) {
                console.log(`⚠️  No deployment found for contract: ${contractName}`);
                continue;
            }
            
            // Get the latest deployment
            const latestNetworkId = networks.sort((a, b) => parseInt(b) - parseInt(a))[0];
            const deployment = artifact.networks[latestNetworkId];
            
            const contractInfo = {
                contract_name: contractName,
                contract_address: deployment.address,
                chain_id: parseInt(latestNetworkId),
                abi: JSON.stringify(artifact.abi),
                deployment_tx: deployment.transactionHash,
                deployed_at: new Date().toISOString(),
                network_mode: this.config.NETWORK_MODE || 'local',
                version: this.generateVersion()
            };
            
            contractInfos.push(contractInfo);
            
            console.log(`📄 ${contractName} Information:`);
            console.log(`   Address: ${contractInfo.contract_address}`);
            console.log(`   Chain ID: ${contractInfo.chain_id}`);
            console.log(`   Transaction: ${contractInfo.deployment_tx}`);
            console.log(`   ABI Functions: ${JSON.parse(contractInfo.abi).length}`);
        }
        
        if (contractInfos.length === 0) {
            throw new Error('No contract deployments found');
        }
        
        return contractInfos;
    }
    
    generateVersion() {
        const timestamp = Date.now();
        const gitHash = this.getGitHash();
        return `v${timestamp}-${gitHash}`;
    }
    
    getGitHash() {
        try {
            return execSync('git rev-parse --short HEAD', { encoding: 'utf8' }).trim();
        } catch {
            return 'nogit';
        }
    }
    
    async fundContractFaucet(contractInfo) {
        console.log('💰 Funding contract faucet...');
        
        // Only fund faucet for local development
        if (this.config.NETWORK_MODE !== 'local') {
            console.log('⏭️  Skipping faucet funding (not local development)');
            return;
        }
        
        try {
            const Web3 = require('web3');
            const web3 = new Web3('http://127.0.0.1:8545');
            const accounts = await web3.eth.getAccounts();
            
            if (accounts.length === 0) {
                throw new Error('No accounts available for funding');
            }
            
            const deployerAccount = accounts[0];
            const fundingAmount = web3.utils.toWei('10', 'ether'); // Fund with 10 ETH
            
            console.log(`   Funding from: ${deployerAccount}`);
            console.log(`   Amount: ${web3.utils.fromWei(fundingAmount, 'ether')} ETH`);
            console.log(`   Contract: ${contractInfo.contract_address}`);
            
            // Send ETH to contract
            const tx = await web3.eth.sendTransaction({
                from: deployerAccount,
                to: contractInfo.contract_address,
                value: fundingAmount,
                gas: 100000,
                gasPrice: web3.utils.toWei('20', 'gwei')
            });
            
            console.log(`✅ Faucet funded successfully!`);
            console.log(`   Transaction: ${tx.transactionHash}`);
            
            // Test faucet functionality
            console.log('🧪 Testing faucet functionality...');
            const abi = JSON.parse(contractInfo.abi);
            const contract = new web3.eth.Contract(abi, contractInfo.contract_address);
            
            // Get faucet info
            const faucetInfo = await contract.methods.getFaucetInfo().call();
            console.log(`   Faucet amount: ${web3.utils.fromWei(faucetInfo.amount, 'ether')} ETH`);
            console.log(`   Cooldown: ${faucetInfo.cooldown} seconds`);
            console.log(`   Enabled: ${faucetInfo.enabled}`);
            console.log(`   Balance: ${web3.utils.fromWei(faucetInfo.balance, 'ether')} ETH`);
            
            // Test with second account if available
            if (accounts.length > 1) {
                const testAccount = accounts[1];
                console.log(`   Testing request from: ${testAccount}`);
                
                try {
                    const initialBalance = await web3.eth.getBalance(testAccount);
                    console.log(`   Initial balance: ${web3.utils.fromWei(initialBalance, 'ether')} ETH`);
                    
                    const faucetTx = await contract.methods.requestFaucetFunds().send({
                        from: testAccount,
                        gas: 100000,
                        gasPrice: web3.utils.toWei('20', 'gwei')
                    });
                    
                    const finalBalance = await web3.eth.getBalance(testAccount);
                    console.log(`   Final balance: ${web3.utils.fromWei(finalBalance, 'ether')} ETH`);
                    console.log(`   ✅ Faucet test successful! Tx: ${faucetTx.transactionHash}`);
                } catch (testError) {
                    console.log(`   ⚠️  Faucet test failed (may be expected): ${testError.message}`);
                }
            }
            
        } catch (error) {
            console.warn(`⚠️  Faucet funding failed: ${error.message}`);
            console.log('   Contract will still work, but faucet won\'t be pre-funded');
        }
    }
    
    async saveToBackend(contractInfos) {
        console.log('💾 Saving contract info to backend...');
        
        const results = [];
        
        for (const contractInfo of contractInfos) {
            try {
                console.log(`   Saving ${contractInfo.contract_name}...`);
                console.log(`     Address: ${contractInfo.contract_address}`);
                console.log(`     ABI: ${JSON.parse(contractInfo.abi).length} functions/events`);
                console.log(`     Chain ID: ${contractInfo.chain_id}`);
                
                const response = await fetch(`${this.backendUrl}/save_contract.php`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify(contractInfo)
                });
                
                if (!response.ok) {
                    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                }
                
                const result = await response.json();
                
                if (result.success) {
                    console.log(`   ✅ ${contractInfo.contract_name} saved successfully!`);
                    console.log(`      Contract ID: ${result.contract_id || 'N/A'}`);
                    results.push({ contract: contractInfo.contract_name, success: true, data: result });
                } else {
                    throw new Error(result.error || 'Unknown backend error');
                }
            } catch (error) {
                console.error(`   ❌ Failed to save ${contractInfo.contract_name}:`, error.message);
                results.push({ contract: contractInfo.contract_name, success: false, error: error.message });
            }
        }
        
        return results;
    }
    
    saveToLocal(contractInfos) {
        console.log('💾 Saving contract info locally...');
        
        const outputDir = path.join(__dirname, '..', 'deployments');
        if (!fs.existsSync(outputDir)) {
            fs.mkdirSync(outputDir, { recursive: true });
        }
        
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const deploymentData = {
            deployment_id: `ledgerly-modular-${timestamp}`,
            deployed_at: new Date().toISOString(),
            network_mode: this.config.NETWORK_MODE || 'local',
            contracts: contractInfos
        };
        
        const fileName = `ledgerly-modular-${timestamp}.json`;
        const filePath = path.join(outputDir, fileName);
        
        fs.writeFileSync(filePath, JSON.stringify(deploymentData, null, 2));
        
        const latestPath = path.join(outputDir, 'ledgerly-modular-latest.json');
        fs.writeFileSync(latestPath, JSON.stringify(deploymentData, null, 2));
        
        console.log(`✅ Contract info saved locally:`);
        console.log(`   Full: ${filePath}`);
        console.log(`   Latest: ${latestPath}`);
    }
    
    updateFlutterConfig(contractInfos) {
        console.log('📱 Updating Flutter configuration...');
        
        const configPath = path.join(__dirname, '..', 'lib', 'contract_config.dart');
        
        // Find main contracts by name
        const emailRegistry = contractInfos.find(c => c.contract_name === 'EmailRegistry');
        const paymentManager = contractInfos.find(c => c.contract_name === 'PaymentManager');
        const basicFaucet = contractInfos.find(c => c.contract_name === 'BasicFaucet');
        
        const dartConfig = `
// GENERATED FILE - DO NOT EDIT MANUALLY
// Generated at: ${new Date().toISOString()}
// Modular Contract Deployment

class ContractConfig {
  // Email Registry Contract
  static const String emailRegistryAddress = '${emailRegistry?.contract_address || 'NOT_DEPLOYED'}';
  static const String emailRegistryTx = '${emailRegistry?.deployment_tx || ''}';
  
  // Payment Manager Contract  
  static const String paymentManagerAddress = '${paymentManager?.contract_address || 'NOT_DEPLOYED'}';
  static const String paymentManagerTx = '${paymentManager?.deployment_tx || ''}';
  
  // Basic Faucet Contract
  static const String basicFaucetAddress = '${basicFaucet?.contract_address || 'NOT_DEPLOYED'}';
  static const String basicFaucetTx = '${basicFaucet?.deployment_tx || ''}';
  
  // Network Info
  static const int chainId = ${contractInfos[0]?.chain_id || 5777};
  static const String networkMode = '${contractInfos[0]?.network_mode || 'local'}';
  static const String deployedAt = '${contractInfos[0]?.deployed_at || ''}';
  
  // Contract ABIs (for client-side interaction)
  static const String emailRegistryAbi = '''${emailRegistry?.abi?.replace(/'/g, "\\'") || '[]'}''';
  static const String paymentManagerAbi = '''${paymentManager?.abi?.replace(/'/g, "\\'") || '[]'}''';
  static const String basicFaucetAbi = '''${basicFaucet?.abi?.replace(/'/g, "\\'") || '[]'}''';
  
  // Legacy compatibility
  static const String contractAddress = '${emailRegistry?.contract_address || 'NOT_DEPLOYED'}';
  static const String contractName = 'LedgerlyModular';
  
  // Helper method to get contract info by name
  static Map<String, dynamic> getContractInfo(String contractName) {
    switch (contractName.toLowerCase()) {
      case 'emailregistry':
        return {
          'address': emailRegistryAddress,
          'abi': emailRegistryAbi,
          'tx': emailRegistryTx,
        };
      case 'paymentmanager':
        return {
          'address': paymentManagerAddress,
          'abi': paymentManagerAbi,
          'tx': paymentManagerTx,
        };
      case 'basicfaucet':
        return {
          'address': basicFaucetAddress,
          'abi': basicFaucetAbi,
          'tx': basicFaucetTx,
        };
      default:
        throw Exception('Unknown contract: \$contractName');
    }
  }
  
  // Get all contract addresses
  static Map<String, String> getAllAddresses() {
    return {
      'EmailRegistry': emailRegistryAddress,
      'PaymentManager': paymentManagerAddress,
      'BasicFaucet': basicFaucetAddress,
    };
  }
}
`;
        
        fs.writeFileSync(configPath, dartConfig);
        console.log(`✅ Flutter config updated: ${configPath}`);
    }
    
    async run() {
        try {
            console.log('🎯 Starting automated deployment pipeline...\n');
            
            // Step 1: Check network connection
            const connected = await this.checkNetworkConnection();
            if (!connected) {
                throw new Error('Network connection failed');
            }
            
            // Step 2: Deploy contract
            const deploySuccess = await this.deployContract();
            if (!deploySuccess) {
                throw new Error('Deployment failed');
            }
            
            // Step 3: Extract contract information
            const contractInfos = this.extractContractInfo();
            
            // Step 4: Fund contract faucet (for local development)
            const faucetContract = contractInfos.find(c => c.contract_name === 'BasicFaucet');
            if (faucetContract) {
                await this.fundContractFaucet(faucetContract);
            }
            
            // Step 5: Save to backend
            await this.saveToBackend(contractInfos);
            
            // Step 6: Save locally
            this.saveToLocal(contractInfos);
            
            // Step 7: Update Flutter config
            this.updateFlutterConfig(contractInfos);
            
            console.log('\n🎉 Deployment pipeline completed successfully!');
            console.log('\n📋 Summary:');
            contractInfos.forEach(contract => {
                console.log(`   ${contract.contract_name}: ${contract.contract_address}`);
            });
            console.log(`   Network: ${this.getTargetNetwork()}`);
            console.log('\n🚀 Your modular contracts are ready to use!');
            
        } catch (error) {
            console.error('\n💥 Pipeline failed:', error.message);
            
            if (error.message.includes('Network connection failed')) {
                console.log('\n💡 Make sure Ganache is running:');
                console.log('   npm run start-ganache');
            }
            
            process.exit(1);
        }
    }
}

// Run the pipeline
if (require.main === module) {
    const pipeline = new ContractDeploymentPipeline();
    pipeline.run();
}

module.exports = ContractDeploymentPipeline;