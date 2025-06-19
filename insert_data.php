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

// Input validation and null checks
$user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : null;
$device_id = isset($_POST['device_id']) ? intval($_POST['device_id']) : null;
$pir = isset($_POST['pir']) ? intval($_POST['pir']) : null;
$water = isset($_POST['water']) ? intval($_POST['water']) : null;

if ($user_id === null || $device_id === null || $pir === null || $water === null) {
    echo json_encode(["success" => false, "message" => "Missing parameters"]);
    exit;
}

$stmt = $conn->prepare("INSERT INTO sensor_data (user_id, device_id, pir, water_level, relay) VALUES (?, ?, ?, ?, 0)");

if (!$stmt) {
    echo json_encode(["success" => false, "message" => "Prepare failed: " . $conn->error]);
    exit;
}

$stmt->bind_param("iiii", $user_id, $device_id, $pir, $water);

if ($stmt->execute()) {
    echo json_encode(["success" => true, "message" => "Data inserted successfully"]);
} else {
    echo json_encode(["success" => false, "message" => "Execute failed: " . $stmt->error]);
}

$stmt->close();
$conn->close();
?>