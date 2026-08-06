# Data Model

> Здесь разделены три вещи: фактический runtime-контракт, контентные/legacy-данные, и данные, которые существуют в репозитории, но пока не подключены к игре. При добавлении контента не считайте наличие поля гарантией того, что оно уже влияет на gameplay.

## Canonical Sources at Runtime

| Domain | Current canonical source | Reader | Not canonical / not active |
| --- | --- | --- | --- |
| Battle level definitions | `data/levels/level_001.json` … `level_005.json` | `LevelLoader.load_level` | `data/levels/campaign_01/*.json` has an alternate schema and is not read. |
| Campaign ordering / next link | `data/levels/level_index.json` | CampaignMap, VictoryScreen | `rewards.unlock_levels` is not used for unlocking. |
| Per-structure runtime state | Dictionary entry in root level JSON -> `Structure.setup_from_data` | LevelLoader / Structure | `unit_type` is active; `type` is present in content but ignored by Structure. |
| Progress and settings | `user://savegame.json` schema from SaveManager | SaveManager | `SaveData.gd` is a legacy/unreferenced typed schema. |
| Audio assets | AudioManager path constants | AudioManager | Faction `default_music` is unreferenced. |
| Localization source | `data/localization/ui.csv` | Godot translation importer / TranslationServer | Most runtime UI literals do not use translation keys. |
| Factions / commanders | No runtime source yet | Nobody | JSON catalogs and typed model scripts are content-only. |
| Tower generation balance | `data/config/game_balance.tres` | Structure / GameBalance | Global `structure_generation_rate`; not a level field. |
| AI Resource | No runtime source yet | Nobody | `data/config/ai_config.tres` is still empty. |

## Level Data

### Active root-level schema

`LevelLoader` opens a file exactly at `res://data/levels/<level_id>.json`. The five root `level_###.json` files use this display-oriented schema:

| Field | Type / example | Used by current runtime | Notes |
| --- | --- | --- | --- |
| `id` | String, `"level_001"` | Yes | File identity; CampaignMap popup and loader depend on matching ID. |
| `name` | String | Popup/UI only | Literal display text; not localized at runtime. |
| `difficulty` | String | No | Content metadata. |
| `time_limit_star` | Number | No | No clock or star evaluator exists. |
| `player_faction` | String, `"player"` | No | Battle logic instead compares Structure owners directly. |
| `enemy_faction` | String, `"enemy"` | No | Note faction catalog identifies enemy as `enemy_01`. |
| `weather` | String | No | Content metadata. |
| `objectives` | Array of strings | Partially | Popup displays it; Game copies the entire array into victory `completed_objectives`; no objective check is performed. |
| `rewards` | Dictionary | Partially | Game reads `stars`, `coins_reward`, `unlock_levels`; only stars/coins have an effect today. |
| `structures` | Array of structure dictionaries | Yes | Required by LevelLoader. |
| `iso_origin` | `{x, y}` or `[x, y]` | Optional | Supported by LevelLoader / BattleBackground for isometric coordinates. |

`LevelLoader` validates only that root JSON is a dictionary, `structures` is an array, every instantiated structure has a non-empty unique id, and referenced link IDs exist. It reports `push_error` for invalid entries; it does not schema-validate the optional gameplay/display fields.

### `rewards`

```json
"rewards": {
  "stars": 3,
  "coins_reward": 100,
  "unlock_levels": ["level_002"]
}
```

- `stars`: used by `Game.complete_level`; absent means `3`.
- `coins_reward`: used by `Game.complete_level`; absent means `100`.
- `unlock_levels`: passed to `SaveManager.mark_level_completed` but currently ignored by SaveManager. Do not rely on this field for unlock behavior until progression is redesigned.

### Alternate `campaign_01` schema — not active

`data/levels/campaign_01/level_001..003.json` contains a different authored schema:

| Field | Status |
| --- | --- |
| `name_key`, `description_key` | Match keys in `ui.csv`, but no active loader/UI path resolves them. |
| `scene_type` | Not read. |
| `commander_id` | Not read; no CommanderController exists. |
| `music_track` | Not read; BattleScene always requests AudioManager's default battle track. |
| `victory_conditions`, `defeat_conditions` | Not read by BattleController. |
| `ai.profile`, `ai.think_interval` | Not read by EnemyAI. |
| `structures`, `rewards` | Structurally similar enough for part of loader, but the folder is not selected by it. |

