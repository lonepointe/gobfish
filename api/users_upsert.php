<?php
require_once __DIR__ . '/db.php';

header('Content-Type: application/json');

$input = json_decode(file_get_contents('php://input'), true);
$token = $input['access_token'] ?? null;
if (!$token) { http_response_code(400); echo json_encode(['error'=>'missing access_token']); exit; }

// 1) Ask Twitch who this is
$ch = curl_init('https://api.twitch.tv/helix/users');
curl_setopt_array($ch, [
  CURLOPT_RETURNTRANSFER => true,
  CURLOPT_HTTPHEADER => [
    'Authorization: Bearer ' . $token,
    'Client-Id: ' . TWITCH_CLIENT_ID,
  ],
]);
$resp = curl_exec($ch);
$code = curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
curl_close($ch);
if ($code !== 200) { http_response_code(401); echo json_encode(['error'=>'token rejected','details'=>$resp]); exit; }

$payload = json_decode($resp, true);
$u = $payload['data'][0] ?? null;
if (!$u) { http_response_code(401); echo json_encode(['error'=>'no user']); exit; }

$twitch_id      = $u['id'];
$twitch_login   = $u['login'];
$twitch_display = $u['display_name'];
$avatar_url     = $u['profile_image_url'] ?? null;

// 2) Legacy-safe upsert (works on SQLite 3.7.x)
$pdo->beginTransaction();




// Try to find by twitch_id first
$sel = $pdo->prepare("SELECT id FROM users WHERE twitch_id = :tid");
$sel->execute([':tid' => $twitch_id]);
$row = $sel->fetch();

if ($row) {
    // Update existing
    $upd = $pdo->prepare("
        UPDATE users
           SET twitch_login   = :login,
               twitch_display = :display,
               avatar_url     = :avatar,
               updated_at     = CURRENT_TIMESTAMP
         WHERE twitch_id = :tid
    ");
    $upd->execute([
      ':login'   => $twitch_login,
      ':display' => $twitch_display,
      ':avatar'  => $avatar_url,
      ':tid'     => $twitch_id,
    ]);
} else {
    // First attempt: username = twitch_login
    $ins = $pdo->prepare("
        INSERT OR IGNORE INTO users
            (username, subscriber, twitch_id, twitch_login, twitch_display, avatar_url, role, created_at, updated_at)
        VALUES
            (:username, 0, :tid, :login, :display, :avatar, 'player', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    ");
    $ins->execute([
      ':username' => $twitch_login,
      ':tid'      => $twitch_id,
      ':login'    => $twitch_login,
      ':display'  => $twitch_display,
      ':avatar'   => $avatar_url,
    ]);

    // Did it insert? (INSERT OR IGNORE is silent on conflict)
    $changes = (int)$pdo->query("SELECT changes()")->fetchColumn();

    if ($changes === 0) {
        // Likely username collision; try a unique fallback username
        $fallback = $twitch_login . '_' . $twitch_id;
        $ins2 = $pdo->prepare("
            INSERT OR IGNORE INTO users
                (username, subscriber, twitch_id, twitch_login, twitch_display, avatar_url, role, created_at, updated_at)
            VALUES
                (:username, 0, :tid, :login, :display, :avatar, 'player', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        ");
        $ins2->execute([
          ':username' => $fallback,
          ':tid'      => $twitch_id,
          ':login'    => $twitch_login,
          ':display'  => $twitch_display,
          ':avatar'   => $avatar_url,
        ]);

        // If this also didn't insert, something else is wrong (unique twitch_id must succeed)
        $changes2 = (int)$pdo->query("SELECT changes()")->fetchColumn();
        if ($changes2 === 0) {
            $pdo->rollBack();
            http_response_code(409);
            echo json_encode(['error'=>'insert failed (unique constraints)']);
            exit;
        }
    }
}

$pdo->commit();

// Fetch the saved row
$stmt = $pdo->prepare("
  SELECT id, username, subscriber, twitch_id, twitch_login, twitch_display, avatar_url, role
  FROM users
  WHERE twitch_id = :tid
");
$stmt->execute([':tid' => $twitch_id]);
$user = $stmt->fetch();

if (!$user) {
    http_response_code(500);
    echo json_encode(['error' => 'saved row not found']);
    exit;
}

// Start a PHP session and remember the user (HostGator + localhost safe)
if (session_status() !== PHP_SESSION_ACTIVE) {
    session_set_cookie_params([
        'lifetime' => 0,
        'path' => '/',
        'secure' => (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on'),
        'httponly' => true,
        'samesite' => 'Lax',
    ]);
    session_start();
}
$_SESSION['uid'] = (int)$user['id'];

// Single, final JSON response
echo json_encode($user, JSON_UNESCAPED_UNICODE);





