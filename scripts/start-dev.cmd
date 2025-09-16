@echo off
title Ledgerly Development Environment

echo 🚀 Starting Ledgerly Development Environment
echo =============================================

REM Check if node is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Node.js is not installed. Please install Node.js first.
    pause
    exit /b 1
)

REM Check if ganache is running
echo 🔍 Checking Ganache connection...
curl -s -X POST -H "Content-Type: application/json" -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_accounts\",\"params\":[],\"id\":1}" http://127.0.0.1:8545 >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Ganache is not running. Please start Ganache first:
    echo    1. Open Ganache GUI
    echo    2. Create/Open workspace on port 8545
    echo    3. Run this script again
    pause
    exit /b 1
)

echo ✅ Ganache is running on port 8545

REM Install dependencies if needed
if not exist "node_modules" (
    echo 📦 Installing Node.js dependencies...
    call npm install
)

REM Start the funding server
echo 💰 Starting funding server...
start "Funding Server" cmd /k "node scripts/funding-server.js"

timeout /t 3 /nobreak >nul

echo.
echo 🎉 Development environment is ready!
echo ====================================
echo.
echo 📱 Flutter App:
echo    Run: flutter run
echo.
echo 💰 Funding Server:
echo    URL: http://localhost:3000
echo    Check the "Funding Server" window
echo.
echo ⛓️  Blockchain:
echo    Ganache: http://127.0.0.1:8545
echo    Network ID: 5777
echo.
echo 🔧 Quick Commands:
echo    Fund wallet: node scripts/fund-accounts.js ^<address^> ^<amount^>
echo    Deploy contract: node scripts/deploy-and-save.js
echo.
echo 💡 Tips:
echo    - Use "Get Test ETH" button in Flutter app
echo    - Check Ganache GUI for transaction history
echo    - Use MetaMask-style wallet creation with seed phrases
echo.
pause