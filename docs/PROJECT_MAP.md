# Project Map

> Техническая карта актуальной runtime-реализации. Состояние проверено по `project.godot`, сценам, GDScript и данным в репозитории. Этот документ описывает фактическое поведение, а не предполагаемую целевую архитектуру.

## 1. Project Overview

`Warbound Realms` — single-player prototype на Godot 4.6.x / GDScript: 2D/2.5D tower-conquest RTS для Steam-направленного MVP. Игровой цикл: структуры производят гарнизон; игрок выбирает дружественную структуру и отправляет часть гарнизона только по существующей связи; поток войск наследует тип исходной башни, усиливает союзника либо сражается за цель и может её захватить. Тип войск пока является только данными и визуальной идентификацией, без боевых модификаторов.

Основные системы: меню и кампания, JSON-загрузка уровней, бой и capture, простой AI противника, пауза/результат боя, прогрессия и настройки в `user://`, музыка/SFX, CSV-локализация. Steam-интеграции и контроллера командиров в runtime нет.

## 2. Entry Points

### Startup configuration

- Стартовая сцена: `res://scenes/menu/MainMenu.tscn` (`project.godot`, `run/main_scene`).
- Скрипт стартовой сцены: `res://scripts/ui/MainMenu.gd`.
- `scenes/boot/Boot.tscn` существует, но не выбран как main scene и не участвует в запуске.

### Autoload / singleton registration

Все ниже зарегистрированы в `project.godot` и создаются до основной сцены:

| Singleton | Path | Startup responsibility |
| --- | --- | --- |
| `Game` | `globals/Game.gd` | Хранит выбранный уровень и текущие level data; запускает/завершает сессию. |
| `SaveManager` | `globals/SaveManager.gd` | В `_ready()` загружает или создаёт сохранение. |
| `AudioManager` | `globals/AudioManager.gd` | Создаёт music/SFX players, применяет сохранённые аудионастройки. |
| `SceneLoader` | `globals/SceneLoader.gd` | Централизует переходы между тремя главными сценами. |
| `EventBus` | `globals/EventBus.gd` | Предоставляет глобальные gameplay/UI signals. |
| `LocalizationManager` | `globals/LocalizationManager.gd` | Читает language из save, задаёт `TranslationServer` locale. |

### Actual app-start flow

`Godot application` -> autoload `_ready()` (`SaveManager` создаёт/мигрирует save; `AudioManager` применяет settings; `LocalizationManager` задаёт locale) -> `MainMenu.tscn` -> `MainMenu._ready()` -> menu music, связи кнопок, состояние Continue и build version.

## 3. Folder Structure

```text
res://
├── assets/                         # Арт, аудио, UI-тема, шрифты и лицензии
│   ├── art/                        # Башни, тайлы, декор, legacy/import assets
│   ├── audio/                      # Menu/Battle/Victory/Defeat music и SFX
│   └── ui/                         # Theme, иконки, SVG-кнопки и frames
├── data/                           # Контент и конфигурация
│   ├── config/                     # Active game balance resource and reserved AI config
│   ├── factions/                   # factions.json и commanders.json
│   ├── levels/                     # runtime level_001..005.json, index и legacy campaign_01/
│   └── localization/               # ui.csv и импортированные translation resources
├── globals/                        # Autoload services
├── scenes/                         # Godot scene composition
│   ├── battle/                     # BattleScene и battle UI
│   ├── boot/                       # Неиспользуемая Boot.tscn
│   ├── common/                     # Reusable placeholder/common scenes
│   ├── menu/                       # Main menu, campaign, popup, settings
│   └── world/                      # Instanced Structure/TroopStream и placeholders
├── scripts/                        # Поведение, сгруппированное по battle/data/ui/utils/world
├── docs/                           # Эта техническая документация
├── resources/                      # Отсутствует в текущем checkout; README упоминает как optional
├── localization/                   # Отсутствует; реальные переводы лежат в data/localization/
└── tests/                          # Headless native Godot tests
```

`*.uid`, `*.import` и `.godot/` — generated/editor metadata, не являются исходниками gameplay.

## 4. Scene Map

