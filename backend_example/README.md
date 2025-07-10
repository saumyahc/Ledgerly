# Ledgerly Backend - OTP System

This directory contains the PHP backend files for the Ledgerly OTP (One-Time Password) authentication system.

## Files Overview

- `signup.php` - Handles user registration and sends OTP
- `verify_signup_otp.php` - Verifies OTP during sign-up process
- `send_otp.php` - Sends OTP for login verification
- `verify_otp.php` - Verifies OTP during login process
- `database_schema.sql` - Database schema for the OTP system

## Setup Instructions

### 1. Database Setup

1. Create a MySQL database
2. Import the schema from `database_schema.sql`:
   ```bash
   mysql -u your_username -p < database_schema.sql
   ```

### 2. Configure Database Connection

Update the database configuration in each PHP file:
```php
$host = 'localhost';
$dbname = 'ledgerly_db';
$username = 'your_username';
$password = 'your_password';
```

### 3. Email Configuration

To enable email sending, configure your PHP mail settings:

1. **For local development**, you can use services like:
   - Mailtrap
   - Gmail SMTP
   - SendGrid

2. **Update the mail() function** in the PHP files:
   ```php
   // Uncomment and configure the mail function
   mail($to, $subject, $message, $headers);
   ```

3. **Alternative: Use PHPMailer** for better email handling:
   ```bash
   composer require phpmailer/phpmailer
   ```

### 4. Update Flutter App URLs

Update the API endpoints in your Flutter app:

```dart
// In signup_page.dart
Uri.parse('https://yourdomain.com/signup.php')

// In otp_verification_page.dart
Uri.parse('https://yourdomain.com/verify_signup_otp.php')
Uri.parse('https://yourdomain.com/verify_otp.php')

// In email_verification.dart
Uri.parse('https://yourdomain.com/send_otp.php')
Uri.parse('https://yourdomain.com/verify_otp.php')
```

## API Endpoints

### POST /signup.php
**Request:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "password": "securepassword"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Sign up successful. Please check your email for verification code.",
  "otp": "123456"
}
```

### POST /verify_signup_otp.php
**Request:**
```json
{
  "email": "john@example.com",
  "otp": "123456"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Email verified successfully! Welcome to Ledgerly.",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

### POST /send_otp.php
**Request:**
```json
{
  "email": "john@example.com"
}
```

**Response:**
```json
{
  "success": true,
  "message": "OTP sent successfully. Please check your email.",
  "otp": "123456"
}
```

### POST /verify_otp.php
**Request:**
```json
{
  "email": "john@example.com",
  "otp": "123456"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful! Welcome back.",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

## Security Considerations

1. **HTTPS**: Always use HTTPS in production
2. **Rate Limiting**: Implement rate limiting for OTP requests
3. **OTP Expiry**: OTPs expire after 10 minutes
4. **Password Hashing**: Passwords are hashed using PHP's password_hash()
5. **Input Validation**: All inputs are validated and sanitized
6. **SQL Injection**: Using prepared statements to prevent SQL injection

## Testing

For testing purposes, OTPs are logged to the PHP error log. Check your server's error log to see the generated OTPs.

**Remove the OTP from the response in production!**

## Troubleshooting

1. **Database Connection Error**: Check your database credentials and connection
2. **Email Not Sending**: Configure your mail server or use a service like Mailtrap
3. **CORS Issues**: The files include CORS headers for cross-origin requests
4. **OTP Not Working**: Check the error logs for debugging information

## Production Deployment

1. Remove debug OTP logging
2. Configure proper email service
3. Set up HTTPS
4. Implement rate limiting
5. Add proper error handling
6. Set up monitoring and logging 