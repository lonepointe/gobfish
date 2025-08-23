<?php
require_once __DIR__ . '/db.php';
header('Content-Type: application/json');

$input = json_decode(file_get_contents('php://input'), true);
$twitch_id = $input['twitch_id'] ?? null;

if (!$twitch_id) { http_response_code(400); echo json_encode(['error'=>'missing twitch_id']); exit; }

$stmt = $pdo->prepare("SELECT id, username, subscriber, twitch_id, twitch_login, twitch_display, avatar_url, role, created_at, updated_at
                         FROM users WHERE twitch_id = :tid");
$stmt->execute([':tid' => $twitch_id]);
$row = $stmt->fetch();

if (!$row) { http_response_code(404); echo json_encode(['error' => 'not found']); exit; }
echo json_encode($row);
