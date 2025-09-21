const fs = require('fs');
const { execSync } = require('child_process');

console.log('🛑 Stopping Ganache...');

try {
    if (fs.existsSync('.ganache-pid')) {
        const pid = fs.readFileSync('.ganache-pid', 'utf8');
        
        // Kill the process
        if (process.platform === 'win32') {
            execSync(`taskkill /F /PID ${pid}`);
        } else {
            execSync(`kill ${pid}`);
        }
        
        fs.unlinkSync('.ganache-pid');
        console.log('✅ Ganache stopped successfully');
    } else {
        console.log('ℹ️ No running Ganache instance found');
    }
} catch (error) {
    console.error('❌ Error stopping Ganache:', error.message);
}