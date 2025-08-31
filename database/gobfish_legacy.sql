PRAGMA foreign_keys = ON;

BEGIN;

/* =========================
   LOOKUP TABLES
   ========================= */












/*what the fuck do we need catagories for?  we don't.


CREATE TABLE IF NOT EXISTS item_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,
  label TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1
);

*/

-- rarities yes we need.
-- this holds the text for rarities, like common, unrare, rare, etc.
-- for the dropdown, to enforce data format.

CREATE TABLE IF NOT EXISTS rarities (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1
);


/* rarities */
INSERT OR IGNORE INTO rarities(code,label,sort_order,is_active) VALUES ('common','Common',10,1);
UPDATE rarities SET label='Common', sort_order=10, is_active=1 WHERE code='common';
INSERT OR IGNORE INTO rarities(code,label,sort_order,is_active) VALUES ('uncommon','Uncommon',15,1);
UPDATE rarities SET label='Uncommon', sort_order=15, is_active=1 WHERE code='uncommon';
INSERT OR IGNORE INTO rarities(code,label,sort_order,is_active) VALUES ('rare','Rare',20,1);
UPDATE rarities SET label='Rare', sort_order=20, is_active=1 WHERE code='rare';
INSERT OR IGNORE INTO rarities(code,label,sort_order,is_active) VALUES ('epic','Epic',30,1);
UPDATE rarities SET label='Epic', sort_order=30, is_active=1 WHERE code='epic';
INSERT OR IGNORE INTO rarities(code,label,sort_order,is_active) VALUES ('legendary','Legendary',40,1);
UPDATE rarities SET label='Legendary', sort_order=40, is_active=1 WHERE code='legendary';



CREATE TABLE IF NOT EXISTS  ( groups
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  group_name TEXT NOT NULL UNIQUE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  group_value INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1

);

/* group_name */
-- need more info, groups.
INSERT OR IGNORE INTO groups(group_name,sort_order, group_value, is_active) VALUES ('',10,0);
UPDATE groups SET group_name='LDdaggars', 35, sort_order=10, is_active=0;
INSERT OR IGNORE INTO groups(group_name, 69, sort_order,is_active) VALUES ('',10,0);
UPDATE groups SET group_name='buggerall', sort_order=20, is_active=0;




-- names the armour slots for the dropdown.  I could hard code this, but meh.

CREATE TABLE IF NOT EXISTS armour_slots (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,
  label TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1
);

/* armor_slots */
INSERT OR IGNORE INTO armor_slots(code,label,sort_order,is_active) VALUES ('head','Head',10,1);
UPDATE armor_slots SET label='Head', sort_order=10, is_active=1 WHERE code='head';
INSERT OR IGNORE INTO armor_slots(code,label,sort_order,is_active) VALUES ('shoulders','Shoulders',20,1);
UPDATE armor_slots SET label='Shoulders', sort_order=20, is_active=1 WHERE code='shoulders';
INSERT OR IGNORE INTO armor_slots(code,label,sort_order,is_active) VALUES ('back','Back',30,1);
UPDATE armor_slots SET label='Back', sort_order=30, is_active=1 WHERE code='back';
INSERT OR IGNORE INTO armor_slots(code,label,sort_order,is_active) VALUES ('face','Face',40,1);
UPDATE armor_slots SET label='Face', sort_order=40, is_active=1 WHERE code='face';
INSERT OR IGNORE INTO armor_slots(code,label,sort_order,is_active) VALUES ('torso','Torso',50,1);
UPDATE armor_slots SET label='Torso', sort_order=50, is_active=1 WHERE code='torso';
INSERT OR IGNORE INTO armor_slots(code,label,sort_order,is_active) VALUES ('hands','Hands',60,1);
UPDATE armor_slots SET label='Hands', sort_order=60, is_active=1 WHERE code='hands';
INSERT OR IGNORE INTO armor_slots(code,label,sort_order,is_active) VALUES ('legs','Legs',70,1);
UPDATE armor_slots SET label='Legs', sort_order=70, is_active=1 WHERE code='legs';
INSERT OR IGNORE INTO armor_slots(code,label,sort_order,is_active) VALUES ('feet','Feet',80,1);
UPDATE armor_slots SET label='Feet', sort_order=80, is_active=1 WHERE code='feet';



-- names the weapon slots for the dropdown.

CREATE TABLE IF NOT EXISTS weapon_slots (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,
  label TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1
);

