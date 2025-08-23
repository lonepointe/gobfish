<?php
require_once __DIR__ . '/db.php';
require_once __DIR__ . '/_env.php';
header('Content-Type: application/json');

$in   = json_decode(file_get_contents('php://input'), true) ?: [];
$tok  = $in['access_token'] ?? null;
$chan = $in['channel_login'] ?? 'ellipsis_goblins';
if (!$tok) { http_response_code(400); echo json_encode(['error'=>'missing access_token']); exit; }

function http_get($url, $headers) {
  if (function_exists('curl_init')) {
    $ch = curl_init($url);
    curl_setopt_array($ch, [CURLOPT_RETURNTRANSFER=>true, CURLOPT_HTTPHEADER=>$headers]);
    $body = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
    $cerr = curl_error($ch);
    curl_close($ch);
    return [$code, $body, $cerr];
  } else {
    $ctx = stream_context_create(['http'=>['method'=>'GET','header'=>implode("\r\n",$headers),'ignore_errors'=>true,'timeout'=>10]]);
    $body = @file_get_contents($url,false,$ctx);
    $hdr0 = $http_response_header[0] ?? '';
    preg_match('#\s(\d{3})\s#',$hdr0,$m); $code = isset($m[1])?(int)$m[1]:0;
    return [$code,$body,null];
  }
}
$H = fn()=>[
  'Authorization: Bearer ' . $tok,
  'Client-Id: ' . TWITCH_CLIENT_ID,
];

// 1) Who is the viewer?
list($c1,$b1,) = http_get('https://api.twitch.tv/helix/users', $H());
if ($c1 !== 200) { http_response_code(401); echo json_encode(['error'=>'token rejected','http'=>$c1,'body'=>json_decode($b1,true)?:$b1]); exit; }
$viewer = (json_decode($b1,true)['data'][0] ?? null);
if (!$viewer) { http_response_code(401); echo json_encode(['error'=>'no viewer']); exit; }

// 2) Find broadcaster id for the channel login
list($c2,$b2,) = http_get('https://api.twitch.tv/helix/users?login='.rawurlencode($chan), $H());
if ($c2 !== 200) { http_response_code(400); echo json_encode(['error'=>'bad channel lookup','http'=>$c2,'body'=>json_decode($b2,true)?:$b2]); exit; }
$bc = (json_decode($b2,true)['data'][0] ?? null);
if (!$bc) { http_response_code(404); echo json_encode(['error'=>'no such channel','channel'=>$chan]); exit; }

// 3) Check subscription (200 = subscribed, 404 = not)
$url = 'https://api.twitch.tv/helix/subscriptions/user?broadcaster_id='.$bc['id'].'&user_id='.$viewer['id'];
list($c3,$b3,) = http_get($url, $H());

$subscribed = false; $tier = null; $is_gift = null;
if ($c3 === 200) {
  $row = (json_decode($b3,true)['data'][0] ?? null);
  $subscribed = (bool)$row;
  $tier = $row['tier'] ?? null;         // "1000" | "2000" | "3000"
  $is_gift = isset($row['is_gift']) ? (bool)$row['is_gift'] : null;
} elseif ($c3 !== 404) {
  http_response_code($c3); echo $b3; exit;
}

// 4) Persist to DB (uses your users.subscriber flag for THIS channel)
$pdo->prepare("UPDATE users SET subscriber = :s, updated_at = CURRENT_TIMESTAMP WHERE twitch_id = :tid")
    ->execute([':s'=>$subscribed?1:0, ':tid'=>$viewer['id']]);

echo json_encode([
  'viewer_id'      => $viewer['id'],
  'viewer_login'   => $viewer['login'],
  'channel_id'     => $bc['id'],
  'channel_login'  => $bc['login'],
  'subscribed'     => $subscribed,
  'tier'           => $tier,
  'is_gift'        => $is_gift,
]);
