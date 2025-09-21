/**
 * Ganache Account Funding Script
 * =============================
 * 
 * This script funds user wallets from pre-funded Ganache accounts.
 * 
 * Usage:
 * node scripts/fund-accounts.js <user_wallet_address> [amount_in_eth]
 * 
 * Examples:
 * node scripts/fund-accounts.js 0x742d35cc6631c0532925a3b8d5c0b5d81c6a5b87 5
 * node scripts/fund-accounts.js 0x742d35cc6631c0532925a3b8d5c0b5d81c6a5b87   (defaults to 1 ETH)
 */

const Web3 = require('web3');
require('dotenv').config();

// Ganache default accounts (pre-funded with 100 ETH each)
const GANACHE_ACCOUNTS = [
    {
        address: '0x627306090abaB3A6e1400e9345bC60c78a8BEf57',
        privateKey: 'c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3'
    },
    {
        address: '0xf17f52151EbEF6C7334FAD080c5704D77216b732',
        privateKey: 'ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f'
    },
    {
        address: '0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef',
        privateKey: '0dbbe8e4ae425a6d2687f1a7e3ba17bc98c673636790f1b8ad91193c05875ef1'
    },
    {
        address: '0x821aEa9a577a9b44299B9c15c88cf3087F3b5544',
        privateKey: 'c88b703fb08cbea894b6aeff5a544fb92e78a18e19814cd85da83b71f772aa6c'
    },
    {
        address: '0x0d1d4e623D10F9FBA5Db95830F7d3839406C6AF2',
        privateKey: '388c684f0ba1ef5017716adb5d21a053ea8e90277d0868337519f97bede61418'
    }
];

class AccountFunder {
    constructor() {
        // Connect to Ganache
        const rpcUrl = process.env.NETWORK_MODE === 'local' 
            ? (process.env.LOCAL_RPC_URL || 'http://127.0.0.1:8545')
            : process.env.ETHEREUM_RPC_URL;
            
        this.web3 = new Web3(rpcUrl);
        this.funderAccount = GANACHE_ACCOUNTS[0]; // Use first account as funder
        
        console.log(`🔗 Connected to: ${rpcUrl}`);
        console.log(`💰 Funding from: ${this.funderAccount.address}`);
    }

    async checkConnection() {
        try {
            const chainId = await this.web3.eth.getChainId();
            const accounts = await this.web3.eth.getAccounts();
            
            console.log(`⛓️  Chain ID: ${chainId}`);
            console.log(`🏠 Available accounts: ${accounts.length}`);
            
            if (accounts.length === 0) {
                throw new Error('No accounts available. Make sure Ganache is running.');
            }
            
            return true;
        } catch (error) {
            console.error('❌ Connection failed:', error.message);
            return false;
        }
    }

    async getBalance(address) {
        const balanceWei = await this.web3.eth.getBalance(address);
        return this.web3.utils.fromWei(balanceWei, 'ether');
    }

    async fundAccount(recipientAddress, amountEth = 1) {
        try {
            console.log(`\\n🚀 Starting funding process...`);
            
            // Validate recipient address
            if (!this.web3.utils.isAddress(recipientAddress)) {
                throw new Error('Invalid recipient address');
            }

            // Check funder balance
            const funderBalance = await this.getBalance(this.funderAccount.address);
            console.log(`💳 Funder balance: ${funderBalance} ETH`);

            if (parseFloat(funderBalance) < amountEth) {
                throw new Error(`Insufficient funds. Funder has ${funderBalance} ETH, need ${amountEth} ETH`);
            }

            // Check recipient current balance
            const recipientBalanceBefore = await this.getBalance(recipientAddress);
            console.log(`📊 Recipient balance before: ${recipientBalanceBefore} ETH`);

            // Prepare transaction
            const amountWei = this.web3.utils.toWei(amountEth.toString(), 'ether');
            const gasPrice = await this.web3.eth.getGasPrice();
            const nonce = await this.web3.eth.getTransactionCount(this.funderAccount.address);

            const transaction = {
                from: this.funderAccount.address,
                to: recipientAddress,
                value: amountWei,
                gas: 21000,
                gasPrice: gasPrice,
                nonce: nonce
            };

            console.log(`📤 Sending ${amountEth} ETH to ${recipientAddress}...`);

            // Sign and send transaction
            const signedTx = await this.web3.eth.accounts.signTransaction(
                transaction, 
                this.funderAccount.privateKey
            );

            const receipt = await this.web3.eth.sendSignedTransaction(signedTx.rawTransaction);

            // Check final balance
            const recipientBalanceAfter = await this.getBalance(recipientAddress);

            console.log(`✅ Transaction successful!`);
            console.log(`🔗 Transaction hash: ${receipt.transactionHash}`);
            console.log(`📊 Recipient balance after: ${recipientBalanceAfter} ETH`);
            console.log(`💸 Amount transferred: ${amountEth} ETH`);

            return {
                success: true,
                transactionHash: receipt.transactionHash,
                amountEth: amountEth,
                recipientAddress: recipientAddress,
                balanceBefore: recipientBalanceBefore,
                balanceAfter: recipientBalanceAfter
            };

        } catch (error) {
            console.error('❌ Funding failed:', error.message);
            return {
                success: false,
                error: error.message
            };
        }
    }