/* weapon_slots */
INSERT OR IGNORE INTO weapon_slots(code,label,sort_order,is_active) VALUES ('mainhand','Main Hand',10,1);
UPDATE weapon_slots SET label='Main Hand', sort_order=10, is_active=1 WHERE code='mainhand';
INSERT OR IGNORE INTO weapon_slots(code,label,sort_order,is_active) VALUES ('offhand','Off Hand',20,1);
UPDATE weapon_slots SET label='Off Hand', sort_order=20, is_active=1 WHERE code='offhand';
INSERT OR IGNORE INTO weapon_slots(code,label,sort_order,is_active) VALUES ('both','Two-Handed',30,1);
UPDATE weapon_slots SET label='Two-Handed', sort_order=30, is_active=1 WHERE code='both';


-- track if an encounter is active or resolved.

CREATE TABLE IF NOT EXISTS encounter_statuses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,
  label TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1
);

/* encounter_statuses */
INSERT OR IGNORE INTO encounter_statuses(code,label,sort_order,is_active) VALUES ('active','Active',10,1);
UPDATE encounter_statuses SET label='Active', sort_order=10, is_active=1 WHERE code='active';
INSERT OR IGNORE INTO encounter_statuses(code,label,sort_order,is_active) VALUES ('resolved','Resolved',20,1);
UPDATE encounter_statuses SET label='Resolved', sort_order=20, is_active=1 WHERE code='resolved';

-- reasons for inventory changes, like loot, reward, purchase, admin, etc.
-- not sure why we need this, but ok.
CREATE TABLE IF NOT EXISTS inventory_event_reasons (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,
  label TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1
);



/* =========================
   CORE TABLES
   ========================= */


-- obviously we need users.
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  subscriber INTEGER NOT NULL DEFAULT 0,      -- 0/1
  twitch_id      TEXT UNIQUE,
  twitch_login   TEXT,
  twitch_display TEXT,
  avatar_url     TEXT,
  role TEXT NOT NULL DEFAULT 'player' CHECK (role IN ('player','dm')),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_users_twitch_login ON users(twitch_login);



-- track item sets, for set bonuses.
CREATE TABLE IF NOT EXISTS item_sets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  set_bonus_value INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);






CREATE TABLE IF NOT EXISTS items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  category_id INTEGER NOT NULL REFERENCES item_categories(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  rarity_id   INTEGER NOT NULL REFERENCES rarities(id)        ON UPDATE RESTRICT ON DELETE RESTRICT,
  set_id      INTEGER REFERENCES item_sets(id)                ON UPDATE RESTRICT ON DELETE SET NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  sprite_json TEXT,
  special     TEXT,
  tooltip     TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_items_category_id ON items(category_id);
CREATE INDEX IF NOT EXISTS idx_items_rarity_id   ON items(rarity_id);
CREATE INDEX IF NOT EXISTS idx_items_set_id      ON items(set_id);




CREATE TABLE IF NOT EXISTS armor_stats (
  item_id INTEGER PRIMARY KEY REFERENCES items(id) ON UPDATE RESTRICT ON DELETE CASCADE,
  slot_id INTEGER NOT NULL REFERENCES armor_slots(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_armor_stats_slot_id ON armor_stats(slot_id);

/*
-- not sure if we need hands, but whatever.
CREATE TABLE IF NOT EXISTS weapon_stats (
  item_id INTEGER PRIMARY KEY REFERENCES items(id) ON UPDATE RESTRICT ON DELETE CASCADE,
  hands        INTEGER NOT NULL DEFAULT 1 CHECK (hands IN (1,2,3)),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

*/

-- user inventory, what they own.
CREATE TABLE IF NOT EXISTS inventory (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id) ON UPDATE RESTRICT ON DELETE CASCADE,
  item_id INTEGER NOT NULL REFERENCES items(id) ON UPDATE RESTRICT ON DELETE CASCADE,
  owned INTEGER NOT NULL DEFAULT 1 CHECK (owned >= 0),
  is_equipped INTEGER NOT NULL DEFAULT 0,
  equipped_armor_slot_id  INTEGER REFERENCES armor_slots(id)  ON UPDATE RESTRICT ON DELETE SET NULL,
  equipped_weapon_slot_id INTEGER REFERENCES weapon_slots(id) ON UPDATE RESTRICT ON DELETE SET NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, item_id),
  CHECK (equipped_armor_slot_id IS NULL OR equipped_weapon_slot_id IS NULL)
);
CREATE INDEX IF NOT EXISTS idx_inventory_user_id ON inventory(user_id);
CREATE INDEX IF NOT EXISTS idx_inventory_item_id ON inventory(item_id);

CREATE TABLE IF NOT EXISTS npcs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  is_hostile INTEGER NOT NULL DEFAULT 1,
  value      INTEGER NOT NULL DEFAULT 0,
  sprite_json TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS encounters (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  npc_id INTEGER NOT NULL REFERENCES npcs(id) ON UPDATE RESTRICT ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON UPDATE RESTRICT ON DELETE CASCADE,
  status_id INTEGER NOT NULL DEFAULT 1 REFERENCES encounter_statuses(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  start_time TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  end_time   TEXT,
  is_won     INTEGER NOT NULL DEFAULT 0,
  is_active  INTEGER NOT NULL DEFAULT 1,
  snapshot_json TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(npc_id, user_id, start_time)
);
CREATE INDEX IF NOT EXISTS idx_encounters_user_id ON encounters(user_id);
CREATE INDEX IF NOT EXISTS idx_encounters_npc_id  ON encounters(npc_id);
CREATE INDEX IF NOT EXISTS idx_encounters_status  ON encounters(status_id);


CREATE TABLE IF NOT EXISTS user_npcs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id) ON UPDATE RESTRICT ON DELETE CASCADE,
  npc_id  INTEGER NOT NULL REFERENCES npcs(id)  ON UPDATE RESTRICT ON DELETE CASCADE,
  is_friendly INTEGER NOT NULL DEFAULT 0,
  bonus_vs    INTEGER NOT NULL DEFAULT 0,
  wins        INTEGER NOT NULL DEFAULT 0,
  losses      INTEGER NOT NULL DEFAULT 0,
  last_encounter_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, npc_id)
);
CREATE INDEX IF NOT EXISTS idx_user_npcs_user ON user_npcs(user_id);
CREATE INDEX IF NOT EXISTS idx_user_npcs_npc  ON user_npcs(npc_id);


