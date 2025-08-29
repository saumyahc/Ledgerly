<?php
error_log("get_profile.php: Request received");
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

// Load environment variables & connect via mysqli
$env = parse_ini_file(__DIR__ . '/.env');
$servername = $env['DB_HOST'];
$database = $env['DB_NAME'];
$username = $env['DB_USER'];
$password = $env['DB_PASS'];
error_log("get_profile.php: Connecting to DB - Host: $servername, Database: $database, User: $username");
$conn = new mysqli($servername, $username, $password, $database);
if ($conn->connect_error) {
    error_log("get_profile.php: DB Connection failed - " . $conn->connect_error);
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed: '.$conn->connect_error]);
    exit;
}
error_log("get_profile.php: DB Connection successful");

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Get user ID from query parameters
    $user_id = $_GET['user_id'] ?? null;
    error_log("get_profile.php: Received user_id = " . ($user_id ?? 'null'));
    
    if (!$user_id) {
        error_log("get_profile.php: User ID is missing");
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'User ID is required']);
        exit;
    }
    
    try {
        // Get user profile data
        $sql = "SELECT up.preferred_currency, up.date_of_birth, up.address, up.city, up.country, up.postal_code, up.wallet_address, up.wallet_created_at, up.profile_completed, up.created_at, up.updated_at FROM user_profiles up WHERE up.user_id = ?";
        error_log("get_profile.php: Executing SQL query for user_id = $user_id");
        $stmt = $conn->prepare($sql);
        $stmt->bind_param('i', $user_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $profile = $result->fetch_assoc();
        error_log("get_profile.php: Query result - " . ($profile ? "Profile found" : "Profile not found"));
            
        if ($profile) {
            error_log("get_profile.php: Profile data: " . json_encode($profile));
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
            error_log("get_profile.php: No profile found, returning default profile");
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
                    'wallet_address' => null,
                    'wallet_created_at' => null,
                    'profile_completed' => false,
                    'created_at' => null,
                    'updated_at' => null
                ]
            ]);
        }
        
    } catch (Exception $e) {
        error_log("get_profile.php: Exception - " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
    
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}
?>