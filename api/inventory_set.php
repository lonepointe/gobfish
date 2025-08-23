<?php
require_once __DIR__ . '/auth.php';
$me = require_user($pdo);

$in = json_decode(file_get_contents('php://input'), true) ?: [];
$action  = $in['action']  ?? null;      // 'equip' | 'unequip'
$item_id = isset($in['item_id']) ? (int)$in['item_id'] : 0;
$hand    = $in['hand']    ?? null;      // 'mainhand' | 'offhand' (for 1-handed weapons)

if (!$action || !$item_id) { http_response_code(400); echo json_encode(['error'=>'bad request']); exit; }

$pdo->beginTransaction();

// Load item with category + stats
$it = $pdo->prepare("
  SELECT it.id, ic.code AS category, 
         (SELECT slot_id FROM armor_stats  WHERE item_id = it.id) AS armor_slot_id,
         (SELECT hands   FROM weapon_stats WHERE item_id = it.id) AS weapon_hands
  FROM items it
  JOIN item_categories ic ON ic.id = it.category_id
  WHERE it.id = :iid
")->execute([':iid'=>$item_id]) ?: null;

$row = $pdo->query("SELECT it.id, ic.code AS category,
         (SELECT slot_id FROM armor_stats  WHERE item_id = $item_id) AS armor_slot_id,
         (SELECT hands   FROM weapon_stats WHERE item_id = $item_id) AS weapon_hands
  FROM items it JOIN item_categories ic ON ic.id = it.category_id
  WHERE it.id = $item_id")->fetch();

if (!$row) { $pdo->rollBack(); http_response_code(404); echo json_encode(['error'=>'no such item']); exit; }

// Ensure the user owns the item row
$own = $pdo->prepare("SELECT id FROM inventory WHERE user_id=:u AND item_id=:i");
$own->execute([':u'=>$me['id'], ':i'=>$item_id]);
if (!$own->fetch()) { $pdo->rollBack(); http_response_code(403); echo json_encode(['error'=>'not in inventory']); exit; }

if ($action === 'unequip') {
    $pdo->prepare("UPDATE inventory
                      SET is_equipped=0,
                          equipped_armor_slot_id=NULL,
                          equipped_weapon_slot_id=NULL,
                          updated_at=CURRENT_TIMESTAMP
                    WHERE user_id=:u AND item_id=:i")
        ->execute([':u'=>$me['id'], ':i'=>$item_id]);
} elseif ($action === 'equip') {
    if ($row['category'] === 'armor') {
        $slot_id = (int)$row['armor_slot_id'];
        if (!$slot_id) { $pdo->rollBack(); http_response_code(400); echo json_encode(['error'=>'armor slot unknown']); exit; }
        // one item per armor slot: clear anything in that slot
        $pdo->prepare("UPDATE inventory SET is_equipped=0, equipped_armor_slot_id=NULL, updated_at=CURRENT_TIMESTAMP
                        WHERE user_id=:u AND equipped_armor_slot_id=:s")->execute([':u'=>$me['id'], ':s'=>$slot_id]);
        // equip this armor
        $pdo->prepare("UPDATE inventory
                          SET is_equipped=1,
                              equipped_armor_slot_id=:s,
                              equipped_weapon_slot_id=NULL,
                              updated_at=CURRENT_TIMESTAMP
                        WHERE user_id=:u AND item_id=:i")
            ->execute([':u'=>$me['id'], ':i'=>$item_id, ':s'=>$slot_id]);
    } elseif ($row['category'] === 'weapon') {
        // choose weapon slot id
        if ((int)$row['weapon_hands'] === 2) {
            $code = 'both';
        } else {
            $code = ($hand === 'offhand') ? 'offhand' : 'mainhand';
        }
        $slot_id = $pdo->prepare("SELECT id FROM weapon_slots WHERE code=:c");
        $slot_id->execute([':c'=>$code]);
        $slot_id = (int)($slot_id->fetch()['id'] ?? 0);
        if (!$slot_id) { $pdo->rollBack(); http_response_code(400); echo json_encode(['error'=>'weapon slot unknown']); exit; }
        // one item per chosen weapon slot
        $pdo->prepare("UPDATE inventory SET is_equipped=0, equipped_weapon_slot_id=NULL, updated_at=CURRENT_TIMESTAMP
                        WHERE user_id=:u AND equipped_weapon_slot_id=:s")->execute([':u'=>$me['id'], ':s'=>$slot_id]);
        // equip this weapon
        $pdo->prepare("UPDATE inventory
                          SET is_equipped=1,
                              equipped_weapon_slot_id=:s,
                              equipped_armor_slot_id=NULL,
                              updated_at=CURRENT_TIMESTAMP
                        WHERE user_id=:u AND item_id=:i")
            ->execute([':u'=>$me['id'], ':i'=>$item_id, ':s'=>$slot_id]);
    } else {
        $pdo->rollBack(); http_response_code(400); echo json_encode(['error'=>'cannot equip this category']); exit;
    }
} else {
    $pdo->rollBack(); http_response_code(400); echo json_encode(['error'=>'unknown action']); exit;
}

$pdo->commit();

// return fresh record
$st = $pdo->prepare("
  SELECT inv.item_id, it.name, ic.code AS category, inv.is_equipped,
         a.code AS armor_slot, w.code AS weapon_slot
    FROM inventory inv
    JOIN items it            ON it.id = inv.item_id
    JOIN item_categories ic  ON ic.id = it.category_id
    LEFT JOIN armor_slots a  ON a.id = inv.equipped_armor_slot_id
    LEFT JOIN weapon_slots w ON w.id = inv.equipped_weapon_slot_id
   WHERE inv.user_id=:u AND inv.item_id=:i
");
$st->execute([':u'=>$me['id'], ':i'=>$item_id]);
echo json_encode($st->fetch());
