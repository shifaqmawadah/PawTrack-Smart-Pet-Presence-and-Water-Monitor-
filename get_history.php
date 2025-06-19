<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

include 'dbconnect.php'; // make sure this connects correctly

$user_id = isset($_GET['user_id']) ? $_GET['user_id'] : null;
$device_id = isset($_GET['device_id']) ? $_GET['device_id'] : null;

$sql = "SELECT * FROM sensor_data";
$params = [];

if ($user_id && $device_id) {
    $sql .= " WHERE user_id = ? AND device_id = ?";
    $params = [$user_id, $device_id];
} elseif ($user_id) {
    $sql .= " WHERE user_id = ?";
    $params = [$user_id];
} elseif ($device_id) {
    $sql .= " WHERE device_id = ?";
    $params = [$device_id];
}

$sql .= " ORDER BY timestamp DESC"; // latest first

$stmt = $conn->prepare($sql);
if ($params) {
    $types = str_repeat("s", count($params));
    $stmt->bind_param($types, ...$params);
}
$stmt->execute();
$result = $stmt->get_result();

$data = [];
while ($row = $result->fetch_assoc()) {
    $data[] = [
        'id' => $row['id'],
        'user_id' => $row['user_id'],
        'device_id' => $row['device_id'],
        'pir' => $row['pir'],
        'water_level' => $row['water_level'],
        'relay' => $row['relay'],
        'timestamp' => $row['timestamp']
    ];
}

echo json_encode($data);
$conn->close();
