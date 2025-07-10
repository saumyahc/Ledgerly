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
$dbname = 'ledgerly_db';
$username = 'your_username';
$password = 'your_password';

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
    $otp = $input['otp'] ?? '';
    
    // Validate input
    if (empty($email) || empty($otp)) {
        echo json_encode(['success' => false, 'message' => 'Email and OTP are required']);
        exit;
    }
    
    try {
        // Find the OTP record
        $stmt = $pdo->prepare("
            SELECT oc.*, u.id as user_id, u.name, u.email_verified 
            FROM otp_codes oc 
            JOIN users u ON oc.user_id = u.id 
            WHERE oc.email = ? AND oc.otp = ? AND oc.expiry_time > NOW()
            ORDER BY oc.created_at DESC 
            LIMIT 1
        ");
        $stmt->execute([$email, $otp]);
        
        if ($stmt->rowCount() === 0) {
            echo json_encode(['success' => false, 'message' => 'Invalid or expired OTP']);
            exit;
        }
        
        $otp_record = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Check if user is already verified
        if ($otp_record['email_verified']) {
            echo json_encode(['success' => false, 'message' => 'Email is already verified']);
            exit;
        }
        
        // Begin transaction
        $pdo->beginTransaction();
        
        // Mark user as verified
        $stmt = $pdo->prepare("UPDATE users SET email_verified = 1, verified_at = NOW() WHERE id = ?");
        $stmt->execute([$otp_record['user_id']]);
        
        // Delete the used OTP
        $stmt = $pdo->prepare("DELETE FROM otp_codes WHERE id = ?");
        $stmt->execute([$otp_record['id']]);
        
        // Commit transaction
        $pdo->commit();
        
        echo json_encode([
            'success' => true, 
            'message' => 'Email verified successfully! Welcome to Ledgerly.',
            'user' => [
                'id' => $otp_record['user_id'],
                'name' => $otp_record['name'],
                'email' => $otp_record['email']
            ]
        ]);
        
    } catch (Exception $e) {
        $pdo->rollback();
        echo json_encode(['success' => false, 'message' => 'Verification failed: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}
?> 