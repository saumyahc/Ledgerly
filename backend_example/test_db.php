<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

$env = parse_ini_file(__DIR__ . '/.env');

$servername = $env['DB_HOST'];
$username   = $env['DB_USERNAME'];
$password   = $env['DB_PASSWORD'];
$database   = $env['DB_DATABASE'];

$conn = new mysqli($servername, $username, $password, $database);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
echo "Connected successfully to database: " . $database;
?>
