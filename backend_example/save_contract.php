<?php
// save_contract.php - Endpoint to save deployed contract details

header('Content-Type: application/json');

// Include database configuration
require_once 'src/DSNConfigurator.php';
$dsn = new DSNConfigurator();
$pdo = $dsn->createConnection();

// Get input data as JSON
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
    // Check if contract already exists for this chain
    $stmt = $pdo->prepare("SELECT * FROM smart_contracts WHERE contract_name = ? AND chain_id = ?");
    $stmt->execute([$input['contract_name'], $input['chain_id']]);
    $existingContract = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($existingContract) {
        // Update existing contract
        $stmt = $pdo->prepare("UPDATE smart_contracts 
                              SET contract_address = ?, 
                                  abi = ?,
                                  updated_at = NOW() 
                              WHERE id = ?");
        $success = $stmt->execute([
            $input['contract_address'],
            $input['abi'],
            $existingContract['id']
        ]);
    } else {
        // Insert new contract
        $stmt = $pdo->prepare("INSERT INTO smart_contracts 
                              (contract_name, contract_address, chain_id, abi, created_at, updated_at) 
                              VALUES (?, ?, ?, ?, NOW(), NOW())");
        $success = $stmt->execute([
            $input['contract_name'],
            $input['contract_address'],
            $input['chain_id'],
            $input['abi']
        ]);
    }
    
    if ($success) {
        echo json_encode([
            'success' => true,
            'message' => 'Contract saved successfully'
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'error' => 'Failed to save contract'
        ]);
    }
} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'error' => 'Database error: ' . $e->getMessage()
    ]);
}
