<?php
// public/index.php
declare(strict_types=1);

// --- locate db.php (adjust if your layout is different) ---
$db_bootstrap = null;
$try = [__DIR__ . '/../api/db.php', __DIR__ . '/api/db.php'];
foreach ($try as $p) { if (is_file($p)) { $db_bootstrap = $p; break; } }

$pdo = null;
$db_err = null;
if ($db_bootstrap) {
    try {
        require $db_bootstrap; // this should set $pdo
        if (!isset($pdo)) throw new RuntimeException('db.php did not initialize $pdo');
    } catch (Throwable $e) {
        $db_err = $e->getMessage();
        $pdo = null;
    }
} else {
    $db_err = "Could not find api/db.php (tried: " . implode(', ', $try) . ")";
}

// --- fetch last 10 users from DB (if available) ---
$rows = [];
if ($pdo instanceof PDO) {
    try {
        $stmt = $pdo->query("SELECT id, username, twitch_id, twitch_login, twitch_display, avatar_url, subscriber, role, created_at, updated_at
                               FROM users ORDER BY updated_at DESC LIMIT 10");
        $rows = $stmt ? $stmt->fetchAll(PDO::FETCH_ASSOC) : [];
    } catch (Throwable $e) {
        $db_err = $e->getMessage();
    }
}
?>
<!doctype html>
<html lang="en">
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Gobfish — Status</title>
<style>
  body { font:16px/1.45 system-ui,-apple-system,Segoe UI,Roboto,Ubuntu; margin:2rem; color:#ddd; background:#111; }
  .grid { display:grid; gap:1rem; grid-template-columns: 1fr; max-width: 1100px; margin: 0 auto;}
  .card { background:#1b1b1b; border:1px solid #2a2a2a; border-radius:12px; padding:1rem 1.25rem; }
  h1,h2 { margin:.2rem 0 .6rem; }
  table { width:100%; border-collapse:collapse; }
  th, td { border-bottom:1px solid #2a2a2a; padding:.5rem; text-align:left; vertical-align:top; }
  .muted { color:#aaa; font-size:.92rem; }
  .btn { display:inline-block; padding:.55rem .9rem; border-radius:10px; border:1px solid #3a3a3a; background:#222; color:#eee; text-decoration:none; }
  img.avatar { width:48px; height:48px; border-radius:50%; object-fit:cover; }
  pre { background:#0e0e0e; border:1px solid #262626; padding:.75rem; border-radius:10px; overflow:auto; }
  code { color:#c9f; }
</style>

<div class="grid">
  <section class="card">
    <h1>Gobfish — Twitch sign-in</h1>
    <p class="muted">This card shows your live Twitch identity via Helix if a browser token is present. Otherwise, use the button below to connect.</p>
    <div id="auth"></div>
  </section>

  <section class="card">
    <h2>Database — latest users</h2>
    <?php if ($db_err): ?>
      <p><strong>DB error:</strong> <?= htmlspecialchars($db_err, ENT_QUOTES) ?></p>
      <p class="muted">Check <code>api/db.php</code> and <code>api/_env.php</code> paths (DB_PATH), and file perms on your <code>.db</code> file.</p>
    <?php elseif (!$rows): ?>
      <p>No users found yet. After you connect with Twitch on <a class="btn" href="login.html">login.html</a>, refresh this page.</p>
    <?php else: ?>
      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Twitch</th>
            <th>Username</th>
            <th>Role</th>
            <th>Updated</th>
          </tr>
        </thead>
        <tbody>
          <?php foreach ($rows as $r): ?>
          <tr>
            <td><?= (int)$r['id'] ?></td>
            <td>
              <?php if (!empty($r['avatar_url'])): ?>
                <img class="avatar" src="<?= htmlspecialchars($r['avatar_url'], ENT_QUOTES) ?>" alt="">
              <?php endif; ?>
              <div><strong><?= htmlspecialchars($r['twitch_display'] ?? '', ENT_QUOTES) ?></strong></div>
              <div class="muted">@<?= htmlspecialchars($r['twitch_login'] ?? '', ENT_QUOTES) ?> <span> (<?= htmlspecialchars($r['twitch_id'] ?? '', ENT_QUOTES) ?>)</span></div>
            </td>
            <td><?= htmlspecialchars($r['username'] ?? '', ENT_QUOTES) ?></td>
            <td><?= htmlspecialchars($r['role'] ?? '', ENT_QUOTES) ?><?= ((int)$r['subscriber'] ? ' (sub)' : '') ?></td>
            <td class="muted"><?= htmlspecialchars($r['updated_at'] ?? '', ENT_QUOTES) ?></td>
          </tr>
          <?php endforeach; ?>
        </tbody>
      </table>
    <?php endif; ?>
  </section>
</div>

<script type="module">
// ===== Browser-side Helix check (optional) =====
const CLIENT_ID = '6isq54n8of787rxzpoiuwlqq9jaq3k'; // <-- set this to your real Client ID
const token = sessionStorage.twitch_token;
const el = document.getElementById('auth');

function out() {
  el.innerHTML = `
    <p>You are signed out.</p>
    <p><a class="btn" href="login.html">Connect with Twitch</a></p>
    <p class="muted">After connecting, you’ll be redirected and your browser will store a short-lived token in sessionStorage. Then refresh this page.</p>
  `;
}

async function showHelix() {
  try {
    if (!CLIENT_ID || CLIENT_ID === 'YOUR_TWITCH_CLIENT_ID') {
      el.innerHTML = `<p><strong>Missing CLIENT_ID</strong> in <code>index.php</code> script. Set it to your real Twitch Client ID.</p>`;
      return;
    }
    const r = await fetch('https://api.twitch.tv/helix/users', {
      headers: { 'Authorization': 'Bearer ' + token, 'Client-Id': CLIENT_ID }
    });
    if (r.status === 401 || r.status === 400) { sessionStorage.removeItem('twitch_token'); out(); return; }
    if (!r.ok) throw new Error(await r.text());
    const data = await r.json();
    const u = data.data?.[0];
    if (!u) throw new Error('No user in Helix response');

    el.innerHTML = `
      <div style="display:flex;gap:1rem;align-items:center;margin:.25rem 0 1rem">
        <img class="avatar" src="${u.profile_image_url}" alt="">
        <div>
          <div><strong>${u.display_name}</strong> <span class="muted">(@${u.login})</span></div>
          <div class="muted">Twitch ID: ${u.id}</div>
        </div>
      </div>
      <details open>
        <summary><strong>Helix user payload</strong></summary>
        <pre>${JSON.stringify(u, null, 2)}</pre>
      </details>
      <div style="margin-top:.5rem">
        <button class="btn" id="logout">Log out</button>
      </div>
      <p class="muted">Log out clears only the browser token.</p>
    `;
    document.getElementById('logout').onclick = () => { sessionStorage.removeItem('twitch_token'); location.reload(); };
  } catch (e) {
    el.innerHTML = `<p><strong>Error:</strong></p><pre>${String(e)}</pre>
      <p><button class="btn" onclick="sessionStorage.removeItem('twitch_token'); location.reload()">Clear token & retry</button></p>`;
    console.error(e);
  }
}

if (!token) out(); else showHelix();
</script>
