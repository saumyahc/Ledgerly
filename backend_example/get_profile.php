<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

// Database configuration
$host = 'localhost';
$dbname = 'ledgerly_db';
$username = 'root';
$password = '';

try {
    // Create PDO connection
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Get user ID from query parameters
    $user_id = $_GET['user_id'] ?? null;
    
    if (!$user_id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'User ID is required']);
        exit;
    }
    
    try {
        // Get user profile data
        $stmt = $pdo->prepare("
            SELECT 
                up.preferred_currency,
                up.date_of_birth,
                up.address,
                up.city,
                up.country,
                up.postal_code,
                up.profile_completed,
                up.created_at,
                up.updated_at
            FROM user_profiles up
            WHERE up.user_id = ?
        ");
        
        $stmt->execute([$user_id]);
        $profile = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($profile) {
            // Convert date format for frontend
            if ($profile['date_of_birth']) {
                $date_obj = DateTime::createFromFormat('Y-m-d', $profile['date_of_birth']);
                $profile['date_of_birth'] = $date_obj->format('d/m/Y');
            }
            
            echo json_encode([
                'success' => true,
                'profile' => $profile
            ]);
        } else {
            // Return empty profile structure
            echo json_encode([
                'success' => true,
                'profile' => [
                    'preferred_currency' => 'USD',
                    'date_of_birth' => '',
                    'address' => '',
                    'city' => '',
                    'country' => '',
                    'postal_code' => '',
                    'profile_completed' => false,
                    'created_at' => null,
                    'updated_at' => null
                ]
            ]);
        }
        
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
    
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}
?> 