# Ledgerly API Status Checker - PowerShell Script
# Run this script to test all your API endpoints

Write-Host "🔍 Ledgerly API Status Checker" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "https://ledgerly.hivizstudios.com/backend_example"

function Test-APIEndpoint {
    param(
        [string]$Endpoint,
        [string]$Method = "GET",
        [hashtable]$Body = $null,
        [string]$Description
    )
    
    Write-Host "Testing: $Description" -ForegroundColor Yellow
    Write-Host "URL: $baseUrl/$Endpoint" -ForegroundColor Gray
    
    try {
        $headers = @{ "Content-Type" = "application/json" }
        
        if ($Method -eq "GET") {
            $response = Invoke-WebRequest -Uri "$baseUrl/$Endpoint" -Method GET -UseBasicParsing
        } else {
            $jsonBody = $Body | ConvertTo-Json
            $response = Invoke-WebRequest -Uri "$baseUrl/$Endpoint" -Method POST -Body $jsonBody -Headers $headers -UseBasicParsing
        }
        
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ SUCCESS (Status: $($response.StatusCode))" -ForegroundColor Green
            Write-Host "Response: $($response.Content.Substring(0, [Math]::Min(200, $response.Content.Length)))..." -ForegroundColor Green
        } else {
            Write-Host "⚠️  WARNING (Status: $($response.StatusCode))" -ForegroundColor Yellow
            Write-Host "Response: $($response.Content)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Test Database Connection
Test-APIEndpoint -Endpoint "test_db.php" -Description "Database Connection"

# Test Email Payment API
Test-APIEndpoint -Endpoint "email_payment.php?email=test@example.com" -Description "Email to Wallet Resolution"

# Test Signup API
$signupData = @{
    name = "Test User"
    email = "test$(Get-Date -Format 'yyyyMMddHHmmss')@example.com"
    password = "testpass123"
}
Test-APIEndpoint -Endpoint "signup.php" -Method "POST" -Body $signupData -Description "User Signup"

# Test Profile API
Test-APIEndpoint -Endpoint "get_profile.php?user_id=1" -Description "Get User Profile"

# Test Contract API
Test-APIEndpoint -Endpoint "get_contract.php?contract_name=EmailPaymentRegistry" -Description "Get Smart Contract"

# Test Wallet API
$walletData = @{
    user_id = 1
    wallet_address = "0x1234567890123456789012345678901234567890"
}
Test-APIEndpoint -Endpoint "wallet_api.php" -Method "POST" -Body $walletData -Description "Wallet Linking"

Write-Host "🏁 API Testing Complete!" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 Tips:" -ForegroundColor Cyan
Write-Host "- If database connection fails, check your .env configuration" -ForegroundColor Gray
Write-Host "- If APIs return errors, check PHP error logs on your server" -ForegroundColor Gray
Write-Host "- For 404 errors, verify files exist in backend_example directory" -ForegroundColor Gray

Read-Host "Press Enter to exit"
