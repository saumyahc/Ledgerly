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

// Database configuration (replace with your actual database details)

$host = 'localhost';
$dbname = 'ledgerly_db'; // replace with your actual database name
$username = 'root';
$password = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
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
    $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ?");
    $stmt->execute([$email]);
    
    if ($stmt->rowCount() > 0) {
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
        $pdo->beginTransaction();
        
        // Insert user data
        $stmt = $pdo->prepare("INSERT INTO users (name, email, phone, password, created_at) VALUES (?, ?, ?, ?, NOW())");
        $stmt->execute([$name, $email, $phone, $hashed_password]);
        
        $user_id = $pdo->lastInsertId();
        
        // Store OTP
        $stmt = $pdo->prepare("INSERT INTO otp_codes (user_id, email, otp, expiry_time, created_at) VALUES (?, ?, ?, ?, NOW())");
        $stmt->execute([$user_id, $email, $otp, $otp_expiry]);
        
        // Commit transaction
        $pdo->commit();
        
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
        $pdo->rollback();
        echo json_encode(['success' => false, 'message' => 'Sign up failed: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}
?> 