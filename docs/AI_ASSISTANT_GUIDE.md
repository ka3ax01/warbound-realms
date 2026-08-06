# AI Assistant Guide

## Before Changing Code

Всегда сначала прочитать в таком порядке:

1. `docs/PROJECT_MAP.md` — ownership, active paths, risks и Task Navigation Guide.
2. `docs/BATTLE_FLOW.md` — если задача касается боя, input, pause, результата, потоков или структуры.
3. `docs/DATA_MODEL.md` — если задача читает/пишет JSON, Resource, save, progression, balance или localization.
4. Конкретный файл из раздела **Where to change what** в Project Map.
5. Его прямых вызывающих и вызываемых соседей: сначала `rg` по имени метода/signal, затем открыть только релевантные сцены и скрипты.

Перед изменением убедиться, что файл и путь действительно активны. В частности, runtime берёт уровни из `data/levels/level_###.json`, а не из `data/levels/campaign_01/`; config `.tres`, faction/commander catalogs и `ObjectiveTracker` в текущем runtime не подключены.

## Rules

- Не менять поведение без явной причины и не подменять запрошенную feature скрытым redesign.
- Не совмещать большой refactor с feature или bug fix. Сначала сделать минимальное изменение в текущем ownership boundary; отдельно предложить refactor, если он нужен.
- Не трогать Steam, фракции, командиров и meta economy, если задача не про них. `SteamManager` и `CommanderController` отсутствуют.
- Не добавлять hardcode, если параметр должен быть content/balance data. Но не создавать «на будущее» новую data model без того, чтобы подключить её к единственному reader.
- Не использовать absolute scene paths для поиска gameplay node. BattleScene уже inject-ит `BattleController` в HUD/PauseMenu; предпочитать явную dependency injection или signal.
- Не создавать вторую модель/папку данных, если уже существует canonical source. Для уровней это `data/levels/level_###.json` + `level_index.json`; для save — SaveManager v1 schema.
- Не считать наличие JSON-поля или `.tres` доказательством его работы: проверять reader. Сейчас `GameBalance.structure_generation_rate` и `structures[].unit_type` активны; unit type (`infantry`/`archer`/`cavalry`) пока влияет только на HUD/визуал потока и не меняет бой. `type`, `weather`, `time_limit_star`, alternate `ai`, faction/commander data и empty `ai_config.tres` не влияют на gameplay.
- Сохранять разделение ownership: Structure хранит локальное tower state; TroopStream отвечает за transit; BattleController — match state/result; Game — session/result facade; SaveManager — persistence; UI — presentation/navigation.
- При изменении scene tree проверить exported relative NodePaths у BattleController, BattleBackground и ConnectionRenderer.
- Использовать `EventBus` для широкого gameplay-to-UI notification, когда событие уже есть. Не добавлять global signal для локальной одноразовой зависимости без необходимости.
- Не обрабатывать `battle_won`/`battle_lost` как обычную running UI-событие: дерево уже paused. Result UI должен иметь `PROCESS_MODE_WHEN_PAUSED`.
- После изменения обновить документацию, если поменялись flow, методы, файлы, scene tree, data model, canonical source или task navigation.

## Fast Orientation

| Question | Open first | Verify next |
| --- | --- | --- |
| Кто начинает бой? | `scripts/battle/BattleController.gd` | `BattleScene.tscn`, `LevelLoader.gd`, BATTLE_FLOW. |
| Откуда пришло событие UI? | `globals/EventBus.gd` | `rg 'EventBus.<signal>'`, receiving UI script. |
| Где реально лежит content level? | `scripts/battle/LevelLoader.gd` | `data/levels/level_###.json`, `CampaignMap.gd`. |
| Почему кнопка кампании locked? | `globals/SaveManager.gd` | `level_index.json`, current save schema. |
| Где применить баланс? | DATA_MODEL balance table | Structure/TroopStream/EnemyAI plus any live reader. |
| Почему translation не видна? | LocalizationManager and `ui.csv` | Literal text in scenes/scripts and use of `tr()`. |
| Где запустить transition? | `globals/SceneLoader.gd` | Caller’s pause state and `Game.selected_level_id`. |

## How to Update Docs

After every relevant code change:

- Update `PROJECT_MAP.md` if files/classes/autoloads/scenes, dependency direction, runtime flow, task routing, or risks changed.
- Update `BATTLE_FLOW.md` if battle start, input, selection, send, combat, pause, result state, edge-case semantics, or BattleScene tree changed.
- Update `DATA_MODEL.md` if a JSON/Resource/save field, loading source, faction/commander contract, balance source, or localization contract changed.
- Update Project Map's **Task Navigation Guide** if a new service/layer becomes the correct entry point for a task.
- Remove or revise a risk only after the code actually resolves it and a focused verification was run.

Documentation should state the implementation that exists, including deliberately unsupported fields. Do not document a planned feature as active.

## Common Change Recipes

### Change battle logic

1. Read `BattleController.gd`, `Structure.gd`, `TroopStream.gd`, and `docs/BATTLE_FLOW.md`.
2. Identify the owner: global match-state condition -> BattleController; local tower rule -> Structure; travel/arrival -> TroopStream.
3. Search callers and EventBus consumers before changing a signal payload or public method.
4. Preserve guards for `RUNNING`, active-stream result protection, and pause behavior unless the task explicitly changes them.
5. Run `godot --headless --path . --scene res://tests/StructureGenerationTest.tscn` for generation changes, then test entering a level, selection/send, capture, victory, defeat, pause/resume and restart. Update BATTLE_FLOW/PROJECT_MAP.

