<?php
// get_contract.php - Endpoint to retrieve deployed contract details

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// Load environment variables & connect via mysqli (same as send_otp.php)
$env = parse_ini_file(__DIR__ . '/.env');
$servername = $env['DB_HOST'];
$database = $env['DB_NAME'];
$username = $env['DB_USER'];
$password = $env['DB_PASS'];
$conn = new mysqli($servername, $username, $password, $database);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Database connection failed: '.$conn->connect_error]);
    exit;
}

// Get query parameters
$contractName = $_GET['contract_name'] ?? null;
$chainId = $_GET['chain_id'] ?? null;

if (!$contractName || !$chainId) {
    echo json_encode([
        'success' => false,
        'error' => 'Missing required parameters'
    ]);
    exit;
}

try {
    // Get contract details from smart_contracts table
    $stmt = $conn->prepare("SELECT 
        id,
        contract_name, 
        contract_address, 
        chain_id, 
        abi,
        deployment_tx,
        network_mode,
        version,
        deployed_at,
        is_active,
        created_at,
        updated_at
    FROM smart_contracts 
    WHERE contract_name = ? AND chain_id = ? AND is_active = 1
    ORDER BY created_at DESC 
    LIMIT 1");
    
    $stmt->bind_param('si', $contractName, $chainId);
    $stmt->execute();
    $result = $stmt->get_result();
    $contract = $result->fetch_assoc();
    
    if ($contract) {
        echo json_encode([
            'success' => true,
            'contract' => [
                'id' => $contract['id'],
                'name' => $contract['contract_name'],
                'address' => $contract['contract_address'],
                'chain_id' => $contract['chain_id'],
                'abi' => $contract['abi'],
                'deployment_tx' => $contract['deployment_tx'],
                'network_mode' => $contract['network_mode'],
                'version' => $contract['version'],
                'deployed_at' => $contract['deployed_at'],
                'is_active' => $contract['is_active'],
                'created_at' => $contract['created_at'],
                'updated_at' => $contract['updated_at']
            ]
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'error' => 'Contract not found'
        ]);
    }
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => 'Database error: ' . $e->getMessage()
    ]);
}

$conn->close();
?>
