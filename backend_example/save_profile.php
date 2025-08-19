<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
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

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get JSON input
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid JSON input']);
        exit;
    }
    
    // Extract and validate required fields
    $user_id = $input['user_id'] ?? null;
    $preferred_currency = $input['preferred_currency'] ?? 'USD';
    $date_of_birth = $input['date_of_birth'] ?? null;
    $address = $input['address'] ?? null;
    $city = $input['city'] ?? null;
    $country = $input['country'] ?? null;
    $postal_code = $input['postal_code'] ?? null;
    
    // Validate required fields
    $errors = [];
    
    if (!$user_id) {
        $errors[] = 'User ID is required';
    }
    
    if (!$address || trim($address) === '') {
        $errors[] = 'Address is required';
    }
    
    if (!$city || trim($city) === '') {
        $errors[] = 'City is required';
    }
    
    if (!$country || trim($country) === '') {
        $errors[] = 'Country is required';
    }
    
    // Validate currency
    $valid_currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY'];
    if (!in_array($preferred_currency, $valid_currencies)) {
        $errors[] = 'Invalid preferred currency';
    }
    
    // Validate date of birth format if provided
    if ($date_of_birth && !empty($date_of_birth)) {
        $date_obj = DateTime::createFromFormat('d/m/Y', $date_of_birth);
        if (!$date_obj || $date_obj->format('d/m/Y') !== $date_of_birth) {
            $errors[] = 'Invalid date of birth format. Use DD/MM/YYYY';
        }
    }
    
    if (!empty($errors)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => implode(', ', $errors)]);
        exit;
    }
    
    try {
        // Check if user exists
        $stmt = $pdo->prepare("SELECT id FROM users WHERE id = ?");
        $stmt->execute([$user_id]);
        
        if (!$stmt->fetch()) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'User not found']);
            exit;
        }
        
        // Convert date format for database storage
        $db_date_of_birth = null;
        if ($date_of_birth && !empty($date_of_birth)) {
            $date_obj = DateTime::createFromFormat('d/m/Y', $date_of_birth);
            $db_date_of_birth = $date_obj->format('Y-m-d');
        }
        
        // Check if profile already exists
        $stmt = $pdo->prepare("SELECT id FROM user_profiles WHERE user_id = ?");
        $stmt->execute([$user_id]);
        $existing_profile = $stmt->fetch();
        
        if ($existing_profile) {
            // Update existing profile
            $stmt = $pdo->prepare("
                UPDATE user_profiles 
                SET preferred_currency = ?, 
                    date_of_birth = ?, 
                    address = ?, 
                    city = ?, 
                    country = ?, 
                    postal_code = ?,
                    profile_completed = TRUE,
                    updated_at = CURRENT_TIMESTAMP
                WHERE user_id = ?
            ");
            
            $stmt->execute([
                $preferred_currency,
                $db_date_of_birth,
                $address,
                $city,
                $country,
                $postal_code,
                $user_id
            ]);
        } else {
            // Insert new profile
            $stmt = $pdo->prepare("
                INSERT INTO user_profiles 
                (user_id, preferred_currency, date_of_birth, address, city, country, postal_code, profile_completed)
                VALUES (?, ?, ?, ?, ?, ?, ?, TRUE)
            ");
            
            $stmt->execute([
                $user_id,
                $preferred_currency,
                $db_date_of_birth,
                $address,
                $city,
                $country,
                $postal_code
            ]);
        }
        
        echo json_encode([
            'success' => true, 
            'message' => 'Profile saved successfully',
            'profile_completed' => true
        ]);
        
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
    
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}
?> 