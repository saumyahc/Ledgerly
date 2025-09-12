@echo off
REM Ledgerly Quick Setup Script for Windows
REM This script helps set up the local development environment

echo 🚀 Ledgerly Local Development Setup
echo ==================================

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed. Please install it from https://nodejs.org/
    pause
    exit /b 1
)

echo ✅ Node.js is installed
node --version

REM Install global dependencies
echo 📦 Installing global dependencies...
npm install -g truffle ganache-cli

REM Install project dependencies
echo 📦 Installing project dependencies...
call npm install

REM Compile contracts
echo 🔨 Compiling smart contracts...
call truffle compile

REM Deploy contracts (assumes Ganache is running)
echo 🚀 Deploying contracts to local network...
echo    Make sure Ganache is running on port 7545
call truffle migrate --network development

echo.
echo ✅ Setup Complete!
echo ==================
echo.
echo 📋 Next Steps:
echo 1. Start Ganache GUI or run: ganache-cli --accounts 10 --host 0.0.0.0 --port 7545 --deterministic
echo 2. Start your PHP backend server (XAMPP/WAMP)
echo 3. Import database schema: mysql -u root -p ledgerly_db ^< backend_example\database_schema.sql
echo 4. Configure backend_example\.env with your database credentials
echo 5. Update Flutter app with the deployed contract address
echo 6. Run your Flutter app with: flutter run
echo.
echo 📄 For detailed instructions, see LEDGERLY_IMPLEMENTATION_STATUS.md
echo.
echo 🔗 Useful Commands:
echo    truffle console                    # Interact with contracts
echo    truffle migrate --reset           # Redeploy contracts
echo    ganache-cli --help               # Ganache options
echo.
pause