`scripts/data/LevelData.gd` models this alternate/target shape: `id`, `name_key`, `description_key`, `scene_type`, `commander_id`, `music_track`, `victory_conditions`, `defeat_conditions`, `structures`, `ai`, `rewards`. Its `from_dict` is currently never called.

### Campaign index schema

`data/levels/level_index.json` is a JSON array, ordered by campaign sequence:

```json
{
  "id": "level_001",
  "name": "Crossroads Clash",
  "description": "Secure the crossroads and capture every tower.",
  "next_level": "level_002"
}
```

- `CampaignMap` reads `id` and `name`; `description` is currently not displayed.
- `VictoryScreen` finds the current `id` and reads `next_level`.
- `SaveManager.is_level_unlocked` does **not** use this index; it derives predecessor from the numeric portion of ID.

## Structure Data

Each element of level `structures` becomes a `Structure.tscn` instance. The current root data uses this shape:

```json
{
  "id": "player_home",
  "type": "tower",
  "owner": "player",
  "position": { "x": 180, "y": 360 },
	"level": 1,
	"unit_type": "infantry",
	"garrison": 20.0,
  "max_garrison": 100.0,
  "connected_to": ["mid_top", "mid_bottom"]
}
```

| Field | Runtime field / use | Rules |
| --- | --- | --- |
| `id` | `Structure.structure_id` | Required non-empty and unique per loaded level. |
| `type` | No runtime field | Present in root JSON but ignored; every entry instantiates same `Structure.tscn`. |
| `owner` | `owner_id` | `player`, `neutral`, `enemy`; strings beginning `enemy` normalize to `enemy`. Unknown strings remain but render as enemy. |
| `position` | `Node2D.position` | Supports `{x,y}` or `[x,y]`. |
| `iso_position` | Converted to `position` by LevelLoader | Optional alternate coordinate form; supports `{x,y}` or `[x,y]`. |
| `level` | `level: int` | Displayed in HUD but has no current mechanical modifier. |
| `unit_type` | `unit_type: String` | Active tower unit identity. Valid values are `infantry`, `archer`, `cavalry`; missing/unknown values safely become `infantry`. It is shown in HUD, inherited by TroopStream, and remains unchanged on capture. It has no combat, production, collision, AI-policy, faction, or commander effect in Milestone 1. |
| `garrison` | `garrison: float` | Starting defenders/troops; display rounds to integer. |
| `max_garrison` | `max_garrison: float` | Production and reinforcement cap. |
| `connected_to` | `connected_to: Array[String]` -> `neighbors: Array[Structure]` | Route IDs. A source may only send to a resolved neighbor. |

Fields requested by a more advanced design that are **not** in current model:

- `defense_modifier`: not read or applied. Defence is exactly current `garrison`.
- `upgrade_cost`: no upgrade mechanic/data read path exists.
- Gameplay-specific structure kinds: `type` is inert, so it cannot yet select a different scene, sprite, production or rule set.

### Structure combat data transformations

For an incoming `attack_power`:

- If `attacker_owner == owner_id`, `garrison = min(max_garrison, garrison + attack_power)`.
- Otherwise if `attack_power > garrison`, owner changes and new `garrison = attack_power - old_garrison`.
- Otherwise `garrison = old_garrison - attack_power` and owner stays.

There are no unit-type modifiers, faction modifiers, defence modifiers, terrain effects, level effects, or upgrading effects in this equation.

### Generation runtime contract

`Structure.can_generate_units()` is evaluated from mutable runtime state, not from a creation-time tower type. It requires current owner other than `neutral`, a positive `GameBalance.structure_generation_rate`, garrison below its JSON `max_garrison`, an enabled node in the scene tree, and a node not queued for deletion. `advance_unit_generation(delta)` is the only production step and is called by `_process`; it uses `_production_accumulator` rather than Timer instances. Capture resets the accumulator through existing `resolve_combat` ownership-change logic.

The active rate configuration is `GameBalance.structure_generation_rate` (units/second) in `data/config/game_balance.tres`; levels retain only per-structure `max_garrison`. The project does not define a separate `generation_interval`; do not add one without a gameplay decision because it would introduce a second overlapping rate model.

