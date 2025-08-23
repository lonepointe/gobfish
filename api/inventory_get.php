<?php
require_once __DIR__ . '/auth.php';
$me = require_user($pdo);

$sql = "
SELECT
  inv.item_id,
  it.name,
  ic.code  AS category,
  r.code   AS rarity,
  inv.owned,
  inv.is_equipped,
  a.code   AS armor_slot,
  w.code   AS weapon_slot
FROM inventory inv
JOIN items it            ON it.id = inv.item_id
JOIN item_categories ic  ON ic.id = it.category_id
LEFT JOIN rarities r     ON r.id = it.rarity_id
LEFT JOIN armor_slots a  ON a.id = inv.equipped_armor_slot_id
LEFT JOIN weapon_slots w ON w.id = inv.equipped_weapon_slot_id
WHERE inv.user_id = :uid
ORDER BY it.name COLLATE NOCASE;
";
$st = $pdo->prepare($sql);
$st->execute([':uid' => $me['id']]);
echo json_encode(['me'=>$me, 'inventory'=>$st->fetchAll()]);
