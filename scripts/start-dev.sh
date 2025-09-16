#!/bin/bash

# Ledgerly Development Startup Script
# ===================================
# This script starts all necessary services for development

echo "🚀 Starting Ledgerly Development Environment"
echo "============================================="

# Check if node is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    exit 1
fi

# Check if ganache is running
echo "🔍 Checking Ganache connection..."
if curl -s -X POST \
   -H "Content-Type: application/json" \
   -d '{"jsonrpc":"2.0","method":"eth_accounts","params":[],"id":1}' \
   http://127.0.0.1:8545 > /dev/null 2>&1; then
    echo "✅ Ganache is running on port 8545"
else
    echo "❌ Ganache is not running. Please start Ganache first:"
    echo "   1. Open Ganache GUI"
    echo "   2. Create/Open workspace on port 8545"
    echo "   3. Run this script again"
    exit 1
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing Node.js dependencies..."
    npm install
fi

# Start the funding server in background
echo "💰 Starting funding server..."
node scripts/funding-server.js &
FUNDING_PID=$!

# Start Ganache if not running (alternative method)
# echo "⛓️  Starting Ganache..."
# node scripts/start-ganache.js &
# GANACHE_PID=$!

echo ""
echo "🎉 Development environment is ready!"
echo "===================================="
echo ""
echo "📱 Flutter App:"
echo "   Run: flutter run"
echo ""
echo "💰 Funding Server:"
echo "   URL: http://localhost:3000"
echo "   PID: $FUNDING_PID"
echo ""
echo "⛓️  Blockchain:"
echo "   Ganache: http://127.0.0.1:8545"
echo "   Network ID: 5777"
echo ""
echo "🔧 Quick Commands:"
echo "   Fund wallet: node scripts/fund-accounts.js <address> <amount>"
echo "   Deploy contract: node scripts/deploy-and-save.js"
echo "   Stop services: kill $FUNDING_PID"
echo ""
echo "🛑 Press Ctrl+C to stop all services"

# Handle cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping development services..."
    if [ ! -z "$FUNDING_PID" ]; then
        kill $FUNDING_PID 2>/dev/null
        echo "   ✅ Funding server stopped"
    fi
    echo "🏁 Development environment stopped"
    exit 0
}

trap cleanup INT TERM

# Keep script running
wait