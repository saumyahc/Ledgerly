<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

// Load environment variables & connect via mysqli
$env = parse_ini_file(__DIR__ . '/.env');
$servername = $env['DB_HOST'];
$database = $env['DB_DATABASE'];
$username = $env['DB_USERNAME'];
$password = $env['DB_PASSWORD'];
$conn = new mysqli($servername, $username, $password, $database);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed: '.$conn->connect_error]);
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
    
    // Get user profile data
    $sql = "SELECT up.preferred_currency, up.date_of_birth, up.address, up.city, up.country, up.postal_code, up.profile_completed, up.created_at, up.updated_at FROM user_profiles up WHERE up.user_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param('i', $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $profile = $result->fetch_assoc();
        
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