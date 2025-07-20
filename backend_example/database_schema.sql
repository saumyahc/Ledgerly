-- Create database
CREATE DATABASE IF NOT EXISTS ledgerly_db;
USE ledgerly_db;

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    password VARCHAR(255) NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP NULL,
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_phone (phone)
);

-- OTP codes table
CREATE TABLE IF NOT EXISTS otp_codes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    email VARCHAR(255) NOT NULL,
    otp VARCHAR(6) NOT NULL,
    expiry_time TIMESTAMP NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_email_otp (email, otp),
    INDEX idx_expiry (expiry_time),
    INDEX idx_user_id (user_id)
);

-- View for active OTPs (not expired, not used, and user exists)
CREATE OR REPLACE VIEW active_otps AS
SELECT 
    oc.id,
    oc.user_id,
    oc.email,
    oc.otp,
    oc.expiry_time,
    oc.created_at,
    u.name AS user_name,
    u.email_verified
FROM otp_codes oc
JOIN users u ON oc.user_id = u.id
WHERE oc.expiry_time > NOW() AND oc.used = FALSE;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_otp_codes_email_expiry ON otp_codes(email, expiry_time);
CREATE INDEX IF NOT EXISTS idx_users_email_verified ON users(email, email_verified);

-- (Optional) For testing: Insert a sample user
-- INSERT INTO users (name, email, phone, password, email_verified) VALUES 
-- ('Test User', 'test@example.com', '+1234567890', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', TRUE);
