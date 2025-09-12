<?php
error_log("email_payment.php: Request received");
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
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
error_log("email_payment.php: Connecting to DB - Host: $servername, Database: $database, User: $username");
$conn = new mysqli($servername, $username, $password, $database);
if ($conn->connect_error) {
    error_log("email_payment.php: DB Connection failed - " . $conn->connect_error);
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed: '.$conn->connect_error]);
    exit;
}
error_log("email_payment.php: DB Connection successful");

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Resolve email to wallet address
    $email = $_GET['email'] ?? null;
    error_log("email_payment.php: GET - Received email = " . ($email ?? 'null'));
    
    if (!$email) {
        error_log("email_payment.php: Email is missing");
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Email address is required']);
        exit;
    }
    
    try {
        // Find user with this email
        $sql = "SELECT u.id, u.name, up.wallet_address FROM users u 
                LEFT JOIN user_profiles up ON u.id = up.user_id
                WHERE u.email = ? AND up.wallet_address IS NOT NULL";
        error_log("email_payment.php: GET - Executing SQL query for email = $email");
        $stmt = $conn->prepare($sql);
        $stmt->bind_param('s', $email);
        $stmt->execute();
        $result = $stmt->get_result();
        $user_data = $result->fetch_assoc();
        
        if ($user_data && $user_data['wallet_address']) {
            error_log("email_payment.php: GET - User found: " . json_encode($user_data));
            echo json_encode([
                'success' => true,
                'user' => [
                    'id' => $user_data['id'],
                    'name' => $user_data['name'],
                    'email' => $email,
                    'wallet_address' => $user_data['wallet_address']
                ]
            ]);
        } else {
            error_log("email_payment.php: GET - No user found with this email or no wallet linked");
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'No user found with this email address or no wallet is linked to this account'
            ]);
        }
        
    } catch (Exception $e) {
        error_log("email_payment.php: GET - Exception: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Process payment request
    $input = json_decode(file_get_contents('php://input'), true);
    $fromEmail = $input['from_email'] ?? null;
    $toEmail = $input['to_email'] ?? null;
    $amount = $input['amount'] ?? null;
    $memo = $input['memo'] ?? '';
    
    error_log("email_payment.php: POST - Received payment request: From=$fromEmail, To=$toEmail, Amount=$amount");
    
    if (!$fromEmail || !$toEmail || !$amount) {
        error_log("email_payment.php: POST - Missing required fields");
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'From email, to email, and amount are required']);
        exit;
    }
    
    try {
        // Get wallet addresses for both emails
        $sql = "SELECT u.id, u.email, up.wallet_address FROM users u 
                LEFT JOIN user_profiles up ON u.id = up.user_id
                WHERE u.email IN (?, ?) AND up.wallet_address IS NOT NULL";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param('ss', $fromEmail, $toEmail);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $wallets = [];
        while ($row = $result->fetch_assoc()) {
            $wallets[$row['email']] = [
                'user_id' => $row['id'],
                'wallet_address' => $row['wallet_address']
            ];
        }
        
        if (!isset($wallets[$fromEmail])) {
            error_log("email_payment.php: POST - Sender wallet not found");
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Sender does not have a wallet linked to their account']);
            exit;
        }
        
        if (!isset($wallets[$toEmail])) {
            error_log("email_payment.php: POST - Receiver wallet not found");
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Receiver does not have a wallet linked to their account']);
            exit;
        }
        
        // At this point, we have both wallet addresses
        // In a real implementation, you would call a smart contract or direct transfer API
        // For now, we'll just record the payment in a new transactions table
        
        // Insert transaction record
        $sql = "INSERT INTO transactions (sender_id, receiver_id, amount, memo, status) 
                VALUES (?, ?, ?, ?, 'pending')";
        $stmt = $conn->prepare($sql);
        $senderId = $wallets[$fromEmail]['user_id'];
        $receiverId = $wallets[$toEmail]['user_id'];
        $stmt->bind_param('iids', $senderId, $receiverId, $amount, $memo);
        
        if ($stmt->execute()) {
            $transactionId = $conn->insert_id;
            error_log("email_payment.php: POST - Transaction recorded with ID: $transactionId");
            
            echo json_encode([
                'success' => true,
                'message' => 'Payment request recorded successfully',
                'transaction' => [
                    'id' => $transactionId,
                    'from_email' => $fromEmail,
                    'to_email' => $toEmail,
                    'from_wallet' => $wallets[$fromEmail]['wallet_address'],
                    'to_wallet' => $wallets[$toEmail]['wallet_address'],
                    'amount' => $amount,
                    'memo' => $memo,
                    'status' => 'pending'
                ]
            ]);
        } else {
            throw new Exception("Failed to record transaction: " . $stmt->error);
        }
        
    } catch (Exception $e) {
        error_log("email_payment.php: POST - Exception: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?>
