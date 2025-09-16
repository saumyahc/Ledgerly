const { spawn } = require('child_process');
const fs = require('fs');

console.log('🚀 Starting persistent Ganache...');

// Check if ganache-cli is installed
try {
    require.resolve('ganache-cli/cli');
} catch (e) {
    console.error('❌ ganache-cli not found. Installing...');
    const { execSync } = require('child_process');
    try {
        execSync('npm install ganache-cli --save-dev', { stdio: 'inherit' });
        console.log('✅ ganache-cli installed successfully');
    } catch (installError) {
        console.error('❌ Failed to install ganache-cli:', installError.message);
        process.exit(1);
    }
}

const ganacheProcess = spawn('npx', [
    'ganache-cli',
    '--port', '8545',
    '--deterministic',
    '--accounts', '10',
    '--defaultBalanceEther', '100',
    '--gasLimit', '8000000',
    '--gasPrice', '20000000000',
    '--db', './ganache-db', // Persistent database
    '--networkId', '5777',
    '--host', '0.0.0.0'
], {
    stdio: ['ignore', 'pipe', 'pipe'],
    shell: true // Important for Windows
});

// Wait for the process to start and get PID
ganacheProcess.on('spawn', () => {
    console.log(`✅ Ganache process started with PID: ${ganacheProcess.pid}`);
    
    // Save PID for later cleanup
    if (ganacheProcess.pid) {
        fs.writeFileSync('.ganache-pid', ganacheProcess.pid.toString());
        console.log('💾 PID saved to .ganache-pid file');
    }
});

ganacheProcess.on('error', (error) => {
    console.error('❌ Failed to start Ganache:', error.message);
    
    // Try alternative command for Windows
    console.log('🔄 Trying alternative startup method...');
    startGanacheAlternative();
});

ganacheProcess.stdout.on('data', (data) => {
    const output = data.toString();
    console.log(output);
    
    // Check if Ganache is ready
    if (output.includes('Listening on')) {
        console.log('🌐 Ganache is ready and listening!');
        console.log('📊 Available accounts and private keys shown above');
        console.log('💡 Press Ctrl+C to stop Ganache');
    }
});

ganacheProcess.stderr.on('data', (data) => {
    console.error('Ganache Error:', data.toString());
});

ganacheProcess.on('exit', (code) => {
    console.log(`\n🛑 Ganache exited with code ${code}`);
    if (fs.existsSync('.ganache-pid')) {
        fs.unlinkSync('.ganache-pid');
        console.log('🗑️ Cleaned up PID file');
    }
});

// Alternative startup method for Windows
function startGanacheAlternative() {
    const { exec } = require('child_process');
    
    const command = 'npx ganache-cli --port 8545 --deterministic --accounts 10 --defaultBalanceEther 100 --gasLimit 8000000 --gasPrice 20000000000 --db ./ganache-db --networkId 5777 --host 0.0.0.0';
    
    const altProcess = exec(command, (error, stdout, stderr) => {
        if (error) {
            console.error('❌ Alternative method also failed:', error.message);
            console.log('\n💡 Manual installation steps:');
            console.log('1. npm install -g ganache-cli');
            console.log('2. ganache-cli --port 8545 --deterministic --accounts 10 --defaultBalanceEther 100 --db ./ganache-db --networkId 5777');
            process.exit(1);
        }
    });
    
    if (altProcess.pid) {
        fs.writeFileSync('.ganache-pid', altProcess.pid.toString());
        console.log(`✅ Alternative Ganache started with PID: ${altProcess.pid}`);
    }
    
    altProcess.stdout.on('data', (data) => {
        console.log(data.toString());
    });
    
    altProcess.stderr.on('data', (data) => {
        console.error(data.toString());
    });
}

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🛑 Received interrupt signal...');
    
    if (ganacheProcess && ganacheProcess.pid) {
        console.log('🛑 Stopping Ganache...');
        ganacheProcess.kill('SIGTERM');
    }
    
    if (fs.existsSync('.ganache-pid')) {
        fs.unlinkSync('.ganache-pid');
    }
    
    console.log('👋 Goodbye!');
    process.exit(0);
});

process.on('SIGTERM', () => {
    console.log('\n🛑 Received terminate signal...');
    if (ganacheProcess && ganacheProcess.pid) {
        ganacheProcess.kill('SIGTERM');
    }
    process.exit(0);
});