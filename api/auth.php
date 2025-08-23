<?php
require_once __DIR__ . '/db.php';

header('Content-Type: application/json');

if (session_status() !== PHP_SESSION_ACTIVE) {
    session_set_cookie_params([
        'lifetime' => 0, 'path' => '/',
        'secure' => isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on',
        'httponly' => true, 'samesite' => 'Lax',
    ]);
    session_start();
}

function require_user(PDO $pdo) {
    if (empty($_SESSION['uid'])) {
        http_response_code(401);
        echo json_encode(['error' => 'unauthenticated']);
        exit;
    }
    $st = $pdo->prepare("SELECT id, username, role, subscriber FROM users WHERE id = :id");
    $st->execute([':id' => (int)$_SESSION['uid']]);
    $me = $st->fetch();
    if (!$me) {
        http_response_code(401);
        echo json_encode(['error' => 'no such user']);
        exit;
    }
    return $me;
}
