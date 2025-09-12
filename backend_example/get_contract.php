<?php
// get_contract.php - Endpoint to retrieve deployed contract details

header('Content-Type: application/json');

// Include database configuration
require_once 'src/DSNConfigurator.php';
$dsn = new DSNConfigurator();
$pdo = $dsn->createConnection();

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
    // Get contract details
    $stmt = $pdo->prepare("SELECT * FROM smart_contracts WHERE contract_name = ? AND chain_id = ?");
    $stmt->execute([$contractName, $chainId]);
    $contract = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($contract) {
        echo json_encode([
            'success' => true,
            'contract' => [
                'name' => $contract['contract_name'],
                'address' => $contract['contract_address'],
                'chain_id' => $contract['chain_id'],
                'abi' => $contract['abi'],
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
} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'error' => 'Database error: ' . $e->getMessage()
    ]);
}
