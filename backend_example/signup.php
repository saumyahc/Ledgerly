<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Database configuration via mysqli
$env = parse_ini_file(__DIR__ . '/.env');
$servername = $env['DB_HOST'];
$database = $env['DB_NAME'];
$username = $env['DB_USER'];
$password = $env['DB_PASS'];
$conn = new mysqli($servername, $username, $password, $database);
if ($conn->connect_error) {
    echo json_encode(['success' => false, 'message' => 'Database connection failed: '.$conn->connect_error]);
    exit;
}
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    // If no JSON input, try POST data
    if (!$input) {
        $input = $_POST;
    }
    
    $name = $input['name'] ?? '';
    $email = $input['email'] ?? '';
    $phone = $input['phone'] ?? '';
    $password = $input['password'] ?? '';
    
    // Validate input
    if (empty($name) || empty($email) || empty($phone) || empty($password)) {
        echo json_encode(['success' => false, 'message' => 'All fields are required']);
        exit;
    }
    
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        echo json_encode(['success' => false, 'message' => 'Invalid email format']);
        exit;
    }
    
    // Check if user already exists
    $stmt = $conn->prepare("SELECT id FROM users WHERE email = ?");
    $stmt->bind_param('s', $email);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($result->num_rows > 0) {
        echo json_encode(['success' => false, 'message' => 'User with this email already exists']);
        exit;
    }
    
    // Generate OTP
    $otp = sprintf("%06d", mt_rand(0, 999999));
    $otp_expiry = date('Y-m-d H:i:s', strtotime('+10 minutes'));
    
    // Hash password
    $hashed_password = password_hash($password, PASSWORD_DEFAULT);
    
    try {
        // Begin transaction
    $conn->begin_transaction();
        
        // Insert user data
    $stmt = $conn->prepare("INSERT INTO users (name, email, phone, password, created_at) VALUES (?, ?, ?, ?, NOW())");
    $stmt->bind_param('ssss', $name, $email, $phone, $hashed_password);
    $stmt->execute();
    $user_id = $stmt->insert_id ?: $conn->insert_id;
        
        // Store OTP
    $stmt = $conn->prepare("INSERT INTO otp_codes (user_id, email, otp, expiry_time, created_at) VALUES (?, ?, ?, ?, NOW())");
    $stmt->bind_param('isss', $user_id, $email, $otp, $otp_expiry);
    $stmt->execute();
        
        // Commit transaction
    $conn->commit();
        
        // Send email with OTP (you'll need to configure your email settings)
        $to = $email;
        $subject = "Ledgerly - Email Verification";
        $message = "Hello $name,\n\n";
        $message .= "Thank you for signing up with Ledgerly!\n\n";
        $message .= "Your verification code is: $otp\n\n";
        $message .= "This code will expire in 10 minutes.\n\n";
        $message .= "If you didn't request this code, please ignore this email.\n\n";
        $message .= "Best regards,\nLedgerly Team";
        
        $headers = "From: noreply@ledgerly.com";
        
        // Uncomment the line below when you have email configured
        mail($to, $subject, $message, $headers);
        
        // For testing, log the OTP (remove in production)
        error_log("OTP for $email: $otp");
        
        echo json_encode([
            'success' => true, 
            'message' => 'Sign up successful. Please check your email for verification code.',
            //'otp' => $otp // Remove this in production
        ]);
        
    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(['success' => false, 'message' => 'Sign up failed: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}
?>