## Faction Data

`data/factions/factions.json` is an array of catalog entries and `FactionData.from_dict` can parse it, but no current code loads it.

| Field | Parsed by `FactionData` | Current runtime use |
| --- | --- | --- |
| `id` | `id` | No. Entries are `player`, `neutral`, `enemy_01`; Structure expects runtime enemy `enemy`. |
| `name_key` | `name_key` | No. |
| `color` | `Color(...)` | No. Structure hardcodes colors. |
| `structure_tint` | `Color(...)` | No. |
| `troop_tint` | `Color(...)` | No. TroopStream hardcodes colors. |
| `banner_icon` | `banner_icon` | No. |
| `default_music` | `default_music` | No. |

There are no `modifiers` or `commanders` fields in the actual faction JSON. Commander linkage exists separately in `commanders.json` through `faction_id`.

## Commander Data

`data/factions/commanders.json` currently contains `enemy_commander_01`. `CommanderData.from_dict` maps:

| Field | Meaning | Current runtime use |
| --- | --- | --- |
| `id` | Commander identifier | No. |
| `name_key`, `title_key`, `description_key` | Localized display keys | No. |
| `portrait` | Resource path | No. |
| `faction_id` | Catalog faction relationship | No. |
| `ai_profile` | Intended AI profile reference | No. |

No `CommanderController`, selection UI, asset loader, or battle application of commander modifiers exists in the project. Adding a JSON commander alone will not change gameplay.

## Save Data

### Current persisted schema

`SaveManager` owns the schema at `user://savegame.json`. `SAVE_VERSION` is **1**. A default save is:

```json
{
  "version": 1,
  "selected_faction": "slavic",
  "coins": 0,
  "stars": 0,
  "completed_levels": {},
  "settings": {
    "master_volume": 1.0,
    "music_volume": 0.7,
    "sfx_volume": 0.8,
    "language": "ru",
    "fullscreen": false
  }
}
```

| Field | Type | Meaning / behavior |
| --- | --- | --- |
| `version` | int | Migration discriminator. Invalid/missing data is merged with current default. |
| `selected_faction` | String | Persisted, default `slavic`; not read by battle or menu. It does not match the current player faction catalog ID. |
| `coins` | int | Accumulated by each completion reward. |
| `stars` | int | Total of each completed level's best stars. |
| `completed_levels` | Dictionary keyed by level id | Completion also provides runtime unlock information. |
| `completed_levels.<id>.stars` | int | Max stars awarded for that level. |
| `completed_levels.<id>.best_time` | float | Stored by API; current Game always passes `0.0`. |
| `completed_levels.<id>.objectives` | Array | Current Game copies all level objective strings on victory. |
| `settings.master_volume` | float | Applied by AudioManager. |
| `settings.music_volume` | float | Applied by AudioManager. |
| `settings.sfx_volume` | float | Applied by AudioManager. |
| `settings.language` | string | Applied by LocalizationManager. |
| `settings.fullscreen` | bool | Saved by SettingsScreen; applied only when toggled in that screen. |

Load behavior: missing save creates one; a parse failure renames the broken file to `user://corrupted_save_<timestamp>.json`, creates default, and writes it. Before normal writing an existing save is copied to `user://savegame.backup.json`. `reset_progress()` makes default progress but preserves `settings`.

### Unlocks and rewards in current SaveManager

The requested conceptual field `unlocked_levels` is not stored in v1 save. `is_level_unlocked(level_id)` returns true for first level and otherwise checks whether a level with previous numeric ID is present in `completed_levels`. Thus `level_003` needs `level_002` completed; ID format must remain numeric/serial for this to work.

`SaveManager.complete_level` receives a reward every completion, maintains maximum stars, and updates total stars by replacing only the prior star contribution. The `unlock_levels` argument is retained only for compatibility in `mark_level_completed` and is unused.

### Legacy typed `SaveData` — not canonical

`scripts/data/SaveData.gd` defines version **2**, `unlocked_levels: Array[String]`, `completed_levels: Array[String]`, `level_results`, and defaults to English/0.8 music. It is not instantiated by SaveManager. `SaveManager._migrate_legacy_save` contains partial migration from such older shapes to the v1 dictionary. Do not use `SaveData.to_dict()` to create new runtime saves without first reconciling the schemas.

