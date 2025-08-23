<?php
require_once __DIR__ . '/db.php';
header('Content-Type: application/json');

// start a session (same params you use elsewhere)
if (session_status() !== PHP_SESSION_ACTIVE) {
    session_set_cookie_params([
        'lifetime' => 0,
        'path' => '/',                                  // NOTE: works for /gobfish/* too
        'secure' => (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on'),
        'httponly' => true,
        'samesite' => 'Lax',
    ]);
    session_start();
}

$uid = $_SESSION['uid'] ?? null;
if (!$uid) { http_response_code(401); echo json_encode(['uid'=>null, 'error'=>'no session']); exit; }

$stmt = $pdo->prepare("SELECT id, username, role, subscriber FROM users WHERE id = :id");
$stmt->execute([':id' => (int)$uid]);
echo json_encode(['uid'=>$uid, 'user'=>$stmt->fetch()]);