| Scene | Path | Script | Purpose | Main dependencies |
| --- | --- | --- | --- | --- |
| MainMenu | `scenes/menu/MainMenu.tscn` | `scripts/ui/MainMenu.gd` | Стартовое меню: Continue, New Game, settings, exit. | `SceneLoader`, `SaveManager`, `AudioManager`, nested SettingsScreen. |
| CampaignMap | `scenes/menu/CampaignMap.tscn` | `scripts/ui/CampaignMap.gd` | Строит список уровней из index, показывает lock/stars. | `level_index.json`, level JSON, `SaveManager`, `LevelInfoPopup`. |
| LevelInfoPopup | `scenes/menu/LevelInfoPopup.tscn` | `scripts/ui/LevelInfoPopup.gd` | Показывает имя/objectives выбранного уровня и запускает его. | Level dictionary, `Game`, `AudioManager`. |
| SettingsScreen | `scenes/menu/SettingsScreen.tscn` | `scripts/ui/SettingsScreen.gd` | Language, audio sliders, fullscreen, reset progress. | `LocalizationManager`, `AudioManager`, `SaveManager`; инстансится в MainMenu и PauseMenu. |
| BattleScene | `scenes/battle/BattleScene.tscn` | `scripts/battle/BattleScene.gd` | Root runtime-композиции боя. | BattleController, world roots, renderers, HUD/result UI. |
| HUD | `scenes/battle/HUD.tscn` | `scripts/ui/HUD.gd` | Информация уровня/выбора, pause button, debug counters. | Injected `BattleController`, `EventBus`, embedded DebugBattleOverlay. |
| PauseMenu | `scenes/battle/PauseMenu.tscn` | `scripts/ui/PauseMenu.gd` | Pause/resume/restart/campaign/settings. | Injected `BattleController`, `EventBus`, nested SettingsScreen; processes while paused. |
| VictoryScreen | `scenes/battle/VictoryScreen.tscn` | `scripts/ui/VictoryScreen.gd` | Показывает rewards и даёт next/retry/campaign. | `EventBus.battle_won`, `Game`, `SaveManager`, `SceneLoader`. |
| DefeatScreen | `scenes/battle/DefeatScreen.tscn` | `scripts/ui/DefeatScreen.gd` | Показывает defeat tip, retry/campaign. | `EventBus.battle_lost`, `Game`, `SceneLoader`. |
| DebugBattleOverlay | `scenes/battle/DebugBattleOverlay.tscn` | `scripts/ui/DebugBattleOverlay.gd` | Отдельная debug сцена, но в Battle HUD фактически используется inline-копия node tree. | Injected `BattleController`; visible только в debug build при default export. |
| Structure | `scenes/world/Structure.tscn` | `scripts/world/Structure.gd` | Runtime-инстанс башни: визуал, input, гарнизон, производство, capture. | Инстансится `LevelLoader`; `EventBus`; собственные signals. |
| TroopStream | `scenes/world/TroopStream.tscn` | `scripts/world/TroopStream.gd` | Runtime-инстанс движущихся войск и in-transit clash. | Инстансится `BattleController`; source/target `Structure`, stream-only Area2D. |
| CaptureEffect | `scenes/world/CaptureEffect.tscn` | — | Пустой placeholder Node2D; не инстансится. | — |
| StructureSelectionRing | `scenes/world/StructureSelectionRing.tscn` | — | Пустой ColorRect placeholder; не используется, поскольку ring embedded в Structure. | — |
| ConfirmPopup | `scenes/common/ConfirmPopup.tscn` | — | Generic `ConfirmationDialog`; не инстансится. | — |
| LoadingScreen | `scenes/common/LoadingScreen.tscn` | — | Пустой Control placeholder; не используется. | — |
| AudioPlayer2D | `scenes/common/AudioPlayer2D.tscn` | — | Generic `AudioStreamPlayer2D`; не используется. | — |
| Boot | `scenes/boot/Boot.tscn` | — | Пустой Node; не используется как start scene. | — |

### BattleScene tree

```text
BattleScene (BattleScene.gd)
├── World
│   ├── Background (BattleBackground.gd; reads ../Structures)
│   ├── Connections (ConnectionRenderer.gd; reads ../Structures)
│   ├── Structures              # LevelLoader creates Structure instances here
│   ├── TroopStreams            # BattleController creates TroopStream instances here
│   └── VFX                     # Present, currently unused
├── Controllers
│   └── BattleController (BattleController.gd)
│       ├── EnemyAI (EnemyAI.gd)
│       └── LevelLoader (LevelLoader.gd)
└── CanvasLayer
    ├── HUD (HUD.gd)
    ├── PauseMenu (PauseMenu.gd, nested SettingsScreen)
    ├── VictoryScreen (VictoryScreen.gd)
    └── DefeatScreen (DefeatScreen.gd)
```

## 5. Autoload / Singleton Map

| Singleton | Path | Responsibility | Key methods | Used by |
| --- | --- | --- | --- | --- |
| `Game` | `globals/Game.gd` | Session state (`selected_level_id`, `current_level_data`), game-level start/result facade. | `start_level`, `complete_level`, `fail_level` | LevelInfoPopup, BattleController, BattleBackground, result screens, ObjectiveTracker. |
| `SaveManager` | `globals/SaveManager.gd` | JSON persistence, migration/backup, level completion/lookup, settings. | `load_save`, `save_game`, `mark_level_completed`, `is_level_unlocked`, `get_level_stars`, `update_setting` | Game, menus, settings, audio, localization, VictoryScreen. |
| `SceneLoader` | `globals/SceneLoader.gd` | Changes to main menu, campaign, or battle; unpauses before transition. | `goto_main_menu`, `goto_campaign`, `goto_battle` | Game, MainMenu, CampaignMap, BattleController, PauseMenu, result screens. |
| `EventBus` | `globals/EventBus.gd` | Decoupled signals for selection, updates, battle result, pause, loaded level, settings. | Signals only | Battle/game systems, HUD, overlays, menus, renderers, screens, AudioManager. |
| `AudioManager` | `globals/AudioManager.gd` | One global music and one SFX player; applies volumes. | `play_music`, `play_sfx`, `play_*_music`, `set_*_volume` | MainMenu, CampaignMap, battle and UI scripts. |
| `LocalizationManager` | `globals/LocalizationManager.gd` | Persists and applies locale; exposes `tr_key`. | `set_language`, `tr_key` | SettingsScreen; Godot `TranslationServer`. |
| `SteamManager` | — | Not present or registered. | — | — |

## 6. Runtime Flow

### 6.1 App Start Flow

