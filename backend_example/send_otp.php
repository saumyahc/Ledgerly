<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;
require __DIR__ . '/src/Exception.php';
require __DIR__ . '/src/PHPMailer.php';
require __DIR__ . '/src/SMTP.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Database configuration (replace with your actual database details)
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
    $stmt = $conn->prepare("SELECT id, name, email_verified FROM users WHERE email = ?");
    $stmt->bind_param('s', $email);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($result->num_rows === 0) {
            echo json_encode(['success' => false, 'message' => 'User not found. Please sign up first.']);
            exit;
        }
    $user = $result->fetch_assoc();
        
        // Generate OTP
        $otp = sprintf("%06d", mt_rand(0, 999999));
        $otp_expiry = date('Y-m-d H:i:s', strtotime('+10 minutes'));
        
        // Delete any existing OTP for this user
    $stmt = $conn->prepare("DELETE FROM otp_codes WHERE user_id = ?");
    $stmt->bind_param('i', $user['id']);
    $stmt->execute();
        
        // Store new OTP
    $stmt = $conn->prepare("INSERT INTO otp_codes (user_id, email, otp, expiry_time, created_at) VALUES (?, ?, ?, ?, NOW())");
    $stmt->bind_param('isss', $user['id'], $email, $otp, $otp_expiry);
    $stmt->execute();
        
        // Send email with OTP using PHPMailer
        $to = $email;
        $subject = "Ledgerly - Login Verification";
        $message = "Hello " . $user['name'] . ",\n\n";
        $message .= "You requested to sign in to your Ledgerly account.\n\n";
        $message .= "Your verification code is: $otp\n\n";
        $message .= "This code will expire in 10 minutes.\n\n";
        $message .= "If you didn't request this code, please ignore this email.\n\n";
        $message .= "Best regards,\nLedgerly Team";

        $mail = new PHPMailer(true);
        try {
            $mail->isSMTP();
            $mail->Host = 'smtp.gmail.com';
            $mail->SMTPAuth = true;
            $mail->Username = 'saumyachandwani1510@gmail.com'; // Your Gmail address
            $mail->Password = 'mvjhghmkrvlnvpod';    // Your Gmail App Password
            $mail->SMTPSecure = 'tls';
            $mail->Port = 587;

            $mail->setFrom('saumyachandwani1510@gmail.com', 'Ledgerly');
            $mail->addAddress($to, $user['name']);

            $mail->isHTML(false);
            $mail->Subject = $subject;
            $mail->Body    = $message;

            $mail->send();
        } catch (Exception $e) {
            error_log('Mailer Error: ' . $mail->ErrorInfo);
        }
        
        echo json_encode([
            'success' => true, 
            'message' => 'OTP sent successfully. Please check your email.'
        ]);
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Failed to send OTP: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}