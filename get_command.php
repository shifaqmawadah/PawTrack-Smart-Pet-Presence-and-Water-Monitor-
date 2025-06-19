<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

include 'dbconnect.php';

$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
$device_id = isset($_GET['device_id']) ? intval($_GET['device_id']) : 0;

if ($user_id === 0 || $device_id === 0) {
    echo json_encode(["error" => "Missing user_id or device_id"]);
    exit;
}

// Get the latest unprocessed command
$stmt = $conn->prepare("SELECT id, command FROM commands WHERE user_id=? AND device_id=? AND processed=0 ORDER BY id ASC LIMIT 1");
$stmt->bind_param("ii", $user_id, $device_id);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    echo json_encode(["command" => $row['command']]);

    // Mark as processed
    $update = $conn->prepare("UPDATE commands SET processed=1 WHERE id=?");
    $update->bind_param("i", $row['id']);
    $update->execute();
} else {
    echo json_encode(["command" => ""]);
}
?>
