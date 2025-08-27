<?php
declare(strict_types=1);
header('Content-Type: application/json');
require __DIR__ . '/_auth.php';
require __DIR__ . '/_db.php';

$id = (int)($_GET['id'] ?? 0);
if ($id < 1) { http_response_code(400); echo json_encode(['error'=>'bad id']); exit; }

$stmt = $pdo->prepare("DELETE FROM items WHERE id = :id");
$stmt->execute([':id'=>$id]);
echo json_encode(['ok'=>true]);
