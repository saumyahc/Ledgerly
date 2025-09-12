# Blockchain Network Setup Validator
# Tests all network configurations and services

Write-Host "Ledgerly Blockchain Network Setup Validator" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if .env file exists
if (-not (Test-Path ".env")) {
    Write-Host "[ERROR] .env file not found!" -ForegroundColor Red
    Write-Host "Please create .env file with your network configuration." -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] .env file found" -ForegroundColor Green

# Read .env file and extract key variables
$envContent = Get-Content ".env" -Raw
$ethereumApiKey = if ($envContent -match "ETHEREUM_API_KEY=(.+)") { $matches[1].Trim() } else { "" }
$enableMainnet = if ($envContent -match "ENABLE_MAINNET=(.+)") { $matches[1].Trim() } else { "false" }
$defaultNetwork = if ($envContent -match "DEFAULT_NETWORK=(.+)") { $matches[1].Trim() } else { "ethereum_sepolia" }

Write-Host "📋 Configuration Summary:" -ForegroundColor Yellow
Write-Host "  API Key: $($ethereumApiKey.Substring(0, [Math]::Min(8, $ethereumApiKey.Length)))..." -ForegroundColor White
Write-Host "  Mainnet Enabled: $enableMainnet" -ForegroundColor White
Write-Host "  Default Network: $defaultNetwork" -ForegroundColor White
Write-Host ""

# Test network endpoints
Write-Host "🌐 Testing Network Connections..." -ForegroundColor Yellow

$networks = @{
    "Ethereum Mainnet" = "https://mainnet.infura.io/v3/$ethereumApiKey"
    "Ethereum Sepolia" = "https://sepolia.infura.io/v3/$ethereumApiKey"
    "Ethereum Goerli" = "https://goerli.infura.io/v3/$ethereumApiKey"
    "Polygon Mainnet" = "https://polygon-mainnet.infura.io/v3/$ethereumApiKey"
    "Local Ganache" = "http://127.0.0.1:7545"
}

$results = @{}