## Balance Data

### Where balance currently lives

| Parameter | Current source | Effective value / behavior | Resource/data status |
| --- | --- | --- | --- |
| Send fraction | `BattleController._on_structure_clicked`, `EnemyAI._take_turn` | Literal `0.5` (floor of current garrison). | `Constants.DEFAULT_SEND_FRACTION = 0.5` exists but is not consumed. |
| Troop speed | `TroopStream.gd` exported field | Default `180.0` pixels/s; no level/AI/balance override. | Hardcoded script default. |
| AI think interval | `EnemyAI.gd` | Default `2.5` seconds. | Hardcoded. Nested `ai.think_interval` exists but is ignored. |
| AI source threshold | `EnemyAI.gd` | Source must have `garrison > 20.0`. | Hardcoded. |
| AI targeting | `EnemyAI.gd` | First viable enemy source sends to weakest neutral/player neighbor. | Hardcoded policy, `ai.profile` ignored. |
| Generation rate | `data/config/game_balance.tres` / `GameBalance` | Global `structure_generation_rate` units/s, applied only by live/enabled non-neutral owners. | Resource-driven globally; default/current value 4.0. |
| Max garrison | Each active root level's structure entry | Reinforcement/production cap. | Data-driven per structure; default 100.0. |
| Initial garrison | Each active root level's structure entry | Starting defence/troops. | Data-driven per structure; default 10.0. |
| Defence modifier | `Structure.resolve_combat` | No modifier: defence equals current garrison. | **Currently not implemented.** |
| Upgrade cost/effect | — | No upgrade action or data read path. | **Currently not implemented.** `AudioManager.UPGRADE_SFX` is only an unused asset constant. |
| Victory stars / coins | Level `rewards`, `Game.gd` | Data values, with defaults 3 / 100. | Data-driven for result payload, not based on objective performance. |
| Owner visual color/textures | `Structure.gd`, `TroopStream.gd` | Fixed player/neutral/enemy palettes and paths. | Hardcoded presentation. |

`data/config/game_balance.tres` is now an active `GameBalance` resource with `structure_generation_rate = 4.0`. `data/config/ai_config.tres` remains an empty unused Resource.

## Data Authoring Checklist

### Add a runtime level

1. Create `data/levels/level_###.json` using the active root schema.
2. Give every structure a unique non-empty `id`.
3. Make `connected_to` references point to existing IDs. Use reciprocal links when the route should be bidirectional; the loader does not add reverse links automatically.
4. Add ordered entry and `next_level` in `data/levels/level_index.json`.
5. Ensure predecessor numeric ID is completable if it should unlock through current SaveManager logic.
6. Open `docs/BATTLE_FLOW.md` and validate selection/capture expectations.

### Do not assume these authoring actions work yet

- Adding `type`, `defense_modifier`, upgrade data, weather, time limit, AI profile/interval, faction modifiers or commander data does not change current runtime behavior.
- `unit_type` is the exception: active root level structures support `infantry`, `archer`, and `cavalry` for HUD/stream identity only; it does not alter combat or AI decisions.
- Editing `campaign_01` definitions does not change live gameplay.
- Editing `rewards.unlock_levels` does not change `SaveManager.is_level_unlocked`.
- Editing `.translation` output files is not the localization workflow; edit `ui.csv` instead.

### Generation regression test

Run the native Godot test scene from the project root:

```bash
godot --headless --path . --scene res://tests/StructureGenerationTest.tscn
```

It covers friendly/enemy/neutral generation, cap, neutral capture transitions, transitions to neutral, repeated owner changes (one accumulator), disabled/queued-removal nodes, and rate/max data values.

## Future Data Consolidation Targets

1. Select one level schema and one folder, then make `LevelData` either the runtime parser or remove it.
2. Define a single versioned save model and reconcile `SaveData` with SaveManager.
3. Give game/AI balance named fields in real Resource classes, load them once, and remove duplicated literals.
4. Establish owner/faction mapping (`enemy` vs `enemy_01`) before catalog data is used.
5. Convert UI and level display content from literal strings to translation keys if language support is a product requirement.