`project.godot` main scene -> `MainMenu.tscn` -> `MainMenu._ready()` -> `AudioManager.play_menu_music()` + button wiring + `SaveManager.has_any_progress()` sets Continue availability. Autoloads have already loaded saved settings/progress.

### 6.2 New Game Flow

`MainMenu._on_new_game_pressed()` -> `SaveManager.reset_progress()` (preserves settings) -> `SceneLoader.goto_campaign()` -> `CampaignMap._ready()` -> `_load_levels()` reads `data/levels/level_index.json` and disables rows through `SaveManager.is_level_unlocked()` -> row click calls `CampaignMap._on_level_pressed()` -> reads `data/levels/<id>.json` -> `LevelInfoPopup.show_level()` -> Start -> `Game.start_level(id)` -> `SceneLoader.goto_battle(id)` -> `BattleScene.tscn`.

Continue skips `reset_progress` and uses the same campaign path. A campaign row cannot start a nested `campaign_01` file because the actual load path is root `data/levels/<id>.json`.

### 6.3 Battle Flow

`BattleScene._ready()` plays battle music and injects its `BattleController` into HUD/PauseMenu. Independently, `BattleController._ready()` resolves `Game.selected_level_id`, calls `LevelLoader.load_level(id, World/Structures)`, saves the returned dictionary into `Game.current_level_data`, connects every Structure signal, then `EnemyAI.setup(self)`.

`LevelLoader` parses `data/levels/<id>.json`, instantiates `Structure.tscn`, calls `Structure.setup_from_data`, validates references and resolves neighbor nodes. It emits `EventBus.level_loaded`; the already-ready `BattleBackground` deferred-builds ground/roads. HUD subscribes later in the scene-ready order, so it misses this initial emit (see risks). Every frame the controller checks win/loss; each Structure produces units; EnemyAI may issue an enemy send order.

### 6.4 Victory Flow

`BattleController._check_battle_state()` detects no enemy-owned structures **and** no active enemy streams -> sets `battle_state = VICTORY` -> `_apply_pause_state(true)` -> `Game.complete_level(Game.selected_level_id, level_data.rewards)` -> `SaveManager.mark_level_completed(...)` -> disk save -> `EventBus.battle_won.emit(...)` -> `VictoryScreen._on_battle_won()` shows rewards and plays victory music. `VictoryScreen` runs while paused.

The completion payload defaults `stars` to 3 and `coins_reward` to 100 if absent. `completed_objectives` is copied from the currently loaded JSON `objectives` array, if it exists.

### 6.5 Defeat Flow

`BattleController._check_battle_state()` detects no player-owned structures **and** no active player streams -> `battle_state = DEFEAT` -> pause -> `Game.fail_level(id)` -> `EventBus.battle_lost.emit({tip})` -> `DefeatScreen._on_battle_lost()` displays result and plays defeat music. There is no persistence write on defeat.

### 6.6 Pause Flow

`ui_cancel`/Esc in `BattleController._unhandled_input()` or HUD `PauseButton` -> `BattleController.request_pause_toggle()` -> changes `battle_state` and `_apply_pause_state()` -> `get_tree().paused` plus `EventBus.pause_changed`. `PauseMenu` is `PROCESS_MODE_WHEN_PAUSED`; it is visible only when `is_paused()` (not victory/defeat). Resume returns to `RUNNING`; settings can be opened from the paused menu.

### 6.7 Restart / Exit Flow

- Pause Restart -> `BattleController.request_restart()` -> unpause -> `SceneLoader.goto_battle(Game.selected_level_id)`.
- Pause Campaign -> `request_exit_to_campaign()` -> unpause -> `SceneLoader.goto_campaign()`.
- Victory/Defeat Retry -> `SceneLoader.goto_battle(Game.selected_level_id)`.
- Victory Next -> `VictoryScreen._get_next_level_id()` reads `level_index.json`; it changes scene only if the next level is unlocked, otherwise campaign.

## 7. Key Systems Overview

### Battle System

Located in `scripts/battle/`. `BattleController` owns battle state, selected source and runtime collection roots; `LevelLoader` creates structures; `EnemyAI` submits the same `send_troops` request as the player; `TroopStream` resolves arrival; `BattleController` evaluates global victory/defeat. Selection is LMB on a player structure. A second LMB on connected target sends 50%; right-click clears selection. The controller does not consult JSON victory/defeat conditions: it uses faction presence plus active streams.

### Structure System

`scripts/world/Structure.gd` implements `Structure.tscn`. Runtime fields: `structure_id`, `owner_id`, `garrison`, `max_garrison`, `level`, `unit_type`, `connected_to`, `neighbors`. `unit_type` is read from active level JSON with a safe `infantry` fallback; valid values are `infantry`, `archer`, `cavalry`. It remains a tower property on capture and has no combat effect in Milestone 1. `can_generate_units()` is the single generation rule: a live, enabled, non-neutral Structure below cap with positive balance rate can generate. `_process()` delegates to `advance_unit_generation(delta)`, which reads global `GameBalance.structure_generation_rate` from `data/config/game_balance.tres` and caps at each structure's JSON `max_garrison`; it creates no Timer. `resolve_combat` reinforces same-owner targets; otherwise it subtracts defence or flips owner with residual attack as garrison. `_update_visuals()` updates labels/textures/glow and emits `EventBus.structure_updated`.

