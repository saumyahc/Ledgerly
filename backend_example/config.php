<?php
/**
 * Database configuration for Ledgerly Backend
 * Uses the same credentials as .env file for consistency
 */

// Load environment variables from .env file
$env = parse_ini_file(__DIR__ . '/.env');

// Database configuration variables
$host = $env['DB_HOST'];
$dbname = $env['DB_NAME'];
$username = $env['DB_USER'];
$password = $env['DB_PASS'];

// Ensure these variables are available globally
$GLOBALS['db_config'] = [
    'host' => $host,
    'dbname' => $dbname,
    'username' => $username,
    'password' => $password
];
?>