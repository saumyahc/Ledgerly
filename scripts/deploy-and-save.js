const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const fetch = require('node-fetch');

class ContractDeploymentPipeline {
    constructor() {
        this.contractName = 'EmailPaymentRegistry';
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
            
            // Deploy to the configured network
            const network = this.getTargetNetwork();
            console.log(`🌐 Deploying to network: ${network}`);
            
            execSync(`truffle migrate --reset --network ${network}`, { stdio: 'inherit' });
            
            console.log('✅ Contract deployed successfully!');
            return true;
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
        
        const contractPath = path.join(this.buildPath, `${this.contractName}.json`);
        
        if (!fs.existsSync(contractPath)) {
            throw new Error(`Contract artifact not found: ${contractPath}`);
        }
        
        const artifact = JSON.parse(fs.readFileSync(contractPath, 'utf8'));
        const networks = Object.keys(artifact.networks);
        
        if (networks.length === 0) {
            throw new Error('No deployment found in contract artifact');
        }
        
        // Get the latest deployment
        const latestNetworkId = networks.sort((a, b) => parseInt(b) - parseInt(a))[0];
        const deployment = artifact.networks[latestNetworkId];
        
        const contractInfo = {
            contract_name: this.contractName,
            contract_address: deployment.address,
            chain_id: parseInt(latestNetworkId),
            abi: JSON.stringify(artifact.abi),
            deployment_tx: deployment.transactionHash,
            deployed_at: new Date().toISOString(),
            network_mode: this.config.NETWORK_MODE || 'local',
            version: this.generateVersion()
        };
        
        console.log('📄 Contract Information:');
        console.log(`   Name: ${contractInfo.contract_name}`);
        console.log(`   Address: ${contractInfo.contract_address}`);
        console.log(`   Chain ID: ${contractInfo.chain_id}`);
        console.log(`   Transaction: ${contractInfo.deployment_tx}`);
        console.log(`   Version: ${contractInfo.version}`);
        
        return contractInfo;
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
    
    async saveToBackend(contractInfo) {
        console.log('💾 Saving contract info to backend...');
        
        try {
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
                console.log('✅ Contract info saved to backend successfully!');
                console.log(`   Contract ID: ${result.contract_id || 'N/A'}`);
            } else {
                throw new Error(result.error || 'Unknown backend error');
            }
            
            return result;
        } catch (error) {
            console.error('❌ Failed to save to backend:', error.message);
            throw error;
        }
    }
    
    saveToLocal(contractInfo) {
        console.log('💾 Saving contract info locally...');
        
        const outputDir = path.join(__dirname, '..', 'deployments');
        if (!fs.existsSync(outputDir)) {
            fs.mkdirSync(outputDir, { recursive: true });
        }
        
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const fileName = `${this.contractName}-${timestamp}.json`;
        const filePath = path.join(outputDir, fileName);
        
        fs.writeFileSync(filePath, JSON.stringify(contractInfo, null, 2));
        
        const latestPath = path.join(outputDir, `${this.contractName}-latest.json`);
        fs.writeFileSync(latestPath, JSON.stringify(contractInfo, null, 2));
        
        console.log(`✅ Contract info saved locally:`);
        console.log(`   Full: ${filePath}`);
        console.log(`   Latest: ${latestPath}`);
    }
    
    updateFlutterConfig(contractInfo) {
        console.log('📱 Updating Flutter configuration...');
        
        const configPath = path.join(__dirname, '..', 'lib', 'contract_config.dart');
        
        const dartConfig = `
// GENERATED FILE - DO NOT EDIT MANUALLY
// Generated at: ${new Date().toISOString()}
// Contract Version: ${contractInfo.version}

class ContractConfig {
  static const String contractName = '${contractInfo.contract_name}';
  static const String contractAddress = '${contractInfo.contract_address}';
  static const int chainId = ${contractInfo.chain_id};
  static const String deploymentTx = '${contractInfo.deployment_tx}';
  static const String version = '${contractInfo.version}';
  static const String networkMode = '${contractInfo.network_mode}';
  
  static const String abi = '''${contractInfo.abi}''';
  
  // Deployment metadata
  static const String deployedAt = '${contractInfo.deployed_at}';
  static const bool isMainnet = ${contractInfo.chain_id === 1};
  static const bool isTestnet = ${contractInfo.chain_id !== 1 && contractInfo.chain_id !== 5777 && contractInfo.chain_id !== 1337};
  static const bool isLocal = ${contractInfo.chain_id === 5777 || contractInfo.chain_id === 1337};
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
            const contractInfo = this.extractContractInfo();
            
            // Step 4: Fund contract faucet (for local development)
            await this.fundContractFaucet(contractInfo);
            
            // Step 5: Save to backend
            await this.saveToBackend(contractInfo);
            
            // Step 6: Save locally
            this.saveToLocal(contractInfo);
            
            // Step 7: Update Flutter config
            this.updateFlutterConfig(contractInfo);
            
            console.log('\n🎉 Deployment pipeline completed successfully!');
            console.log('\n📋 Summary:');
            console.log(`   Contract: ${contractInfo.contract_address}`);
            console.log(`   Network: ${this.getTargetNetwork()}`);
            console.log(`   Version: ${contractInfo.version}`);
            console.log('\n🚀 Your contract is ready to use!');
            
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