### Troop Stream System

`BattleController._on_troops_requested()` instantiates `TroopStream.tscn` in `World/TroopStreams`, injects its `is_running` guard, listens to `finished`, then calls `setup`. The stream reads its `unit_type` from the source Structure and displays `INF` / `ARC` / `CAV` with a unit-specific marker color; trail/glow still identify owner. A stream owns a marker-sized `DetectionArea` on collision layer/mask `2`, isolated from Structure's default layer. Opposing streams resolve exactly once through deterministic lower-instance-id initiator plus finished/resolving guards: the larger stream loses the opponent amount and continues toward its original target; equal streams both end. Allies ignore each other. Unit type does not affect this arithmetic. `TroopStream._process()` moves at exported `speed = 180.0`; within four pixels a surviving stream calls `target.resolve_combat(owner_id, amount)`, emits `arrived`, then `finished(ARRIVED)`. Destroyed streams emit only `finished(DESTROYED_IN_TRANSIT)` and never contact the target.

### Enemy AI System

`scripts/battle/EnemyAI.gd` ticks only while `BattleController.can_ai_act()`. Default interval is 2.5 s. At a tick it finds enemy structures with garrison `> 20`, considers neutral/player neighbors, sorts by lowest garrison and sends 50% from the first viable source to its weakest target. Level JSON contains an `ai.think_interval`, but it is not read by EnemyAI.

### Save / Progression System

`SaveManager` reads/writes `user://savegame.json`, copies the old file to `user://savegame.backup.json` before a write, and moves malformed save content to `user://corrupted_save_<unix timestamp>.json`. Current schema is version 1 and stores selected faction, coins, stars, `completed_levels` result dictionary, and settings. Unlock state is inferred sequentially from completion of the numerically preceding level; it is not an explicit `unlocked_levels` array in the current schema.

### Campaign / Level Selection System

`CampaignMap.gd` reads `data/levels/level_index.json`, builds dynamic buttons and queries `SaveManager` for lock/star state. Click opens `LevelInfoPopup`, which loads `data/levels/<id>.json` and calls `Game.start_level` from its Start button. Index metadata supplies campaign names/descriptions/next links; level JSON supplies battle content and popup objectives.

### UI System

Scripts are in `scripts/ui/`; composition is in `scenes/menu` and `scenes/battle`. HUD subscribes to selection, structure update, level loaded, pause and result signals. PauseMenu subscribes to pause. Victory/Defeat subscribe to result signals and use `PROCESS_MODE_WHEN_PAUSED`. Most UI communicates through injected BattleController, autoloads, or EventBus; there is no direct absolute-path lookup of BattleController by UI.

### Data Loading System

`LevelLoader` directly parses root `data/levels/level_###.json` using `JSON`; CampaignMap/VictoryScreen use `JsonUtils.load_json_file` for index and popup detail. Runtime currently keeps untyped `Dictionary` level data. `FactionData`, `CommanderData`, and `LevelData` provide parsers but no caller loads them. Therefore root `data/levels/level_001..005.json` plus `level_index.json` are the runtime canonical level sources; faction/commander catalogs are content-only today.

### Audio System

`AudioManager` owns one `AudioStreamPlayer` for music and one for SFX. It reads volumes from `SaveManager` and reapplies them upon `EventBus.settings_changed`. MainMenu/CampaignMap request menu music; BattleScene requests battle music; result screens request their tracks. UI and battle interactions request fixed SFX constants.

### Localization System

`data/localization/ui.csv` is imported into `ui.en.translation` and `ui.ru.translation`. `LocalizationManager` reads settings at startup, calls `TranslationServer.set_locale`, persists a selected language, and exposes `tr_key`. Current UI strings and runtime level display fields are largely literal strings, and no script calls `tr_key`; this limits actual localization coverage.

## 8. Class and Method Index

### `Game`

Path: `globals/Game.gd`<br>
Responsibility: global selected-level/current-data state and game-result facade.<br>
Fields: `selected_level_id`, `current_level_data`.

- `start_level(level_id: String) -> void` — records selection indirectly through `SceneLoader.goto_battle`; called by LevelInfoPopup.
- `complete_level(level_id: String, rewards := {}) -> void` — derives reward/objective payload, saves via `SaveManager.mark_level_completed`, emits `battle_won`; called by BattleController (and stale ObjectiveTracker).
- `fail_level(level_id: String) -> void` — emits loss tip; called by BattleController (and stale ObjectiveTracker).

Dependencies: `SceneLoader`, `SaveManager`, `EventBus`. Used by menu, battle, background, result UI.

### `SaveManager`

Path: `globals/SaveManager.gd`<br>
Responsibility: save lifecycle, migration, progression queries and settings.

- `load_save() -> Dictionary` / `save_game() -> bool` — load-or-create, validate/migrate, backup/write JSON.
- `reset_progress() -> void` — resets progress but retains settings; emits `settings_changed`.
- `complete_level(level_id, stars, best_time, objectives, coins_reward) -> void` — preserves best stars/time, accumulates totals, saves.
- `mark_level_completed(level_id, unlock_levels := [], stars := 0, coins_reward := 0, completed_objectives := []) -> void` — compatibility wrapper; `unlock_levels` is currently unused.
- `is_level_unlocked`, `is_level_completed`, `get_level_stars`, `get_level_result`, `has_any_progress` — campaign/UI read API.
- `set_setting` / `update_setting`, `get_setting`, `get_settings` — persistence setting API; writes and emits settings signal on set.

