<?php
// save_contract.php - Endpoint to save deployed contract details

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, PUT, POST');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// Load environment variables & connect via mysqli
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

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // POST - Save new contract
    $input = json_decode(file_get_contents('php://input'), true);

    if (!isset($input['contract_name']) || !isset($input['contract_address']) || 
        !isset($input['chain_id']) || !isset($input['abi'])) {
        echo json_encode([
            'success' => false,
            'error' => 'Missing required parameters'
        ]);
        exit;
    }

    try {
        // Start transaction
        $conn->autocommit(FALSE);
        
        // First, deactivate all previous contracts for this name and chain
        $deactivate_sql = "UPDATE smart_contracts 
                          SET is_active = 0, 
                              deactivated_at = NOW() 
                          WHERE contract_name = ? 
                          AND chain_id = ? 
                          AND is_active = 1";
        
        $deactivate_stmt = $conn->prepare($deactivate_sql);
        $deactivate_stmt->bind_param('si', $input['contract_name'], $input['chain_id']);
        $deactivate_stmt->execute();
        $deactivated_count = $conn->affected_rows;
        
        // Insert new contract as active
        $insert_sql = "INSERT INTO smart_contracts 
                      (contract_name, contract_address, chain_id, abi, 
                       deployment_tx, network_mode, version, deployed_at, 
                       is_active, created_at, updated_at) 
                      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, NOW(), NOW())";
        
        $insert_stmt = $conn->prepare($insert_sql);
        
        // Extract optional fields with defaults
        $deployment_tx = isset($input['deployment_tx']) ? $input['deployment_tx'] : null;
        $network_mode = isset($input['network_mode']) ? $input['network_mode'] : 'unknown';
        $version = isset($input['version']) ? $input['version'] : 'v1.0.0';
        $deployed_at = isset($input['deployed_at']) ? $input['deployed_at'] : date('Y-m-d H:i:s');
        
        $insert_stmt->bind_param('ssisssss', 
            $input['contract_name'], 
            $input['contract_address'], 
            $input['chain_id'], 
            $input['abi'],
            $deployment_tx,
            $network_mode,
            $version,
            $deployed_at
        );
        
        $success = $insert_stmt->execute();
        $contract_id = $conn->insert_id;
        
        if ($success) {
            // Commit transaction
            $conn->commit();
            
            echo json_encode([
                'success' => true,
                'message' => 'Contract saved successfully',
                'contract_id' => $contract_id,
                'deactivated_previous' => $deactivated_count,
                'data' => [
                    'contract_name' => $input['contract_name'],
                    'contract_address' => $input['contract_address'],
                    'chain_id' => $input['chain_id'],
                    'version' => $version,
                    'is_active' => true
                ]
            ]);
        } else {
            // Rollback on failure
            $conn->rollback();
            echo json_encode([
                'success' => false,
                'error' => 'Failed to save contract: ' . $conn->error
            ]);
        }
        
        // Re-enable autocommit
        $conn->autocommit(TRUE);
        
    } catch (Exception $e) {
        $conn->rollback();
        $conn->autocommit(TRUE);
        echo json_encode([
            'success' => false,
            'error' => 'Database error: ' . $e->getMessage()
        ]);
    }

} else if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // GET - Retrieve active contracts sorted by newest first
    try {
        $chain_id = isset($_GET['chain_id']) ? $_GET['chain_id'] : null;
        $contract_name = isset($_GET['contract_name']) ? $_GET['contract_name'] : null;
        
        $sql = "SELECT 
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
                WHERE is_active = 1";
        
        $params = [];
        $types = "";
        
        if ($chain_id) {
            $sql .= " AND chain_id = ?";
            $params[] = $chain_id;
            $types .= "i";
        }
        
        if ($contract_name) {
            $sql .= " AND contract_name = ?";
            $params[] = $contract_name;
            $types .= "s";
        }
        
        $sql .= " ORDER BY created_at DESC, id DESC";
        
        $stmt = $conn->prepare($sql);
        
        if (!empty($params)) {
            $stmt->bind_param($types, ...$params);
        }
        
        $stmt->execute();
        $result = $stmt->get_result();
        
        $contracts = [];
        while ($row = $result->fetch_assoc()) {
            $contracts[] = $row;
        }
        
        echo json_encode([
            'success' => true,
            'contracts' => $contracts,
            'count' => count($contracts)
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'error' => 'Database error: ' . $e->getMessage()
        ]);
    }
    
} else {
    echo json_encode([
        'success' => false,
        'error' => 'Method not allowed'
    ]);
}

$conn->close();
?>
