yet another implemtation of the gobfish game helper.  
Lets hope this one actually sticks this time.

8-23-2025, 12:10pm finally got twitch login api to work.  
Not sure about the whole clicking on a link after the "login" botton on index.html to do the actual login, but whatever.

# Gobfish — MVP Rules & Logic

## Core Concepts

- **Item**
  - `name`, `slot` (head/chest/hands/feet/offhand/…), `rarity`, `is_active`
- **Inventory (per player)**
  - Owned items + which one is **equipped** per slot (max 1 per slot)
- **Encounter**
  - Two lock phases:
    - **PRE_ENCOUNTER**: freeze a baseline snapshot; players can still stage changes until start
    - **ENCOUNTER_ACTIVE**: player UI read-only; new grants go to a **queue**

## Player Rules

1. **Equip/Unequip**: At most **one** equipped item per slot. Equipping a new one auto-unequips the old.
2. **Duplicates**: Allowed to own; only one can be equipped in its slot.
3. **OPEN (between encounters)**: Free equip/unequip; apply immediately.
4. **ENCOUNTER_ACTIVE**: Sheet locked; incoming items land in **Queued** (not applied yet).

## DM Rules

1. **Start Encounter**
   - Create `encounters` row with `status=ACTIVE`
   - **Snapshot** each player’s equipped state + inventory rev
   - Flip players to **ENCOUNTER_ACTIVE** (lock UI)
2. **Resolve**
   - Review **Queued Events** (`grant_item`, `remove_item`, `adjust_stat`, `message`, …)
   - Approve/reject each; optionally “auto-apply safe events”
3. **End Encounter**
   - Apply all **approved** events in FIFO
   - Slot conflict policy (pick one):
     - **Auto-replace** (default): new equips; old moves to inventory unequipped
     - **Keep existing**: queued item remains owned but **unequipped**
   - Unlock players back to **OPEN**

## Event / Queue Rules

- **Event fields**: `id`, `player_id`, `type`, `payload` (JSON), `source` (dm/chat/api), `encounter_id`, `created_at`, `status` (`queued|approved|applied|rejected`)
- **De-dupe**: `source_id` (e.g., chat msg ID / giveaway code) to prevent double-apply
- **Limits**: Per-player queue cap (e.g., 50). Overflow: drop oldest or merge.

## Data Integrity Rules

1. **Slot validation**: Exactly **one equipped per slot**; reject unknown slots.
2. **Atomic apply**: Applying queued events is transactional per player.
3. **No overlapping encounters**: Only one `ACTIVE` encounter at a time.
4. **Baseline safety**: If apply fails, rollback the affected player to snapshot; keep encounter `ACTIVE` until fixed.

## Visibility / UI Rules

- **OPEN**: All controls enabled.
- **PRE_ENCOUNTER**: Banner “Encounter starting—changes will be frozen soon.” (optional countdown)
- **ENCOUNTER_ACTIVE**: Controls greyed out; **Queued** panel visible so players see pending grants/drops.
- **After End**: Show “Applied X changes” toast/log per player.

## Anti-Abuse Basics

- **Rate limits** on public grant endpoints (per IP/user).
- **Auth**: Only DM can change encounter state or approve queue.
- **Provenance**: Store creator (`source`, `user_id` if any, `ip`).
- **Audit log**: Append-only record of approved/applied actions (who/when/what).

## Optional Toggles (Later)

- **Two-handed items**: Occupies `hands` and `offhand`.
- **Backpack capacity**: Cap total owned items; overflow remains queued.
- **Rarity gates**: Some slots require minimum rarity during encounters.
- **Auto-apply safe types**: Cosmetic grants bypass approval even during encounters.

## Minimal API Endpoints (tech-agnostic; implement in PHP)

- `GET /api/items` — list catalog (filters: `slot`, `rarity`, `q`)
- `GET /api/player/:id/inventory` — owned + equipped
- `POST /api/player/:id/equip` — body: `{ "item_id": <int> }`
- `POST /api/encounters/start`
- `POST /api/encounters/:id/queue` — body: event(s) to queue
- `POST /api/encounters/:id/approve` — body: `{ "event_ids": [ ... ] }`
- `POST /api/encounters/:id/end`

## Minimal Tables (suggested)

- `players(id, name, ...)`
- `items(id, name, slot, rarity, is_active)`
- `player_items(id, player_id, item_id, equipped BOOLEAN)`
- `encounters(id, status, started_at, ended_at)`
- `events(id, encounter_id, player_id, type, payload_json, source, source_id, status, created_at, applied_at)`
- `snapshots(id, encounter_id, player_id, equipped_json, inventory_rev, created_at)`