Private helpers create defaults/backups, migrate legacy v0 / old `SaveData` shapes and infer previous level IDs. Dependencies: `Constants`, filesystem/JSON, `EventBus`. Used by Game, UI, audio/localization.

### `SceneLoader`

Path: `globals/SceneLoader.gd`<br>
Responsibility: scene transition boundary.

- `goto_main_menu()`, `goto_campaign()`, `goto_battle(level_id)` — unpause and call `change_scene_to_file`; battle transition assigns `Game.selected_level_id`.

Used by Game and navigation UI. It depends on `Game` and scene paths.

### `EventBus`

Path: `globals/EventBus.gd`<br>
Responsibility: global event contract. Signals: `structure_selected`, `troops_sent`, `structure_captured`, `battle_won`, `battle_lost`, `pause_changed`, `structure_updated`, `level_loaded`, `settings_changed`. Producers/consumers are listed in the dependency map below.

### `AudioManager`

Path: `globals/AudioManager.gd`<br>
Responsibility: global music/SFX and saved volumes.

- `play_music(track_path)` / `play_sfx(sfx_path)` — resource-checked player requests.
- `play_menu_music`, `play_battle_music`, `play_victory_music`, `play_defeat_music` — fixed track convenience methods.
- `set_master_volume`, `set_music_volume`, `set_sfx_volume` — persist values through SaveManager; `_apply_settings` responds to the event.

### `LocalizationManager`

Path: `globals/LocalizationManager.gd`<br>
Responsibility: language choice.

- `set_language(language_code)` — calls `TranslationServer.set_locale` and saves setting.
- `tr_key(key) -> String` — wraps Godot `tr`.

### `BattleScene`

Path: `scripts/battle/BattleScene.gd`<br>
Responsibility: composition glue. `_ready()` starts battle music and calls `setup(controller)` on HUD and PauseMenu. It owns no battle rules.

### `BattleController`

Path: `scripts/battle/BattleController.gd`<br>
Responsibility: match coordinator and state machine (`RUNNING`, `PAUSED`, `VICTORY`, `DEFEAT`).

Fields: exported `level_id`, root NodePaths; `selected_structure`, `level_data`, `battle_state`, `structures_by_id`.

- `is_running`, `is_paused`, `is_finished`, `can_accept_input`, `can_send_troops`, `can_ai_act` — runtime state guards.
- `request_pause_toggle`, `request_resume`, `request_restart`, `request_exit_to_campaign` — UI/input commands; pause changes tree pause state and emits `pause_changed`.
- `get_structures_by_owner`, `get_structure_count`, `get_structure_by_id`, `get_active_troop_stream_count` — HUD/AI read API.
- `send_troops(source, target, send_fraction := 0.5) -> bool` — delegates subtraction/stream request to Structure; plays SFX and emits `troops_sent`.

Key callbacks: `_on_structure_clicked` applies select/send rules; `_on_troops_requested` creates/configures a stream; `_on_structure_owner_changed` emits capture and schedules check; `_on_troop_stream_finished` schedules a check for arrival or in-transit destruction; `_check_battle_state` calls Game result API. Depends on LevelLoader, EnemyAI, Structure, TroopStream, AudioManager, EventBus, Game/SceneLoader.

### `LevelLoader`

Path: `scripts/battle/LevelLoader.gd`<br>
Responsibility: parse runtime level JSON and build the structure graph.

- `load_level(level_id, structures_root) -> Dictionary` — clears old structures; parses root `data/levels/<id>.json`; resolves optional isometric positions; instantiates/configures structures; validates/resolves links; emits `level_loaded`.
- `get_structure_by_id(id) -> Structure` — lookup in `structures_by_id`.

It also owns private position parsing/isometric centering and connection validation helpers. Used exclusively by BattleController.

### `Structure`

Path: `scripts/world/Structure.gd`<br>
Responsibility: one tower's state, production, input and combat result.

Important fields: `structure_id`, `owner_id`, `garrison`, `max_garrison`, `level`, `unit_type`, `connected_to`, resolved `neighbors`; selection/production accumulators. `unit_type` accepts `infantry`/`archer`/`cavalry`, defaults safely to infantry, and is intentionally unchanged by capture. Generation rate is queried from `GameBalance`, not stored per Structure.

- `setup_from_data(data)` — applies supported JSON fields, including backward-compatible `unit_type`.
- `get_unit_type()` / `is_valid_unit_type(value)` — unit-type read/validation API for transit/UI.
- `can_generate_units() -> bool` — live/enabled, non-neutral owner, positive rate, and not-at-cap generation guard.
- `advance_unit_generation(delta)` — the sole production step called by `_process`; accumulates rate, produces whole units and caps garrison.
- `resolve_neighbors(structure_map)` — resolves string IDs to Structure nodes.
- `can_send_to(target) -> bool` — connected target and at least 2 garrison.
- `send_troops(target, send_fraction := 0.5) -> float` — subtracts floored amount, updates visual, emits `troops_requested`.
- `resolve_combat(attacker_owner, attack_power)` — reinforces or subtracts/captures and emits owner change if needed.
- `select` / `deselect` — selection visual state.

