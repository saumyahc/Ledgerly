const { exec } = require('child_process');
const fs = require('fs');

console.log('🚀 Starting Ganache for Windows...');

// Direct command execution using new Ganache v7 with correct arguments
const command = `npx ganache --server.port 8545 --wallet.deterministic --wallet.totalAccounts 10 --wallet.defaultBalance 100 --miner.blockGasLimit 8000000 --miner.defaultGasPrice 20000000000 --database.dbPath ./ganache-db --chain.networkId 5777 --chain.chainId 5777 --server.host 0.0.0.0`;

console.log('📋 Command:', command);

const ganacheProcess = exec(command, {
    maxBuffer: 1024 * 1024 * 10 // 10MB buffer
});

// Handle process startup
setTimeout(() => {
    if (ganacheProcess.pid) {
        fs.writeFileSync('.ganache-pid', ganacheProcess.pid.toString());
        console.log(`✅ Ganache started with PID: ${ganacheProcess.pid}`);
    }
}, 1000);

ganacheProcess.stdout.on('data', (data) => {
    console.log(data.toString());
});

ganacheProcess.stderr.on('data', (data) => {
    console.error('Error:', data.toString());
});

ganacheProcess.on('exit', (code) => {
    console.log(`\n🛑 Ganache exited with code ${code}`);
    if (fs.existsSync('.ganache-pid')) {
        fs.unlinkSync('.ganache-pid');
    }
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🛑 Stopping Ganache...');
    ganacheProcess.kill();
    process.exit(0);
});