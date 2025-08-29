<?php
error_log("wallet_api.php: Request received");
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
error_log("wallet_api.php: Connecting to DB - Host: $servername, Database: $database, User: $username");
$conn = new mysqli($servername, $username, $password, $database);
if ($conn->connect_error) {
    error_log("wallet_api.php: DB Connection failed - " . $conn->connect_error);
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed: '.$conn->connect_error]);
    exit;
}
error_log("wallet_api.php: DB Connection successful");

// Function to validate Ethereum address
function isValidEthereumAddress($address) {
    // Check if address is 42 characters long and starts with 0x
    if (strlen($address) !== 42 || substr($address, 0, 2) !== '0x') {
        return false;
    }
    // Check if the remaining characters are valid hex
    $hex_part = substr($address, 2);
    return ctype_xdigit($hex_part);
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Get wallet info for a user
    $user_id = $_GET['user_id'] ?? null;
    error_log("wallet_api.php: GET - Received user_id = " . ($user_id ?? 'null'));
    
    if (!$user_id) {
        error_log("wallet_api.php: GET - User ID is missing");
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'User ID is required']);
        exit;
    }
    
    try {
        // Get wallet information
        $sql = "SELECT wallet_address, wallet_created_at FROM user_profiles WHERE user_id = ?";
        error_log("wallet_api.php: GET - Executing SQL query for user_id = $user_id");
        $stmt = $conn->prepare($sql);
        $stmt->bind_param('i', $user_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $wallet_data = $result->fetch_assoc();
        
        if ($wallet_data) {
            error_log("wallet_api.php: GET - Wallet data found: " . json_encode($wallet_data));
            echo json_encode([
                'success' => true,
                'wallet' => [
                    'address' => $wallet_data['wallet_address'],
                    'created_at' => $wallet_data['wallet_created_at'],
                    'has_wallet' => !empty($wallet_data['wallet_address'])
                ]
            ]);
        } else {
            error_log("wallet_api.php: GET - No wallet data found, user may not exist");
            echo json_encode([
                'success' => true,
                'wallet' => [
                    'address' => null,
                    'created_at' => null,
                    'has_wallet' => false
                ]
            ]);
        }
        
    } catch (Exception $e) {
        error_log("wallet_api.php: GET - Exception: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }

} elseif ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    // Link/Update wallet address for a user
    $input = json_decode(file_get_contents('php://input'), true);
    $user_id = $input['user_id'] ?? null;
    $wallet_address = $input['wallet_address'] ?? null;
    
    error_log("wallet_api.php: PUT - Received user_id = " . ($user_id ?? 'null') . ", wallet_address = " . ($wallet_address ?? 'null'));
    
    if (!$user_id || !$wallet_address) {
        error_log("wallet_api.php: PUT - Missing required fields");
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'User ID and wallet address are required']);
        exit;
    }
    
    // Validate Ethereum address format
    if (!isValidEthereumAddress($wallet_address)) {
        error_log("wallet_api.php: PUT - Invalid Ethereum address format: $wallet_address");
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid Ethereum address format']);
        exit;
    }
    
    try {
        // Start transaction
        $conn->begin_transaction();
        
        // Check if user exists
        $check_user_sql = "SELECT id FROM users WHERE id = ?";
        $check_stmt = $conn->prepare($check_user_sql);
        $check_stmt->bind_param('i', $user_id);
        $check_stmt->execute();
        $user_result = $check_stmt->get_result();
        
        if ($user_result->num_rows === 0) {
            error_log("wallet_api.php: PUT - User not found: $user_id");
            $conn->rollback();
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'User not found']);
            exit;
        }
        
        // Check if wallet address is already linked to another user
        $check_wallet_sql = "SELECT user_id FROM user_profiles WHERE wallet_address = ? AND user_id != ?";
        $check_wallet_stmt = $conn->prepare($check_wallet_sql);
        $check_wallet_stmt->bind_param('si', $wallet_address, $user_id);
        $check_wallet_stmt->execute();
        $wallet_result = $check_wallet_stmt->get_result();
        
        if ($wallet_result->num_rows > 0) {
            $existing_user = $wallet_result->fetch_assoc();
            error_log("wallet_api.php: PUT - Wallet address already linked to user: " . $existing_user['user_id']);
            $conn->rollback();
            http_response_code(409);
            echo json_encode(['success' => false, 'message' => 'Wallet address is already linked to another account']);
            exit;
        }
        
        // Check if user profile exists
        $profile_check_sql = "SELECT id FROM user_profiles WHERE user_id = ?";
        $profile_check_stmt = $conn->prepare($profile_check_sql);
        $profile_check_stmt->bind_param('i', $user_id);
        $profile_check_stmt->execute();
        $profile_result = $profile_check_stmt->get_result();
        
        if ($profile_result->num_rows > 0) {
            // Update existing profile
            $update_sql = "UPDATE user_profiles SET wallet_address = ?, wallet_created_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP WHERE user_id = ?";
            $update_stmt = $conn->prepare($update_sql);
            $update_stmt->bind_param('si', $wallet_address, $user_id);
            error_log("wallet_api.php: PUT - Updating existing profile for user_id = $user_id");
            
            if ($update_stmt->execute()) {
                error_log("wallet_api.php: PUT - Profile updated successfully");
            } else {
                throw new Exception("Failed to update profile: " . $update_stmt->error);
            }
        } else {
            // Create new profile with wallet address
            $insert_sql = "INSERT INTO user_profiles (user_id, wallet_address, wallet_created_at, preferred_currency) VALUES (?, ?, CURRENT_TIMESTAMP, 'ETH')";
            $insert_stmt = $conn->prepare($insert_sql);
            $insert_stmt->bind_param('is', $user_id, $wallet_address);
            error_log("wallet_api.php: PUT - Creating new profile for user_id = $user_id");
            
            if ($insert_stmt->execute()) {
                error_log("wallet_api.php: PUT - Profile created successfully");
            } else {
                throw new Exception("Failed to create profile: " . $insert_stmt->error);
            }
        }
        
        // Commit transaction
        $conn->commit();
        
        error_log("wallet_api.php: PUT - Wallet address linked successfully");
        echo json_encode([
            'success' => true,
            'message' => 'Wallet address linked successfully',
            'wallet' => [
                'address' => $wallet_address,
                'created_at' => date('Y-m-d H:i:s'),
                'has_wallet' => true
            ]
        ]);
        
    } catch (Exception $e) {
        $conn->rollback();
        error_log("wallet_api.php: PUT - Exception: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }

} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Additional wallet operations (future use)
    http_response_code(501);
    echo json_encode(['success' => false, 'message' => 'POST method not implemented yet']);
    
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?>