Signals: `structure_clicked(Structure)`, `troops_requested(source,target,amount)`, `owner_changed(structure,previous_owner,new_owner)`. Used by LevelLoader/BattleController/rendering/HUD.

### `TroopStream`

Path: `scripts/world/TroopStream.gd`<br>
Responsibility: one dispatched troop batch.

Fields: exported `speed = 180.0`, `owner_id`, `amount`, `unit_type`, `source`, `target`; private finish/resolution guards and injected battle-running Callable. `setup(...)` validates owner (`player`/`enemy`), inherits a valid unit type from source or falls back to infantry, and configures owner/unit presentation. `_process(delta)` moves a surviving stream and resolves target arrival. `DetectionArea.area_entered` resolves only opposing stream pairs while BattleController is running. Signals: `arrived(stream)` only for target arrival; `finished(stream, reason)` for all terminal states, listened to by BattleController.

### `EnemyAI`

Path: `scripts/battle/EnemyAI.gd`<br>
Responsibility: simple periodic hostile-order policy.

- `setup(controller)` — dependency injection.
- `_process(delta)` — accumulates default 2.5-second tick when controller accepts AI.
- `_take_turn()` — first enemy source above 20 sends 50% to weakest neutral/player neighbor.

### `ObjectiveTracker`

Path: `scripts/battle/ObjectiveTracker.gd`<br>
Responsibility: intended older objective/star system, not part of BattleScene.

- `setup(controller, new_level_data: LevelData)` — assigns dependencies.
- `check_state()` — tries player-empty/all-player-owned result checks.

It is not instanced or called. Its call to nonexistent `BattleController.all_structures_owned_by` is a documented risk.

### `BattleBackground` and `ConnectionRenderer`

Paths: `scripts/battle/BattleBackground.gd`, `scripts/battle/ConnectionRenderer.gd`.<br>
Responsibilities: procedural decorative isometric ground/path background; connection lines and selected-link highlighting. Both receive a `structures_root_path` from BattleScene. Background rebuilds after `level_loaded`; renderer listens to `structure_selected` and redraws every frame.

### `HUD` / `DebugBattleOverlay`

Paths: `scripts/ui/HUD.gd`, `scripts/ui/DebugBattleOverlay.gd`.<br>
Responsibility: HUD gets controller through `setup`, requests pause, renders selected structure or aggregated count. It listens to EventBus selection, update, load, pause and result signals. Debug overlay gets the same controller and writes four counts each frame; default visibility is only debug builds.

### `PauseMenu`, `VictoryScreen`, `DefeatScreen`

Paths: `scripts/ui/PauseMenu.gd`, `scripts/ui/VictoryScreen.gd`, `scripts/ui/DefeatScreen.gd`.<br>
Responsibilities: PauseMenu `setup`, result buttons and settings; Victory responds to `battle_won` and uses `level_index.json` for Next; Defeat responds to `battle_lost`. All result actions use SceneLoader. Pause/Victory/Defeat process while tree is paused.

### `MainMenu`, `CampaignMap`, `LevelInfoPopup`, `SettingsScreen`

Paths: corresponding `scripts/ui/*.gd`.<br>
Responsibilities: menu state/navigation; dynamic indexed level rows; selected level display/start; saved settings and display mode. Their key public-looking entry points are `CampaignMap._load_levels()`, `LevelInfoPopup.show_level(level_data)`, and each screen's `_on_*` button callbacks.

### `LevelData`, `FactionData`, `CommanderData`, `SaveData`

Paths: `scripts/data/*.gd`.<br>
Responsibilities: RefCounted data-transfer models with a `static from_dict(data)` parser (and `SaveData.to_dict`). They describe intended schemas but are not invoked by current runtime loaders. `SaveData` is a legacy schema (version 2 with `unlocked_levels`/array completion), unlike SaveManager's current version-1 dictionary schema.

### `GameBalance`

Path: `scripts/data/GameBalance.gd`<br>
Responsibility: typed Resource schema for globally shared battle balance. It currently exports `structure_generation_rate` (units/s), instantiated by `data/config/game_balance.tres` with value `4.0`. Structure preloads this resource and uses it for every non-neutral tower; levels no longer define a generation rate.

### `Constants` and `JsonUtils`

Paths: `scripts/utils/Constants.gd`, `scripts/utils/JsonUtils.gd`.<br>
`Constants` defines faction IDs, save/settings paths and `DEFAULT_SEND_FRACTION`; only save path is consumed in current runtime. `JsonUtils.load_json_file`/`save_json_file` is a generic FileAccess/JSON helper; CampaignMap and VictoryScreen use `load_json_file`.

## 9. Data Files Map

