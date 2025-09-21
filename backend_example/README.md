# Ledgerly Backend - OTP System

This directory contains the PHP backend files for the Ledgerly system, including OTP authentication, profile management, and smart contract interaction.

## Files Overview

- `signup.php` - Handles user registration and sends OTP
- `verify_signup_otp.php` - Verifies OTP during sign-up process
- `send_otp.php` - Sends OTP for login verification
- `verify_otp.php` - Verifies OTP during login process
- `database_schema.sql` - Database schema for the OTP system
- `save_profile.php` - Saves user profile data.
- `get_profile.php` - Retrieves user profile data.
- `save_contract.php` - Saves smart contract address associated with a user.
- `get_contract.php` - Retrieves smart contract address associated with a user.
- `email_payment.php` - Handles email payment processing (likely related to smart contracts).
- `debug_save_contract.php` - (Debug) Saves smart contract data, potentially without security checks. **Do not use in production.**
- `wallet_api.php` - Handles wallet-related operations (creation, retrieval, etc.).

## Setup Instructions

### 1. Database Setup

1.  Create a MySQL database
2.  Import the schema from `database_schema.sql`:

    ```bash
    mysql -u your_username -p < database_schema.sql
    ```
3.  Run the migrations in `database_migrations/` and `migrations/` to create the smart_contracts and transactions tables:

    ```bash
    mysql -u your_username -p < database_migrations/smart_contracts_table.sql
    mysql -u your_username -p < migrations/add_transactions_table.sql
    ```

### 2. Configure Database Connection

Update the database configuration in `DatabaseConfig.php`:

```php
<?php
$host = 'localhost';
$dbname = 'ledgerly_db';
$username = 'your_username';
$password = 'your_password';
?>
```