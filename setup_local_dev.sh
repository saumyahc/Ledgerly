#!/bin/bash

# Ledgerly Quick Setup Script
# This script helps set up the local development environment

echo "🚀 Ledgerly Local Development Setup"
echo "=================================="

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install it from https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js is installed: $(node --version)"

# Install global dependencies
echo "📦 Installing global dependencies..."
npm install -g truffle ganache-cli

# Install project dependencies
echo "📦 Installing project dependencies..."
npm install

# Compile contracts
echo "🔨 Compiling smart contracts..."
truffle compile

# Check if Ganache is running
echo "🔍 Checking if Ganache is running..."
if curl -s http://127.0.0.1:7545 > /dev/null; then
    echo "✅ Ganache is already running"
else
    echo "⚠️  Ganache is not running. Starting Ganache..."
    echo "   You can also run: ganache-cli --accounts 10 --host 0.0.0.0 --port 7545 --deterministic"
    ganache-cli --accounts 10 --host 0.0.0.0 --port 7545 --deterministic &
    sleep 5
fi

# Deploy contracts
echo "🚀 Deploying contracts to local network..."
truffle migrate --network development

echo ""
echo "✅ Setup Complete!"
echo "=================="
echo ""
echo "📋 Next Steps:"
echo "1. Start your PHP backend server (XAMPP/WAMP)"
echo "2. Import database schema: mysql -u root -p ledgerly_db < backend_example/database_schema.sql"
echo "3. Configure backend_example/.env with your database credentials"
echo "4. Update Flutter app with the deployed contract address"
echo "5. Run your Flutter app with: flutter run"
echo ""
echo "📄 For detailed instructions, see LEDGERLY_IMPLEMENTATION_STATUS.md"
echo ""
echo "🔗 Useful Commands:"
echo "   truffle console                    # Interact with contracts"
echo "   truffle migrate --reset           # Redeploy contracts"
echo "   ganache-cli --help               # Ganache options"
echo ""