| Data file | Path | Purpose | Loaded by | Important fields |
| --- | --- | --- | --- | --- |
| Campaign index | `data/levels/level_index.json` | Ordered campaign listing and Next-level links. | CampaignMap, VictoryScreen. | `id`, `name`, `description`, `next_level`. |
| Runtime levels | `data/levels/level_001.json` … `level_005.json` | Authoritative battle definitions currently used by loader. | LevelLoader; CampaignMap popup. | `id`, `name`, `difficulty`, `time_limit_star`, factions, `weather`, `objectives`, `rewards`, `structures.unit_type`. |
| Legacy/alternate campaign levels | `data/levels/campaign_01/level_001.json` … `003.json` | Alternate, currently unreferenced definitions. | Nobody. | `name_key`, `description_key`, `scene_type`, commander, conditions, `ai`, structures/rewards. |
| Faction catalog | `data/factions/factions.json` | Intended faction metadata. | Nobody. | `id`, `name_key`, color/tints, banner, default music. |
| Commander catalog | `data/factions/commanders.json` | Intended commander metadata. | Nobody. | `id`, keys, portrait, `faction_id`, `ai_profile`. |
| Balance resource | `data/config/game_balance.tres` | Global tower-generation balance. | Structure via `GameBalance`. | `structure_generation_rate` (units/s). |
| AI resource | `data/config/ai_config.tres` | Intended AI tuning Resource. | Nobody. | No custom fields yet. |
| Source translation | `data/localization/ui.csv` | English/Russian translation entries. | Godot CSV Translation importer. | `keys`, `en`, `ru`. |
| Imported translations | `data/localization/ui.en.translation`, `ui.ru.translation` | Generated binary translations. | Godot TranslationServer/import pipeline. | Generated from CSV; do not hand-edit. |
| User save (runtime) | `user://savegame.json` | Progress/settings persistence; not versioned in repo. | SaveManager. | `version`, `selected_faction`, `coins`, `stars`, `completed_levels`, `settings`. |
| Structure generation test | `tests/StructureGenerationTest.tscn` + `tests/structure_generation_test.gd` | Native headless regression test for tower generation and owner transitions. | Godot scene runner. | Friendly/enemy/neutral, cap, capture, disabled/removal, rate/limit. |

## 10. Dependency Map

### Actual layer direction

```text
UI -> EventBus / AudioManager / SaveManager / SceneLoader / injected BattleController
BattleController -> LevelLoader -> Structure -> EventBus
BattleController -> EnemyAI / TroopStream / Game
Game -> SaveManager / SceneLoader / EventBus
SaveManager -> Constants / FileAccess / EventBus
Campaign UI -> JsonUtils -> JSON data
```

`BattleBackground` additionally reads global `Game.current_level_data`; `ConnectionRenderer` reads Structure nodes and EventBus selection. Structure depends directly on EventBus for visual-update events; TroopStream calls Structure directly on arrival.

### Event contract: real producers and listeners

| Event | Producer | Current listeners |
| --- | --- | --- |
| `level_loaded` | LevelLoader | HUD, BattleBackground |
| `structure_selected` | BattleController | HUD, ConnectionRenderer |
| `structure_updated` | Structure | HUD |
| `structure_captured` | BattleController | No listener found |
| `troops_sent` | BattleController | No listener found |
| `pause_changed` | BattleController | HUD, PauseMenu |
| `battle_won` | Game | HUD, VictoryScreen |
| `battle_lost` | Game | HUD, DefeatScreen |
| `settings_changed` | SaveManager | AudioManager, MainMenu |

### Dependency observations

- UI does **not** search a BattleController via an absolute scene path; BattleScene injects it into HUD/PauseMenu. This is a good boundary to retain.
- Battle logic still directly triggers `AudioManager` and global result flow via `Game`, and Structure directly emits global EventBus updates. These are intentional MVP shortcuts, but increase global coupling.
- Exported NodePaths inside BattleController/renderer/background are relative, not absolute; they nevertheless couple scripts to the current BattleScene hierarchy.
- SaveManager has no UI dependency and Structure has no progression/campaign dependency.

## 11. Task Navigation Guide

| Task | Start here | Also check | Do not touch unless needed |
| --- | --- | --- | --- |
| Изменить отправку войск | `scripts/battle/BattleController.gd`, `scripts/world/Structure.gd` | TroopStream, HUD hint, Constants | Save/progression, LevelLoader. |
| Изменить скорость потока | `scripts/world/TroopStream.gd` | `scenes/world/TroopStream.tscn`, BATTLE_FLOW | AI/data unless making it configurable. |
| Изменить столкновения потоков | `scripts/world/TroopStream.gd` | TroopStream scene collision layer/mask, BattleController finish handling, focused collision test | Structure and level JSON. |
| Изменить unit type башни/потока | `scripts/world/Structure.gd` | TroopStream, HUD, active root level JSON, DATA_MODEL | Combat formula, AI policy, factions/commanders. |
| Изменить генерацию башен | `scripts/world/Structure.gd` | `data/config/game_balance.tres`, HUD | Per-level JSON: it must not contain `generation_rate`. |
| Проверить генерацию башен | `tests/structure_generation_test.gd` | `tests/StructureGenerationTest.tscn`, Structure.gd | Do not require a second Timer/test framework. |
| Изменить победу/поражение | `scripts/battle/BattleController.gd` | Game, result screens, BATTLE_FLOW | Stale ObjectiveTracker unless deliberately reactivating it. |
| Изменить AI | `scripts/battle/EnemyAI.gd` | BattleController, DATA_MODEL | `ai` JSON/config until code begins reading them. |
| Добавить тип структуры | Structure + `scenes/world/Structure.tscn` | LevelLoader, art, data contract | Existing `type` JSON alone has no runtime effect. |
| Добавить уровень | `data/levels/level_###.json` | `level_index.json`, CampaignMap, DATA_MODEL | `campaign_01/` duplicate source. |
| Изменить карту кампании | CampaignMap scene/script | level index, LevelInfoPopup, SaveManager unlock | Battle flow. |
| Изменить открытие уровней | SaveManager `is_level_unlocked` | Game rewards, index, save migration | Do not assume `unlock_levels` works today. |
| Изменить victory screen | VictoryScreen scene/script | Game completion payload, index | Battle state only if result semantics change. |
| Изменить pause | BattleController + PauseMenu | HUD, tree pause process modes | Result screen behavior. |
| Изменить settings | SettingsScreen | SaveManager, AudioManager, LocalizationManager | MainMenu state / reset semantics. |
| Добавить локализацию | `data/localization/ui.csv` | literal UI and level strings to convert with `tr()` | Generated `.translation` files. |
| Добавить звук | `assets/audio/` then AudioManager | concrete caller and licenses | Do not duplicate playback ownership. |
| Добавить фракцию | `data/factions/factions.json`, FactionData | owner-ID mapping, Structure colors/assets | Claiming runtime support without wiring loader. |
| Добавить командира | commanders JSON, CommanderData | level schema and an eventual controller | No CommanderController exists. |
| Изменить баланс | Structure, TroopStream, EnemyAI, level JSON | DATA_MODEL hardcoded list | Empty `*.tres` have no effect. |
| Подготовить Steam achievement | Add integration layer first | Game completion / EventBus battle result | SteamManager is absent; do not put platform calls in Structure. |

