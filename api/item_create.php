<?php
declare(strict_types=1);
header('Content-Type: application/json');
require __DIR__ . '/_auth.php';
require __DIR__ . '/_db.php';

$input = json_decode(file_get_contents('php://input'), true, 512, JSON_THROW_ON_ERROR);
$name = trim((string)($input['name'] ?? ''));
if ($name === '') { http_response_code(400); echo json_encode(['error'=>'name required']); exit; }

$stmt = $pdo->prepare("INSERT INTO items (name,category,rarity,notes,updated_at)
                       VALUES (:n,:c,:r,:no,CURRENT_TIMESTAMP)");
$stmt->execute([
  ':n'=>$name,
  ':c'=>trim((string)($input['category'] ?? 'misc')),
  ':r'=>trim((string)($input['rarity'] ?? 'common')),
  ':no'=>trim((string)($input['notes'] ?? '')),
]);

echo json_encode(['id'=>(int)$pdo->lastInsertId()]);
