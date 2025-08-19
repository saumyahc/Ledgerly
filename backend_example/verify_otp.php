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

$host = 'localhost';
$dbname = 'ledgerly_db';
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
        $stmt = $pdo->prepare("SELECT id, name, email FROM users WHERE email = ?");
        $stmt->execute([$email]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$user) {
            echo json_encode(['success' => false, 'message' => 'User not found. Please sign up first.']);
            exit;
        }
        // Check OTP
        $stmt = $pdo->prepare("SELECT id, expiry_time, used FROM otp_codes WHERE email = ? AND otp = ? ORDER BY created_at DESC LIMIT 1");
        $stmt->execute([$email, $otp]);
        $otp_row = $stmt->fetch(PDO::FETCH_ASSOC);
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
        $stmt = $pdo->prepare("UPDATE otp_codes SET used = 1 WHERE id = ?");
        $stmt->execute([$otp_row['id']]);
        // Optionally update last_login
        $stmt = $pdo->prepare("UPDATE users SET last_login = NOW() WHERE id = ?");
        $stmt->execute([$user['id']]);
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