## 12. Known Architecture Risks

| Risk | Files | Why it matters | Suggested future fix |
| --- | --- | --- | --- |
| Duplicate level sources and schemas | `data/levels/*.json`, `data/levels/campaign_01/*`, README | Loader uses only root files; nested campaign definitions have different fields (`ai`, commander's metadata) and can silently drift. | Choose one canonical folder/schema, migrate content, make loader/index use it, then remove/archive the other. |
| Runtime ignores level conditions and AI metadata | BattleController, EnemyAI, nested level JSON | `victory_conditions`, `defeat_conditions`, `ai.think_interval` are not consulted; actual rules are hardcoded. | Introduce one tested condition/AI-config consumption path or remove unsupported fields. |
| Intended data models are unused / SaveData conflicts | `scripts/data/*.gd`, SaveManager | Runtime dictionaries do not use LevelData/FactionData/CommanderData; SaveData v2 shape conflicts with current SaveManager v1 shape. | Select canonical typed models/schema and remove or migrate obsolete compatibility types. |
| Progression data contract is misleading | Game, SaveManager, level rewards | `unlock_levels` is passed into `mark_level_completed` but ignored; unlocking is inferred by numeric predecessor. | Either persist/read explicit unlocks or remove reward field and document sequential-only progression. |
| Balance coverage is partial | `data/config/game_balance.tres`, `ai_config.tres`, TroopStream, EnemyAI | Tower generation is now resource-driven, but troop speed, send fraction and AI rules remain hardcoded; AI config is still empty/unread. | Extend resource-backed balance incrementally per owning system. |
| Generation behavior depended on an inline condition | Structure | The original `owner_id != "neutral"` condition was correct but not independently named/testable, which made later state changes easier to regress. | Addressed: `can_generate_units` and one `advance_unit_generation` path now define and test the contract; keep the rule centralized. |
| Stale ObjectiveTracker | ObjectiveTracker, BattleScene | It is not instanced; it expects typed LevelData and calls nonexistent `all_structures_owned_by`, so activation would fail. | Delete after confirmation or rewrite/test it before wiring it into BattleScene. |
| Faction/commander catalog not integrated | faction JSON/data classes, Structure | Runtime uses owner IDs `player`/`neutral`/`enemy`; catalog has `enemy_01`, and catalog asset paths are not verified by runtime. | Add faction resolver/owner mapping and load catalog once; wire commander/AI only with a real feature. |
| Localization coverage is mostly literal English | UI scripts/scenes, root level JSON, LocalizationManager | Changing locale does not translate hardcoded UI labels or `name`/objective text; `tr_key` has no caller. | Convert display strings to translation keys and add keys to CSV; make one localization audit. |
| Scene-topology coupling | BattleController, BattleBackground, ConnectionRenderer and BattleScene NodePaths | Relative NodePaths will break if `World` structure changes. | Inject roots or expose a battle context/composition API; retain no absolute paths. |
| Order-sensitive initial HUD setup | BattleScene, BattleController, LevelLoader, HUD | LevelLoader emits `level_loaded` before the later CanvasLayer/HUD node connects; HUD `setup` also occurs after its `_ready()` reset. Initial level label/hint and aggregate placeholder values can remain stale until a later event/selection. | Inject/refresh initial battle data explicitly after HUD setup, or connect before loading the level. |
| Startup fullscreen setting is not applied | SettingsScreen, SaveManager | Setting is saved, but only toggling within Settings calls `DisplayServer.window_set_mode`; saved fullscreen is not applied by an autoload. | Apply display settings during startup in a dedicated settings-application step. |
| Headless main-scene shutdown warning | MainMenu / global audio lifetime not yet attributed | `Godot --headless --path . --quit` reaches startup but reports one ObjectDB instance and one resource still in use at exit. | Investigate ownership/cleanup separately; do not suppress the warning without locating its source. |
| Unused placeholders / duplicated debug scene | Boot/common/world placeholders, DebugBattleOverlay scene/HUD | Increases navigation ambiguity; standalone DebugBattleOverlay is not the instance used in HUD. | Remove/mark templates, or instance one shared debug scene. |

No code was changed to address these risks in this documentation task.
