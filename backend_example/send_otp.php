<?php
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
    
    $email = $input['email'] ?? '';
    
    // Validate input
    if (empty($email)) {
        echo json_encode(['success' => false, 'message' => 'Email is required']);
        exit;
    }
    
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        echo json_encode(['success' => false, 'message' => 'Invalid email format']);
        exit;
    }
    
    try {
        // Check if user exists
        $stmt = $pdo->prepare("SELECT id, name, email_verified FROM users WHERE email = ?");
        $stmt->execute([$email]);
        
        if ($stmt->rowCount() === 0) {
            echo json_encode(['success' => false, 'message' => 'User not found. Please sign up first.']);
            exit;
        }
        
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Check if email is verified
        if (!$user['email_verified']) {
            echo json_encode(['success' => false, 'message' => 'Please verify your email first.']);
            exit;
        }
        
        // Generate OTP
        $otp = sprintf("%06d", mt_rand(0, 999999));
        $otp_expiry = date('Y-m-d H:i:s', strtotime('+10 minutes'));
        
        // Delete any existing OTP for this user
        $stmt = $pdo->prepare("DELETE FROM otp_codes WHERE user_id = ?");
        $stmt->execute([$user['id']]);
        
        // Store new OTP
        $stmt = $pdo->prepare("INSERT INTO otp_codes (user_id, email, otp, expiry_time, created_at) VALUES (?, ?, ?, ?, NOW())");
        $stmt->execute([$user['id'], $email, $otp, $otp_expiry]);
        
        // Send email with OTP (you'll need to configure your email settings)
        $to = $email;
        $subject = "Ledgerly - Login Verification";
        $message = "Hello " . $user['name'] . ",\n\n";
        $message .= "You requested to sign in to your Ledgerly account.\n\n";
        $message .= "Your verification code is: $otp\n\n";
        $message .= "This code will expire in 10 minutes.\n\n";
        $message .= "If you didn't request this code, please ignore this email.\n\n";
        $message .= "Best regards,\nLedgerly Team";
        
        $headers = "From: noreply@ledgerly.com";
        
        // Uncomment the line below when you have email configured
        mail($to, $subject, $message, $headers);
        
        // For testing, log the OTP (remove in production)
        error_log("Login OTP for $email: $otp");
        
        echo json_encode([
            'success' => true, 
            'message' => 'OTP sent successfully. Please check your email.'
            // 'otp' => $otp // Removed for production
        ]);
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Failed to send OTP: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}
?>