### Add a level

1. Use active root path `data/levels/level_###.json`; copy the **active root schema**, not `campaign_01` schema.
2. Define unique IDs and valid `connected_to` routes; author reverse routes intentionally because they are not inferred.
3. Add the ordered campaign entry and `next_level` to `data/levels/level_index.json`.
4. Check sequential unlock behavior in SaveManager: it derives previous numeric level ID and ignores `rewards.unlock_levels`.
5. Run the level and confirm LevelLoader reports no duplicate/missing link errors. Update DATA_MODEL if schema changes, otherwise document content only where the project’s content workflow expects it.

### Change UI

1. Open both scene (`scenes/menu` or `scenes/battle`) and matching `scripts/ui/*.gd`.
2. Determine whether the screen gets data via EventBus, an injected controller, an autoload or local level data. Do not replace controller injection with path traversal.
3. For pause/result UI, retain `PROCESS_MODE_WHEN_PAUSED` when interaction must work after pause.
4. If visible player-facing text is added, decide whether it must be a translation key. Current literal coverage is incomplete; do not accidentally mix a third localization pattern.
5. Update Project Map scene table and BATTLE_FLOW when UI event/state routing changes.

### Change save / progression

1. Read `SaveManager.gd` completely and then DATA_MODEL's Save Data section.
2. Treat `user://savegame.json` and its migration/backup behavior as the source of truth, not `SaveData.gd`.
3. Preserve old saves with a migration and default merge. Do not remove fields or change type without compatibility logic.
4. Check callers: Game completion, CampaignMap lock/stars, MainMenu Continue, SettingsScreen, AudioManager and LocalizationManager.
5. If unlock logic changes, align `level_index.json`, reward contract and SaveManager rather than changing one in isolation. Update PROJECT_MAP and DATA_MODEL.

### Change AI

1. Read `EnemyAI.gd`, BattleController send API, Structure neighbor/guard rules, and BATTLE_FLOW.
2. Keep AI orders going through `BattleController.send_troops`; do not mutate garrison or create TroopStream directly from AI.
3. If adding data-driven AI values, create a single active reader and connect the chosen level/resource source. Existing `ai.think_interval`, `ai.profile` and `ai_config.tres` do nothing today.
4. Test pausing and result state: `can_ai_act()` must block actions outside `RUNNING`.
5. Update DATA_MODEL balance table and BATTLE_FLOW.

### Add a new structure type

1. Read `Structure.gd`, `Structure.tscn`, `LevelLoader.gd`, BattleController and DATA_MODEL.
2. Decide whether it is a visual variation, a data variation, or a different gameplay class/scene. The current JSON `type` is inert, so simply adding a new string has no effect.
3. Define a single instantiation/resolution path in LevelLoader and preserve the Structure signal contract expected by BattleController.
4. Add art/resource paths and validate a level using the new type. Do not place campaign/progression knowledge inside the structure.
5. Document schema, loader behavior, scene map and relevant task navigation.

### Change tower unit type

1. Read `Structure.gd`, `TroopStream.gd`, HUD, active root level JSON, and DATA_MODEL.
2. Keep `unit_type` as a tower property: valid values are `infantry`, `archer`, and `cavalry`; missing/unknown data must safely fall back to infantry.
3. Preserve the existing `TroopStream.setup` boundary: player and AI orders both flow through BattleController and inherit the type from their source Structure.
4. Do not add unit combat, collision, generation, ownership, faction, or commander modifiers without a separately scoped gameplay milestone.
5. Run StructureGenerationTest and TroopStreamCollisionTest, then update PROJECT_MAP, BATTLE_FLOW, and DATA_MODEL.

### Add a new balance parameter

1. Locate the existing real owner of the behavior: Structure, TroopStream, EnemyAI, BattleController or level JSON.
2. Choose one data authority that is actively loaded. Tower generation belongs to `game_balance.tres`; do not reintroduce `generation_rate` into level JSON. `ai_config.tres` remains inactive.
3. Thread the value explicitly to the owner; add a backward-compatible default for existing levels/saves where needed.
4. Search for duplicate literals and either keep intentional local defaults documented or consolidate as part of a scoped refactor.
5. Update DATA_MODEL's balance table and tests/manual acceptance notes.

## Definition of Done for a Change

- The changed owner and all direct consumers compile/load in Godot.
- Manual coverage is proportional to the feature; for battle changes include select/send/capture/pause/result routes.
- No active data source has drifted from its reader.
- No stale hardcoded UI hint contradicts input behavior.
- Relevant technical docs accurately explain the new runtime behavior.
- `git diff` contains only the requested code/content/documentation scope; generated `.uid`, `.import`, and `.godot` noise is excluded.

## Current High-Risk Boundaries

Before work that touches any of these, read the matching risk row in `PROJECT_MAP.md`:

- root runtime levels vs unreferenced `campaign_01` level definitions;
- SaveManager v1 dictionary schema vs legacy `SaveData` model;
- sequential computed unlocks vs ignored `unlock_levels` rewards;
- resource-backed tower generation vs remaining hardcoded battle/AI values;
- inactive ObjectiveTracker and missing `all_structures_owned_by` API;
- `enemy` runtime owner vs `enemy_01` faction catalog;
- literal UI strings vs nominal localization system.
