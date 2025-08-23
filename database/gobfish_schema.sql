PRAGMA foreign_keys = ON;

BEGIN;

/* =========================
   LOOKUP TABLES
   ========================= */

CREATE TABLE IF NOT EXISTS item_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,            -- armor, weapon, misc
  label TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS rarities (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,            -- common, rare, epic, legendary
  label TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS armor_slots (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,            -- head, shoulders, back, face, torso, hands, legs, feet
  label TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS weapon_slots (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,            -- mainhand, offhand, both (two-handed)
  label TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS encounter_statuses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,            -- active, resolved
  label TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS inventory_event_reasons (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,            -- loot, reward, purchase, admin
  label TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1
);

/* =========================
   CORE TABLES
   ========================= */

CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  subscriber INTEGER NOT NULL DEFAULT 0,     -- 0/1 (your app logic decides what sets this)
  -- Twitch identity (no Laravel migration needed)
  twitch_id      TEXT UNIQUE,
  twitch_login   TEXT,
  twitch_display TEXT,
  avatar_url     TEXT,
  role TEXT NOT NULL DEFAULT 'player' CHECK (role IN ('player','dm')),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_users_twitch_login ON users(twitch_login);

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
  sprite_json TEXT,                    -- bbox/frames if you want it at item-level
  special     TEXT,                    -- freeform abilities text
  tooltip     TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_items_category_id ON items(category_id);
CREATE INDEX IF NOT EXISTS idx_items_rarity_id   ON items(rarity_id);
CREATE INDEX IF NOT EXISTS idx_items_set_id      ON items(set_id);

/* 1:1 armor details (only for items in category 'armor') */
CREATE TABLE IF NOT EXISTS armor_stats (
  item_id INTEGER PRIMARY KEY REFERENCES items(id) ON UPDATE RESTRICT ON DELETE CASCADE,
  slot_id INTEGER NOT NULL REFERENCES armor_slots(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  -- defense INTEGER NOT NULL DEFAULT 0,
  -- weight  INTEGER NOT NULL DEFAULT 0,
  -- durability INTEGER NOT NULL DEFAULT 100,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_armor_stats_slot_id ON armor_stats(slot_id);

/* 1:1 weapon details (only for items in category 'weapon') */
CREATE TABLE IF NOT EXISTS weapon_stats (
  item_id INTEGER PRIMARY KEY REFERENCES items(id) ON UPDATE RESTRICT ON DELETE CASCADE,
  attack_power INTEGER NOT NULL DEFAULT 0,
  attack_speed INTEGER NOT NULL DEFAULT 1,
  range        INTEGER NOT NULL DEFAULT 1,
  hands        INTEGER NOT NULL DEFAULT 1 CHECK (hands IN (1,2,3)),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS inventory (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id) ON UPDATE RESTRICT ON DELETE CASCADE,
  item_id INTEGER NOT NULL REFERENCES items(id) ON UPDATE RESTRICT ON DELETE CASCADE,
  owned INTEGER NOT NULL DEFAULT 1 CHECK (owned >= 0),  -- fixed CHECK
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
  is_hostile INTEGER NOT NULL DEFAULT 1,      -- 1 hostile, 0 friendly (global default)
  is_active  INTEGER NOT NULL DEFAULT 1,
  value      INTEGER NOT NULL DEFAULT 0,      -- difficulty / hp / to-hit baseline
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
  snapshot_json TEXT,                          -- loadout summary; optional
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
  is_friendly INTEGER NOT NULL DEFAULT 0,       -- becomes 1 on win
  bonus_vs    INTEGER NOT NULL DEFAULT 0,       -- +1 per loss vs this NPC
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
  applied_at TEXT,                              -- NULL = pending; set when drained post-battle
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_inv_events_user_id   ON inventory_events(user_id);
CREATE INDEX IF NOT EXISTS idx_inv_events_item_id   ON inventory_events(item_id);
CREATE INDEX IF NOT EXISTS idx_inv_events_reason_id ON inventory_events(reason_id);
CREATE INDEX IF NOT EXISTS idx_inv_events_enc_id    ON inventory_events(encounter_id);

/* =========================
   SEED LOOKUPS (idempotent)
   ========================= */

INSERT INTO item_categories (code,label,sort_order,is_active) VALUES
 ('armor','Armor',10,1),
 ('weapon','Weapon',20,1),
 ('misc','Misc',30,1)
ON CONFLICT(code) DO UPDATE SET
 label=excluded.label, sort_order=excluded.sort_order, is_active=excluded.is_active;

INSERT INTO rarities (code,label,sort_order,is_active) VALUES
 ('common','Common',10,1),
 ('uncommon','Uncommon',15,1),
 ('rare','Rare',20,1),
 ('epic','Epic',30,1),
 ('legendary','Legendary',40,1)
ON CONFLICT(code) DO UPDATE SET
 label=excluded.label, sort_order=excluded.sort_order, is_active=excluded.is_active;

INSERT INTO armor_slots (code,label,sort_order,is_active) VALUES
 ('head','Head',10,1),
 ('shoulders','Shoulders',20,1),
 ('back','Back',30,1),
 ('face','Face',40,1),
 ('torso','Torso',50,1),
 ('hands','Hands',60,1),
 ('legs','Legs',70,1),
 ('feet','Feet',80,1)
ON CONFLICT(code) DO UPDATE SET
 label=excluded.label, sort_order=excluded.sort_order, is_active=excluded.is_active;

INSERT INTO weapon_slots (code,label,sort_order,is_active) VALUES
 ('mainhand','Main Hand',10,1),
 ('offhand','Off Hand',20,1),
 ('both','Two-Handed',30,1)
ON CONFLICT(code) DO UPDATE SET
 label=excluded.label, sort_order=excluded.sort_order, is_active=excluded.is_active;

INSERT INTO encounter_statuses (code,label,sort_order,is_active) VALUES
 ('active','Active',10,1),
 ('resolved','Resolved',20,1)
ON CONFLICT(code) DO UPDATE SET
 label=excluded.label, sort_order=excluded.sort_order, is_active=excluded.is_active;

INSERT INTO inventory_event_reasons (code,label,sort_order,is_active) VALUES
 ('loot','Loot',10,1),
 ('reward','Reward',20,1),
 ('purchase','Purchase',30,1),
 ('admin','Admin',40,1)
ON CONFLICT(code) DO UPDATE SET
 label=excluded.label, sort_order=excluded.sort_order, is_active=excluded.is_active;

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
