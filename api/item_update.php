<?php
declare(strict_types=1);
header('Content-Type: application/json');
require __DIR__ . '/_auth.php';
require __DIR__ . '/_db.php';

$input = json_decode(file_get_contents('php://input'), true, 512, JSON_THROW_ON_ERROR);
$id    = (int)($input['id'] ?? 0);
$patch = $input['patch'] ?? [];

if ($id < 1 || !is_array($patch)) {
  http_response_code(400); echo json_encode(['error'=>'bad request']); exit;
}

// Only allow specific columns
$allowed = ['name','category','rarity','notes'];
$set = [];
$params = [':id' => $id];
foreach ($patch as $k=>$v) {
  if (in_array($k, $allowed, true)) {
    $set[] = "$k = :$k";
    $params[":$k"] = $v;
  }
}
if (!$set) { echo json_encode(['ok'=>true]); exit; }

$sql = "UPDATE items SET ".implode(',', $set).", updated_at = CURRENT_TIMESTAMP WHERE id = :id";
$stmt = $pdo->prepare($sql);
$stmt->execute($params);

echo json_encode(['ok'=>true]);
