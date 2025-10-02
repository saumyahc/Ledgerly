# Ledgerly Backend

This directory contains the PHP backend files for the Ledgerly system, including OTP authentication, profile management, wallet and contract management, payment processing, and transaction history.

## Files Overview

- `signup.php` - Handles user registration and sends OTP.
- `verify_signup_otp.php` - Verifies OTP during sign-up process.
- `send_otp.php` - Sends OTP for login verification.
- `verify_otp.php` - Verifies OTP during login process.
- `database_schema.sql` - Main database schema for users, profiles, and OTP system.
- `save_profile.php` - Saves user profile data.
- `get_profile.php` - Retrieves user profile data by user ID, email, or wallet address.
- `save_contract.php` - Saves smart contract address associated with a user.
- `get_contract.php` - Retrieves smart contract address associated with a user.
- `email_payment.php` - Handles email-based payment lookup and wallet mapping.
- `wallet_api.php` - Handles wallet-related operations (creation, retrieval, linking, etc.).
- `transaction_api.php` - Manages transaction recording, status updates, history, pending transactions, and summaries.
- `test_db.php` - Simple script to test database connectivity.
- `config.php` / `.env` - Database and environment configuration.
- `database_migrations/` - Migration scripts for smart contracts and deployments.
- `migrations/` - Migration scripts for transactions and enhanced transaction schema.
- `src/` - Supporting libraries (PHPMailer, OAuth, etc.).
- `Ledgerly_API_Tests.postman_collection.json` - Postman collection for API testing.
- `Ledgerly_Profile_API_Tests.postman_collection.json` - Postman collection for profile API testing.
- `README_PROFILE_SYSTEM.md` - Additional documentation for the profile system.

## Transaction & Payment System

- **Transactions:**  
  - Recorded via `transaction_api.php` with sender/receiver IDs, emails, amount, status, and memo.
  - Status can be updated (pending, completed, failed).
  - History and summary endpoints available for analytics and user history.
- **Email Payments:**  
  - `email_payment.php` resolves email to wallet address for payments.
  - Used for sending ETH to users via their registered email.

## Smart Contract Management

- **Contracts:**  
  - Users can save and retrieve their smart contract addresses.
  - Contract deployment tracking via migration scripts.

## OTP & Profile System

- **OTP:**  
  - Registration and login flows use OTP verification.
  - Secure user onboarding and authentication.
- **Profiles:**  
  - Users can save and retrieve profile information.
  - Lookup by user ID, email, or wallet address.

## Setup Instructions

### 1. Database Setup

1. Create a MySQL database.
2. Import the schema from `database_schema.sql`:

    ```bash
    mysql -u your_username -p < database_schema.sql
    ```
3. Run the migrations in `database_migrations/` and `migrations/` to create the smart_contracts and transactions tables:

    ```bash
    mysql -u your_username -p < database_migrations/smart_contracts_table.sql
    mysql -u your_username -p < migrations/add_transactions_table.sql
    mysql -u your_username -p < migrations/enhanced_transactions_table.sql
    ```

### 2. Configure Database Connection

Update the database configuration in `config.php` or `.env`:

```php
<?php
$host = 'localhost';
$dbname = 'ledgerly_db';
$username = 'your_username';
$password = 'your_password';
?>
```