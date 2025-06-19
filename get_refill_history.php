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

// Fetch refill events
$sql = "SELECT created_at AS timestamp, command 
        FROM commands 
        WHERE user_id = ? AND device_id = ? AND command IN ('REFILL_WATER', 'REFILL_FOOD') 
        ORDER BY created_at DESC";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ii", $user_id, $device_id);
$stmt->execute();
$result = $stmt->get_result();

$refillEvents = [];
while ($row = $result->fetch_assoc()) {
    $refillEvents[] = $row;
}

// Count refill totals
$sqlCount = "SELECT command, COUNT(*) AS count 
             FROM commands 
             WHERE user_id = ? AND device_id = ? AND command IN ('REFILL_WATER', 'REFILL_FOOD') 
             GROUP BY command";
$stmtCount = $conn->prepare($sqlCount);
$stmtCount->bind_param("ii", $user_id, $device_id);
$stmtCount->execute();
$resultCount = $stmtCount->get_result();

$commandCounts = [];
while ($row = $resultCount->fetch_assoc()) {
    $commandCounts[$row['command']] = (int)$row['count'];
}

echo json_encode([
    "refill_events" => $refillEvents,
    "refill_counts" => $commandCounts
]);
?>