    async fundMultipleAccounts(recipients, amountEth = 1) {
        console.log(`\\n💰 Funding ${recipients.length} accounts with ${amountEth} ETH each...`);
        
        const results = [];
        
        for (let i = 0; i < recipients.length; i++) {
            const recipient = recipients[i];
            console.log(`\\n[${i + 1}/${recipients.length}] Funding ${recipient}...`);
            
            const result = await this.fundAccount(recipient, amountEth);
            results.push(result);
            
            // Small delay between transactions
            if (i < recipients.length - 1) {
                await new Promise(resolve => setTimeout(resolve, 1000));
            }
        }
        
        return results;
    }

    async listGanacheAccounts() {
        console.log('\\n🏦 Pre-funded Ganache Accounts:');
        console.log('=====================================');
        
        for (let i = 0; i < GANACHE_ACCOUNTS.length; i++) {
            const account = GANACHE_ACCOUNTS[i];
            try {
                const balance = await this.getBalance(account.address);
                console.log(`[${i}] ${account.address} - ${balance} ETH`);
            } catch (error) {
                console.log(`[${i}] ${account.address} - Error getting balance`);
            }
        }
    }
}

// CLI Usage
async function main() {
    const funder = new AccountFunder();
    
    // Check connection first
    const connected = await funder.checkConnection();
    if (!connected) {
        process.exit(1);
    }

    const args = process.argv.slice(2);
    
    if (args.length === 0) {
        console.log('\\n📖 Usage Examples:');
        console.log('==================');
        console.log('Fund single account:');
        console.log('node scripts/fund-accounts.js 0x742d35cc6631c0532925a3b8d5c0b5d81c6a5b87 5');
        console.log('\\nList Ganache accounts:');
        console.log('node scripts/fund-accounts.js --list');
        console.log('\\nFund multiple accounts:');
        console.log('node scripts/fund-accounts.js --multiple 0xaddr1,0xaddr2,0xaddr3 2');
        
        await funder.listGanacheAccounts();
        return;
    }

    // List accounts
    if (args[0] === '--list') {
        await funder.listGanacheAccounts();
        return;
    }

    // Fund multiple accounts
    if (args[0] === '--multiple') {
        const addresses = args[1] ? args[1].split(',') : [];
        const amount = args[2] ? parseFloat(args[2]) : 1;
        
        if (addresses.length === 0) {
            console.error('❌ Please provide comma-separated addresses');
            return;
        }
        
        const results = await funder.fundMultipleAccounts(addresses, amount);
        
        console.log('\\n📊 Summary:');
        console.log('===========');
        const successful = results.filter(r => r.success).length;
        console.log(`✅ Successful: ${successful}/${results.length}`);
        
        return;
    }

    // Fund single account
    const recipientAddress = args[0];
    const amount = args[1] ? parseFloat(args[1]) : 1;

    if (isNaN(amount) || amount <= 0) {
        console.error('❌ Please provide a valid amount (positive number)');
        return;
    }

    const result = await funder.fundAccount(recipientAddress, amount);
    
    if (result.success) {
        console.log('\\n🎉 Funding completed successfully!');
    } else {
        console.log('\\n💥 Funding failed!');
        process.exit(1);
    }
}

// Export for use in other scripts
module.exports = AccountFunder;

// Run if called directly
if (require.main === module) {
    main().catch(console.error);
}