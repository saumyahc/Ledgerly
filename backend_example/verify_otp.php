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
    if (!$input) {
        $input = $_POST;
    }
    $email = $input['email'] ?? '';
    $otp = $input['otp'] ?? '';

    if (empty($email) || empty($otp)) {
        echo json_encode(['success' => false, 'message' => 'Email and OTP are required']);
        exit;
    }
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        echo json_encode(['success' => false, 'message' => 'Invalid email format']);
        exit;
    }

    try {
        // Find user
    $stmt = $conn->prepare("SELECT id, name, email FROM users WHERE email = ?");
    $stmt->bind_param('s', $email);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();
        if (!$user) {
            echo json_encode(['success' => false, 'message' => 'User not found. Please sign up first.']);
            exit;
        }
    // Check OTP
    $stmt = $conn->prepare("SELECT id, expiry_time, used FROM otp_codes WHERE email = ? AND otp = ? ORDER BY created_at DESC LIMIT 1");
    $stmt->bind_param('ss', $email, $otp);
    $stmt->execute();
    $result = $stmt->get_result();
    $otp_row = $result->fetch_assoc();
        if (!$otp_row) {
            echo json_encode(['success' => false, 'message' => 'Invalid OTP']);
            exit;
        }
        if ($otp_row['used']) {
            echo json_encode(['success' => false, 'message' => 'OTP already used']);
            exit;
        }
        if (strtotime($otp_row['expiry_time']) < time()) {
            echo json_encode(['success' => false, 'message' => 'OTP expired']);
            exit;
        }
        // Mark OTP as used
    $stmt = $conn->prepare("UPDATE otp_codes SET used = 1 WHERE id = ?");
    $stmt->bind_param('i', $otp_row['id']);
    $stmt->execute();
        // Optionally update last_login
    $stmt = $conn->prepare("UPDATE users SET last_login = NOW() WHERE id = ?");
    $stmt->bind_param('i', $user['id']);
    $stmt->execute();
        // Success response
        echo json_encode([
            'success' => true,
            'message' => 'Login successful! Welcome back.',
            'user' => [
                'id' => $user['id'],
                'name' => $user['name'],
                'email' => $user['email']
            ]
        ]);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'OTP verification failed: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}