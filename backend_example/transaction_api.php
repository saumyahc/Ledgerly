<?php
/**
 * Transaction API for Ledgerly
 * Handles recording and retrieving blockchain transactions
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Load environment variables & connect via PDO
$env = parse_ini_file(__DIR__ . '/.env');
$servername = $env['DB_HOST'];
$database = $env['DB_NAME'];
$username = $env['DB_USER'];
$password = $env['DB_PASS'];

try {
    $pdo = new PDO("mysql:host=$servername;dbname=$database;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed: ' . $e->getMessage()]);
    exit();
}

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

switch($method) {
    case 'POST':
        if ($action === 'record') {
            recordTransaction($pdo);
        } elseif ($action === 'update_status') {
            updateTransactionStatus($pdo);
        } else {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid action']);
        }
        break;
        
    case 'GET':
        if ($action === 'history') {
            getTransactionHistory($pdo);
        } elseif ($action === 'pending') {
            getPendingTransactions($pdo);
        } elseif ($action === 'summary') {
            getTransactionSummary($pdo);
        } else {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid action']);
        }
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
        break;
}

/**
 * Record a new transaction
 */
function recordTransaction($pdo) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Validate required fields
    $required = ['user_id', 'wallet_address', 'transaction_hash', 'transaction_type', 
                'direction', 'from_address', 'to_address', 'amount', 'sender_id', 'receiver_id', 'sender_email', 'receiver_email'];
    
    foreach ($required as $field) {
        if (!isset($input[$field]) || empty($input[$field])) {
            http_response_code(400);
            echo json_encode(['error' => "Missing required field: $field"]);
            return;
        }
    }
    
    try {
        $sql = "INSERT INTO transactions (
            sender_id, receiver_id, sender_email, receiver_email, amount, memo, transaction_hash, status, created_at, updated_at
        ) VALUES (
            :sender_id, :receiver_id, :sender_email, :receiver_email, :amount, :memo, :transaction_hash, :status, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        )";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':sender_id' => $input['sender_id'],
            ':receiver_id' => $input['receiver_id'],
            ':sender_email' => $input['sender_email'],
            ':receiver_email' => $input['receiver_email'],
            ':amount' => $input['amount'],
            ':memo' => $input['memo'] ?? null,
            ':transaction_hash' => $input['transaction_hash'] ?? null,
            ':status' => $input['status'] ?? 'pending'
        ]);
        
        $transaction_id = $pdo->lastInsertId();
        
        echo json_encode([
            'success' => true,
            'transaction_id' => $transaction_id,
            'message' => 'Transaction recorded successfully'
        ]);
        
    } catch(PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to record transaction: ' . $e->getMessage()]);
    }
}

/**
 * Update transaction status (when confirmed/failed)
 */
function updateTransactionStatus($pdo) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['transaction_hash']) || !isset($input['status'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing transaction_hash or status']);
        return;
    }
    
    try {
        $sql = "UPDATE transactions SET 
                status = :status,
                confirmations = :confirmations,
                block_number = :block_number,
                block_hash = :block_hash,
                transaction_index = :transaction_index,
                gas_used = :gas_used,
                gas_cost = :gas_cost,
                error_message = :error_message,
                blockchain_timestamp = :blockchain_timestamp,
                updated_at = CURRENT_TIMESTAMP
                WHERE transaction_hash = :transaction_hash";
        
        $stmt = $pdo->prepare($sql);
        
        $stmt->execute([
            ':status' => $input['status'],
            ':confirmations' => $input['confirmations'] ?? 0,
            ':block_number' => $input['block_number'] ?? null,
            ':block_hash' => $input['block_hash'] ?? null,
            ':transaction_index' => $input['transaction_index'] ?? null,
            ':gas_used' => $input['gas_used'] ?? null,
            ':gas_cost' => $input['gas_cost'] ?? null,
            ':error_message' => $input['error_message'] ?? null,
            ':blockchain_timestamp' => $input['blockchain_timestamp'] ?? null,
            ':transaction_hash' => $input['transaction_hash']
        ]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Transaction status updated successfully'
        ]);
        
    } catch(PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to update transaction: ' . $e->getMessage()]);
    }
}

/**
 * Get transaction history for a user
 */
function getTransactionHistory($pdo) {
    $user_id = $_GET['user_id'] ?? null;
    $wallet_address = $_GET['wallet_address'] ?? null;
    $limit = min(($_GET['limit'] ?? 50), 100); // Max 100 transactions
    $offset = $_GET['offset'] ?? 0;
    $type = $_GET['type'] ?? null;
    
    if (!$user_id && !$wallet_address) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing user_id or wallet_address']);
        return;
    }
    
    try {
        $params = [];
        $limitInt = (int)$limit;
        $offsetInt = (int)$offset;
        if (!$user_id) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing user_id']);
            return;
        }
        // Only show pending transactions for sender, completed for both
        $sql = "SELECT * FROM transactions WHERE (
            (status = 'pending' AND sender_id = :user_id)
            OR (status = 'completed' AND (sender_id = :user_id OR receiver_id = :user_id))
        ) ORDER BY created_at DESC LIMIT $limitInt OFFSET $offsetInt";
        $params[':user_id'] = $user_id;
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $transactions = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $countSQL = "SELECT COUNT(*) FROM transactions WHERE (
            (status = 'pending' AND sender_id = :user_id)
            OR (status = 'completed' AND (sender_id = :user_id OR receiver_id = :user_id))
        )";
        $countStmt = $pdo->prepare($countSQL);
        $countStmt->execute($params);
        $total = $countStmt->fetchColumn();
        echo json_encode([
            'success' => true,
            'transactions' => $transactions,
            'total' => (int)$total,
            'limit' => (int)$limit,
            'offset' => (int)$offset
        ]);
    } catch(PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch transactions: ' . $e->getMessage()]);
    }
}

/**
 * Get pending transactions
 */
function getPendingTransactions($pdo) {
    $user_id = $_GET['user_id'] ?? null;
    
    try {
        $sql = "SELECT * FROM pending_transactions";
        $params = [];
        
        if ($user_id) {
            $sql .= " WHERE user_id = :user_id";
            $params[':user_id'] = $user_id;
        }
        
        $sql .= " ORDER BY created_at ASC";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $transactions = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'pending_transactions' => $transactions
        ]);
        
    } catch(PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch pending transactions: ' . $e->getMessage()]);
    }
}

/**
 * Get transaction summary for a user
 */
function getTransactionSummary($pdo) {
    $user_id = $_GET['user_id'] ?? null;
    $days = min(($_GET['days'] ?? 30), 90); // Max 90 days
    
    if (!$user_id) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing user_id']);
        return;
    }
    
    try {
        $sql = "SELECT 
                    summary_date,
                    total_transactions,
                    incoming_count,
                    outgoing_count,
                    total_incoming,
                    total_outgoing,
                    total_gas_fees,
                    net_amount,
                    send_count,
                    receive_count,
                    faucet_count,
                    betting_count,
                    contract_count
                FROM transaction_summaries 
                WHERE user_id = :user_id 
                AND summary_date >= DATE_SUB(CURDATE(), INTERVAL :days DAY)
                ORDER BY summary_date DESC";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':user_id' => $user_id,
            ':days' => $days
        ]);
        
        $summaries = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'summaries' => $summaries,
            'days' => (int)$days
        ]);
        
    } catch(PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch summary: ' . $e->getMessage()]);
    }
}
?>