foreach ($network in $networks.GetEnumerator()) {
    Write-Host "  Testing $($network.Key)..." -NoNewline
    
    try {
        $body = @{
            jsonrpc = "2.0"
            method = "eth_blockNumber"
            params = @()
            id = 1
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri $network.Value -Method POST -Body $body -ContentType "application/json" -TimeoutSec 10
        
        if ($response.result) {
            $blockNumber = [Convert]::ToInt32($response.result, 16)
            Write-Host " ✅ Connected (Block: $blockNumber)" -ForegroundColor Green
            $results[$network.Key] = "✅ Connected"
        } else {
            Write-Host " ❌ No response" -ForegroundColor Red
            $results[$network.Key] = "❌ No response"
        }
    }
    catch {
        Write-Host " ❌ Failed ($($_.Exception.Message.Split('.')[0]))" -ForegroundColor Red
        $results[$network.Key] = "❌ Failed"
    }
}

Write-Host ""

# Test local backend APIs
Write-Host "🔧 Testing Backend APIs..." -ForegroundColor Yellow

$apiEndpoints = @{
    "Profile System" = "http://localhost/ledgerly_backend/get_profile.php"
    "Wallet API" = "http://localhost/ledgerly_backend/wallet_api.php"
    "Contract API" = "http://localhost/ledgerly_backend/get_contract.php"
    "Database Test" = "http://localhost/ledgerly_backend/test_db.php"
}

foreach ($endpoint in $apiEndpoints.GetEnumerator()) {
    Write-Host "  Testing $($endpoint.Key)..." -NoNewline
    
    try {
        $response = Invoke-WebRequest -Uri $endpoint.Value -Method GET -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host " ✅ Available" -ForegroundColor Green
        } else {
            Write-Host " ⚠️  Status: $($response.StatusCode)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host " ❌ Unavailable" -ForegroundColor Red
    }
}

Write-Host ""

# Check Flutter dependencies
Write-Host "📱 Checking Flutter Setup..." -ForegroundColor Yellow

if (Get-Command flutter -ErrorAction SilentlyContinue) {
    Write-Host "  Flutter CLI: ✅ Available" -ForegroundColor Green
    
    # Check if in Flutter project
    if (Test-Path "pubspec.yaml") {
        Write-Host "  Flutter Project: ✅ Detected" -ForegroundColor Green
        
        # Check key dependencies
        $pubspecContent = Get-Content "pubspec.yaml" -Raw
        $dependencies = @("web3dart", "flutter_secure_storage", "provider", "http")
        
        foreach ($dep in $dependencies) {
            if ($pubspecContent -match $dep) {
                Write-Host "  ${dep}: [OK] Found" -ForegroundColor Green
            } else {
                Write-Host "  ${dep}: [X] Missing" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  Flutter Project: ❌ Not detected" -ForegroundColor Red
    }
} else {
    Write-Host "  Flutter CLI: ❌ Not found" -ForegroundColor Red
}

Write-Host ""

# Check Node.js and npm setup
Write-Host "📦 Checking Node.js Setup..." -ForegroundColor Yellow

if (Get-Command node -ErrorAction SilentlyContinue) {
    $nodeVersion = node --version
    Write-Host "  Node.js: ✅ $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "  Node.js: ❌ Not found" -ForegroundColor Red
}

if (Get-Command npm -ErrorAction SilentlyContinue) {
    $npmVersion = npm --version
    Write-Host "  npm: ✅ v$npmVersion" -ForegroundColor Green
    
    # Check if package.json exists
    if (Test-Path "package.json") {
        Write-Host "  package.json: ✅ Found" -ForegroundColor Green
        
        # Check if node_modules exists
        if (Test-Path "node_modules") {
            Write-Host "  Dependencies: ✅ Installed" -ForegroundColor Green
        } else {
            Write-Host "  Dependencies: ⚠️  Run 'npm install'" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  package.json: ❌ Not found" -ForegroundColor Red
    }
} else {
    Write-Host "  npm: ❌ Not found" -ForegroundColor Red
}

Write-Host ""

# Summary and recommendations
Write-Host "📊 Setup Summary:" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan

$passedTests = 0
$totalTests = $results.Count

foreach ($result in $results.GetEnumerator()) {
    Write-Host "  $($result.Key): $($result.Value)"
    if ($result.Value -like "*✅*") { $passedTests++ }
}

Write-Host ""
Write-Host "📈 Network Status: $passedTests/$totalTests networks accessible" -ForegroundColor $(if ($passedTests -gt 0) { "Green" } else { "Red" })

# Recommendations
Write-Host ""
Write-Host "💡 Recommendations:" -ForegroundColor Yellow

if ($results["Local Ganache"] -like "*❌*") {
    Write-Host "  • Start Ganache for local development: ganache-cli --port 7545" -ForegroundColor White
}

if ($results["Ethereum Sepolia"] -like "*❌*") {
    Write-Host "  • Check your Infura API key and internet connection" -ForegroundColor White
}

if ($enableMainnet -eq "true") {
    Write-Host "  ⚠️  MAINNET ENABLED - You're using real ETH!" -ForegroundColor Red
    Write-Host "  • Consider setting ENABLE_MAINNET=false for testing" -ForegroundColor White
}

Write-Host ""
Write-Host "🚀 Next Steps:" -ForegroundColor Green
Write-Host "  1. Fix any failed network connections above" -ForegroundColor White
Write-Host "  2. Run 'flutter pub get' to install Flutter dependencies" -ForegroundColor White
Write-Host "  3. Run 'npm install' to install Node.js dependencies" -ForegroundColor White
Write-Host "  4. Test wallet creation with your chosen network" -ForegroundColor White
Write-Host "  5. Deploy contracts using 'truffle migrate --network <network>'" -ForegroundColor White

Write-Host ""
Write-Host "Network validation complete!" -ForegroundColor Cyan
