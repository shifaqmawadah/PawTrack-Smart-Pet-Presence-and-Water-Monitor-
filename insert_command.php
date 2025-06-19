<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

// Allow preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// Enable error reporting for debugging (remove in production)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

include 'dbconnect.php';

$user_id = $_POST['user_id'];
$device_id = $_POST['device_id'];
$command = $_POST['command']; // e.g., REFILL_WATER or REFILL_FOOD
$relay = $_POST['relay'] ?? 0; // optional

$sql = "INSERT INTO commands (user_id, device_id, command, relay, created_at) 
        VALUES ('$user_id', '$device_id', '$command', '$relay', NOW())";

if (mysqli_query($conn, $sql)) {
  echo json_encode(['success' => true]);
} else {
  echo json_encode(['success' => false, 'error' => mysqli_error($conn)]);
}
?>
