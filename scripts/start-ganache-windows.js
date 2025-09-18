const { exec } = require('child_process');
const fs = require('fs');

console.log('🚀 Starting Ganache for Windows...');

// Direct command execution
const command = `npx ganache-cli --port 8545 --deterministic --accounts 10 --defaultBalanceEther 100 --gasLimit 8000000 --gasPrice 20000000000 --db ./ganache-db --networkId 5777 --host 0.0.0.0`;

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