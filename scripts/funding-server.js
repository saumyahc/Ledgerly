/**
 * Simple Express server for wallet funding
 * =======================================
 * 
 * This creates a local API endpoint that Flutter can call to fund wallets.
 * 
 * Setup:
 * npm install express cors dotenv
 * node scripts/funding-server.js
 * 
 * Usage from Flutter:
 * POST http://localhost:3000/api/fund-wallet
 * Body: {"address": "0x...", "amount": 2.5}
 */

const express = require('express');
const cors = require('cors');
const AccountFunder = require('./fund-accounts');
require('dotenv').config();

const app = express();
const PORT = process.env.FUNDING_SERVER_PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Initialize the account funder
let funder;

async function initializeFunder() {
    try {
        funder = new AccountFunder();
        const connected = await funder.checkConnection();
        
        if (!connected) {
            console.error('❌ Failed to connect to blockchain network');
            process.exit(1);
        }
        
        console.log('✅ Account funder initialized successfully');
    } catch (error) {
        console.error('❌ Failed to initialize account funder:', error.message);
        process.exit(1);
    }
}

// API Routes

/**
 * Fund a wallet address
 * POST /api/fund-wallet
 * Body: { address: string, amount?: number }
 */
app.post('/api/fund-wallet', async (req, res) => {
    try {
        const { address, amount = 1 } = req.body;
        
        // Validation
        if (!address) {
            return res.status(400).json({
                success: false,
                message: 'Wallet address is required'
            });
        }
        
        if (amount <= 0 || amount > 10) {
            return res.status(400).json({
                success: false,
                message: 'Amount must be between 0 and 10 ETH'
            });
        }
        
        // Check if local development mode
        if (process.env.NETWORK_MODE !== 'local') {
            return res.status(403).json({
                success: false,
                message: 'Funding only available in local development mode'
            });
        }
        
        console.log(`📤 Funding request: ${amount} ETH to ${address}`);
        
        // Fund the account
        const result = await funder.fundAccount(address, amount);
        
        if (result.success) {
            res.json({
                success: true,
                message: `Successfully funded ${address} with ${amount} ETH`,
                transactionHash: result.transactionHash,
                amount: result.amountEth,
                balanceBefore: result.balanceBefore,
                balanceAfter: result.balanceAfter,
                newBalance: result.balanceAfter
            });
        } else {
            res.status(500).json({
                success: false,
                message: result.error || 'Funding failed'
            });
        }
        
    } catch (error) {
        console.error('❌ Funding error:', error.message);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * Get funding information
 * GET /api/funding-info
 */
app.get('/api/funding-info', async (req, res) => {
    try {
        const isLocal = process.env.NETWORK_MODE === 'local';
        
        let ganacheAccounts = [];
        if (isLocal && funder) {
            // Get balances of Ganache accounts
            try {
                for (let i = 0; i < 3; i++) { // Show first 3 accounts
                    const account = funder.constructor.GANACHE_ACCOUNTS?.[i];
                    if (account) {
                        const balance = await funder.getBalance(account.address);
                        ganacheAccounts.push({
                            address: account.address,
                            balance: parseFloat(balance)
                        });
                    }
                }
            } catch (error) {
                console.warn('Could not get Ganache account info:', error.message);
            }
        }
        
        res.json({
            available: isLocal,
            networkMode: process.env.NETWORK_MODE || 'unknown',
            maxAmountPerRequest: 10,
            description: isLocal 
                ? 'Free test ETH available from Ganache'
                : 'Funding only available in local development',
            ganacheAccounts: ganacheAccounts
        });
        
    } catch (error) {
        console.error('❌ Info error:', error.message);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * Health check
 * GET /api/health
 */
app.get('/api/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        networkMode: process.env.NETWORK_MODE || 'unknown',
        fundingAvailable: process.env.NETWORK_MODE === 'local'
    });
});

// Error handling middleware
app.use((error, req, res, next) => {
    console.error('❌ Server error:', error.message);
    res.status(500).json({
        success: false,
        message: 'Internal server error'
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Endpoint not found'
    });
});

// Start server
async function startServer() {
    console.log('🚀 Starting funding server...');
    
    // Initialize funder first
    await initializeFunder();
    
    app.listen(PORT, () => {
        console.log(`💰 Funding server running on http://localhost:${PORT}`);
        console.log(`🌐 Network mode: ${process.env.NETWORK_MODE || 'unknown'}`);
        console.log('\\n📖 Available endpoints:');
        console.log(`   POST http://localhost:${PORT}/api/fund-wallet`);
        console.log(`   GET  http://localhost:${PORT}/api/funding-info`);
        console.log(`   GET  http://localhost:${PORT}/api/health`);
        console.log('\\n💡 Usage from Flutter:');
        console.log('   Use FundingService to request test ETH');
        console.log('\\n🛑 To stop: Ctrl+C');
    });
}

// Handle graceful shutdown
process.on('SIGINT', () => {
    console.log('\\n🛑 Shutting down funding server...');
    process.exit(0);
});

// Start the server
if (require.main === module) {
    startServer().catch(error => {
        console.error('❌ Failed to start server:', error.message);
        process.exit(1);
    });
}

module.exports = app;