CREATE TABLE IF NOT EXISTS inventory_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id) ON UPDATE RESTRICT ON DELETE CASCADE,
  item_id INTEGER NOT NULL REFERENCES items(id) ON UPDATE RESTRICT ON DELETE CASCADE,
  qty_change INTEGER NOT NULL DEFAULT 1,
  reason_id  INTEGER NOT NULL REFERENCES inventory_event_reasons(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  encounter_id INTEGER REFERENCES encounters(id) ON UPDATE RESTRICT ON DELETE SET NULL,
  applied_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_inv_events_user_id   ON inventory_events(user_id);
CREATE INDEX IF NOT EXISTS idx_inv_events_item_id   ON inventory_events(item_id);
CREATE INDEX IF NOT EXISTS idx_inv_events_reason_id ON inventory_events(reason_id);
CREATE INDEX IF NOT EXISTS idx_inv_events_enc_id    ON inventory_events(encounter_id);

/* =========================
   SEED LOOKUPS (legacy-safe)
   ========================= */

/* rarities */
INSERT OR IGNORE INTO rarities(code,label,sort_order,is_active) VALUES ('common','Common',10,1);
UPDATE rarities SET label='Common', sort_order=10, is_active=1 WHERE code='common';
INSERT OR IGNORE INTO rarities(code,label,sort_order,is_active) VALUES ('uncommon','Uncommon',15,1);
UPDATE rarities SET label='Uncommon', sort_order=15, is_active=1 WHERE code='uncommon';
INSERT OR IGNORE INTO rarities(code,label,sort_order,is_active) VALUES ('rare','Rare',20,1);
UPDATE rarities SET label='Rare', sort_order=20, is_active=1 WHERE code='rare';
INSERT OR IGNORE INTO rarities(code,label,sort_order,is_active) VALUES ('epic','Epic',30,1);
UPDATE rarities SET label='Epic', sort_order=30, is_active=1 WHERE code='epic';
INSERT OR IGNORE INTO rarities(code,label,sort_order,is_active) VALUES ('legendary','Legendary',40,1);
UPDATE rarities SET label='Legendary', sort_order=40, is_active=1 WHERE code='legendary';

/* armor_slots */
INSERT OR IGNORE INTO armor_slots(code,label,sort_order,is_active) VALUES ('head','Head',10,1);
UPDATE armor_slots SET label='Head', sort_order=10, is_active=1 WHERE code='head';
INSERT OR IGNORE INTO armor_slots(code,label,sort_order,is_active) VALUES ('shoulders','Shoulders',20,1);
UPDATE armor_slots SET label='Shoulders', sort_order=20, is_active=1 WHERE code='shoulders';
INSERT OR IGNORE INTO armor_slots(code,label,sort_order,is_active) VALUES ('back','Back',30,1);
UPDATE armor_slots SET label='Back', sort_order=30, is_active=1 WHERE code='back';
INSERT OR IGNORE INTO armor_slots(code,label,sort_order,is_active) VALUES ('face','Face',40,1);
UPDATE armor_slots SET label='Face', sort_order=40, is_active=1 WHERE code='face';
INSERT OR IGNORE INTO armor_slots(code,label,sort_order,is_active) VALUES ('torso','Torso',50,1);
UPDATE armor_slots SET label='Torso', sort_order=50, is_active=1 WHERE code='torso';
INSERT OR IGNORE INTO armor_slots(code,label,sort_order,is_active) VALUES ('hands','Hands',60,1);
UPDATE armor_slots SET label='Hands', sort_order=60, is_active=1 WHERE code='hands';
INSERT OR IGNORE INTO armor_slots(code,label,sort_order,is_active) VALUES ('legs','Legs',70,1);
UPDATE armor_slots SET label='Legs', sort_order=70, is_active=1 WHERE code='legs';
INSERT OR IGNORE INTO armor_slots(code,label,sort_order,is_active) VALUES ('feet','Feet',80,1);
UPDATE armor_slots SET label='Feet', sort_order=80, is_active=1 WHERE code='feet';

/* weapon_slots */
INSERT OR IGNORE INTO weapon_slots(code,label,sort_order,is_active) VALUES ('mainhand','Main Hand',10,1);
UPDATE weapon_slots SET label='Main Hand', sort_order=10, is_active=1 WHERE code='mainhand';
INSERT OR IGNORE INTO weapon_slots(code,label,sort_order,is_active) VALUES ('offhand','Off Hand',20,1);
UPDATE weapon_slots SET label='Off Hand', sort_order=20, is_active=1 WHERE code='offhand';
INSERT OR IGNORE INTO weapon_slots(code,label,sort_order,is_active) VALUES ('both','Two-Handed',30,1);
UPDATE weapon_slots SET label='Two-Handed', sort_order=30, is_active=1 WHERE code='both';

/* encounter_statuses */
INSERT OR IGNORE INTO encounter_statuses(code,label,sort_order,is_active) VALUES ('active','Active',10,1);
UPDATE encounter_statuses SET label='Active', sort_order=10, is_active=1 WHERE code='active';
INSERT OR IGNORE INTO encounter_statuses(code,label,sort_order,is_active) VALUES ('resolved','Resolved',20,1);
UPDATE encounter_statuses SET label='Resolved', sort_order=20, is_active=1 WHERE code='resolved';

/* inventory_event_reasons */
INSERT OR IGNORE INTO inventory_event_reasons(code,label,sort_order,is_active) VALUES ('loot','Loot',10,1);
UPDATE inventory_event_reasons SET label='Loot', sort_order=10, is_active=1 WHERE code='loot';
INSERT OR IGNORE INTO inventory_event_reasons(code,label,sort_order,is_active) VALUES ('reward','Reward',20,1);
UPDATE inventory_event_reasons SET label='Reward', sort_order=20, is_active=1 WHERE code='reward';
INSERT OR IGNORE INTO inventory_event_reasons(code,label,sort_order,is_active) VALUES ('purchase','Purchase',30,1);
UPDATE inventory_event_reasons SET label='Purchase', sort_order=30, is_active=1 WHERE code='purchase';
INSERT OR IGNORE INTO inventory_event_reasons(code,label,sort_order,is_active) VALUES ('admin','Admin',40,1);
UPDATE inventory_event_reasons SET label='Admin', sort_order=40, is_active=1 WHERE code='admin';

/* =========================
   OPTIONAL DEBUG VIEW
   ========================= */
DROP VIEW IF EXISTS v_user_npc_effective_value;
CREATE VIEW v_user_npc_effective_value AS
SELECT
  u.id AS user_id,
  n.id AS npc_id,
  n.name AS npc_name,
  n.value AS base_value,
  COALESCE(un.bonus_vs,0) AS bonus_vs,
  CASE WHEN n.value - COALESCE(un.bonus_vs,0) < 0 THEN 0
       ELSE n.value - COALESCE(un.bonus_vs,0)
  END AS effective_value
FROM npcs n
CROSS JOIN users u
LEFT JOIN user_npcs un ON un.user_id = u.id AND un.npc_id = n.id;

COMMIT;
