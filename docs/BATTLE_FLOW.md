# Battle Flow

> Этот документ описывает текущий battle runtime. Названия методов и последовательности соответствуют коду; JSON-поля, которые пока не читаются, помечены отдельно.

## Battle Scene Tree

```text
BattleScene : Node2D                                      [BattleScene.gd]
├── World : Node2D
│   ├── Background : Node2D                               [BattleBackground.gd]
│   │   └── generated Sprite2D tiles/roads/decor at runtime
│   ├── Connections : Node2D                              [ConnectionRenderer.gd]
│   ├── Structures : Node2D                               # LevelLoader adds Structure instances
│   │   └── Structure : Node2D                            [Structure.gd] × N
│   │       ├── SelectionRing : Sprite2D
│   │       ├── OwnerGlow : Sprite2D
│   │       ├── TowerSprite : Sprite2D
│   │       ├── GarrisonLabel / ProductionLabel : Label
│   │       └── ClickArea : Area2D / CollisionShape2D
│   ├── TroopStreams : Node2D                             # BattleController adds streams
│   │   └── TroopStream : Node2D                          [TroopStream.gd] × N
│   │       ├── Trail / Glow / Marker : ColorRect
│   │       └── AmountLabel : Label
│   └── VFX : Node2D                                      # Present, unused
├── Controllers : Node
│   └── BattleController : Node                           [BattleController.gd]
│       ├── EnemyAI : Node                                [EnemyAI.gd]
│       └── LevelLoader : Node                            [LevelLoader.gd]
└── CanvasLayer : CanvasLayer
    ├── HUD : Control                                      [HUD.gd]
    ├── PauseMenu : Control                                [PauseMenu.gd]
    │   └── SettingsScreen
    ├── VictoryScreen : Control                            [VictoryScreen.gd]
    └── DefeatScreen : Control                             [DefeatScreen.gd]
```

`BattleScene` is composition glue: in `_ready()` it starts battle music and calls `hud.setup(battle_controller)` / `pause_menu.setup(battle_controller)`. `BattleController` is the coordinator. `LevelLoader`, `EnemyAI`, Structure signals, troop arrival, `Game`, `EventBus`, and AudioManager all meet there.

`Background` and `Connections` are siblings of the dynamic roots, not children of BattleController. Both receive `../Structures` via an exported relative `NodePath`; Background rebuilds after `EventBus.level_loaded`, while Connections redraws based on Structure neighbor data and selection events.

## Battle Startup

The following is the runtime sequence after `SceneLoader.goto_battle(level_id)` changes to `BattleScene.tscn`.

1. `SceneLoader.goto_battle(level_id)` writes `Game.selected_level_id = level_id`, clears `get_tree().paused`, and changes to `res://scenes/battle/BattleScene.tscn`.
2. Child nodes become ready. `BattleController._ready()` obtains the requested ID from its exported `level_id` if provided; otherwise it uses `Game.selected_level_id`.
3. `BattleController` calls `level_loader.load_level(resolved_level_id, structures_root)`. `structures_root` is `../../World/Structures` from the controller node.
4. `LevelLoader.load_level`:
   - frees old children under Structures and clears its lookup map;
   - opens **only** `res://data/levels/<level_id>.json`;
   - validates JSON root is a dictionary and `structures` is an array;
   - calculates optional isometric origin (`iso_origin` or derived from `iso_position`);
   - instantiates `Structure.tscn` for each valid structure entry;
   - calls `Structure.setup_from_data`; rejects missing/duplicate IDs;
   - validates all `connected_to` IDs and calls `Structure.resolve_neighbors`.
5. LevelLoader emits `EventBus.level_loaded(level_id)` and returns the raw level dictionary. BattleController assigns it to both `level_data` and `Game.current_level_data`; it copies `level_loader.structures_by_id`.
6. BattleController subscribes to every instantiated Structure:
   - `structure_clicked` -> `_on_structure_clicked`;
   - `troops_requested` -> `_on_troops_requested`;
   - `owner_changed` -> `_on_structure_owner_changed`.
7. `enemy_ai.setup(self)` supplies EnemyAI its coordinator. It starts ticking only while battle state is `RUNNING`.
8. `BattleBackground`, already subscribed to `level_loaded`, calls deferred `_build_background()`: it rebuilds terrain, roads inferred from resolved neighbors, and border decor. The CanvasLayer/HUD subtree becomes ready only later, so HUD connects to `level_loaded` **after this initial emit** and misses it.
9. `BattleScene._ready()` plays `AudioManager.play_battle_music()` and injects BattleController into HUD and PauseMenu. HUD's embedded DebugBattleOverlay receives it too. `HUD.setup` does not currently call `_on_level_loaded` or refresh the aggregate placeholder panel, so those initial HUD values may remain stale until a later selection/update; this is a documented architecture risk.

### Startup contracts and non-contracts

- Required functional level field: `structures`, with a unique `id` and valid `connected_to` references per entry.
- Supported structure fields are exactly implemented by `Structure.setup_from_data`: `id`, `position`/`iso_position`, `owner`, `garrison`, `max_garrison`, `level`, `unit_type`, `connected_to`. `unit_type` accepts `infantry`, `archer`, `cavalry`; missing/unknown values safely become `infantry`. Generation rate is intentionally not a level field.
- Root runtime levels presently use Cartesian `position`; LevelLoader also supports `iso_position` but current root campaign levels do not require it.
- `type`, `difficulty`, `weather`, `player_faction`, `enemy_faction`, `time_limit_star`, `objectives`, and `rewards` may appear in root JSON but do not change Structure construction. `rewards` is read only when victory is saved/emitted.
- Nested `data/levels/campaign_01/*` data, its `ai`, commander and condition fields are not considered by this path.

## Player Input Flow

### Input surface

- **Left mouse button**: `Structure._on_input_event()` receives a pressed LMB from `ClickArea` and emits `structure_clicked(self)`.
- **Right mouse button**: `BattleController._unhandled_input()` clears current selection while battle accepts input.
- **Esc / `ui_cancel`**: the same controller handler toggles pause and marks input handled.
- **HUD Pause button**: `HUD._on_pause_pressed()` invokes injected controller's `request_pause_toggle()`.

Only `BattleState.RUNNING` allows selection/order input. `BattleController.can_accept_input()` and `can_send_troops()` both return false for paused or finished battles.

### Structure generation lifecycle

Each Structure retains a single `_production_accumulator`; it has no `Timer` node and does not start a coroutine/cycle on owner change. On every normal Godot `_process(delta)`, Structure calls `advance_unit_generation(delta)`. That method first calls `can_generate_units()` and produces only when the current owner is not `neutral`, the Structure is in the tree, enabled, not queued for deletion, `GameBalance.structure_generation_rate` is positive, and the Structure is below its JSON `max_garrison`.

Because the predicate reads the **current** `owner_id`, capture changes behavior on the next process step without setup-time state being cached:

- Neutral -> player/enemy: production begins.
- Player/enemy -> neutral: production stops.
- Player <-> enemy: production continues under the new owner.

Tree pause prevents `_process`, and queued-for-deletion/disabled nodes are also excluded by the predicate. `structure_generation_rate` comes from the shared GameBalance resource; `max_garrison` continues to come from each structure's level JSON entry.

### Selection and target rules

`BattleController._on_structure_clicked(clicked)` uses this decision table:

| Current selection | Clicked structure | Result |
| --- | --- | --- |
| None | Player-owned | `_set_selected_structure(clicked)`: select visual, select SFX, `EventBus.structure_selected(id, owner)`. |
| None | Neutral/enemy | Error SFX; no selection. |
| Same selected structure | Same | `_clear_selection()`, deselect visual, emits empty selection. |
| Player selected | A resolved neighbor | `send_troops(selected, clicked, 0.5)`, then clear selection. The target can be player, neutral or enemy. |
| Player selected | Non-neighbor / invalid | Error SFX. If clicked is player, it becomes new selection; otherwise selection clears. |

`Structure.can_send_to(target)` independently enforces that target is non-null, is in resolved `neighbors`, and source garrison is at least 2. This means a direct caller of `BattleController.send_troops` still cannot create an arbitrary route.

HUD listens to `structure_selected` and displays source id/owner. It then retrieves the structure through `BattleController.get_structure_by_id` and shows owner, garrison/max, production, level, and raw `connected_to` identifiers. `ConnectionRenderer` listens to the same event and highlights links touching the selected id.

## Troop Send Flow

```text
LMB on Structure.ClickArea
  -> Structure.structure_clicked(clicked)
  -> BattleController._on_structure_clicked(clicked)
  -> BattleController.send_troops(source, target, 0.5)
  -> Structure.send_troops(target, 0.5)
      -> floor(source.garrison * 0.5), subtract source garrison
      -> Structure._update_visuals() / EventBus.structure_updated
      -> Structure.troops_requested(source, target, amount)
  -> BattleController._on_troops_requested(...)
      -> instantiate TroopStream.tscn under World/TroopStreams
      -> inject BattleController.is_running guard
      -> connect stream.finished to BattleController._on_troop_stream_finished
      -> TroopStream.setup(source, target, amount, source.owner_id)
          -> inherits unit_type from source (fallback: infantry)
  -> AudioManager SEND_TROOPS_SFX + EventBus.troops_sent(...)
```

`Structure.send_troops` floors the amount. With default 50%, a garrison of 2 sends 1; no order is made if the floored amount is below 1. The controller returns `true` only if a positive amount was sent. It plays error SFX for an invalid send or state guard failure.

The `send_fraction` is hardcoded as `0.5` in the current click/AI call sites. `Constants.DEFAULT_SEND_FRACTION` also equals 0.5 but is not used by those call sites.

## Stream Movement and Combat Resolve Flow

### Movement

On `TroopStream.setup`, the stream stores source/target/owner/amount and the source tower's `unit_type`, starts at source `global_position`, labels its amount, and renders `INF` / `ARC` / `CAV` with a unit-specific marker color while trail/glow retain owner color. Missing or invalid source type falls back to infantry. Invalid owner (including `neutral`) or non-positive amount logs an error and ends the stream in transit. In `_process(delta)` a surviving stream:

1. Emits `finished(INVALID_TARGET)` and removes itself if target is null.
2. Advances to target at exported `speed = 180.0` pixels/s with `move_toward`.
3. Rotates toward the target and applies a pulse scale.
4. If distance to current target position is <= 4 pixels, resolves combat, emits `arrived`, then `finished(ARRIVED)`, and queues itself for free.

### In-transit stream collision

`DetectionArea/CollisionShape2D` is a radius-8 circle matching the 16×16 Marker, not the trail. It uses collision layer and mask `2`, which only detects other streams and remains isolated from Structure ClickArea's default layer.

Both `Area2D` instances can emit `area_entered` in one physics frame. Only the stream with lower `instance_id` initiates arithmetic; `_resolving_collision` protects both participants during resolution and `_is_finished` makes repeat signals no-ops. Collision also requires the injected `BattleController.is_running()` guard to return true.

```text
Opposing DetectionArea overlap
  -> same owner: ignore; both continue
  -> different owner, larger amount: larger.amount -= smaller.amount
                                    -> refresh winner AmountLabel
                                    -> smaller.finished(DESTROYED_IN_TRANSIT)
  -> equal amount: both finished(DESTROYED_IN_TRANSIT)
```

The winner retains its original target and proceeds normally. A destroyed stream does not emit `arrived`, cannot call `target.resolve_combat`, and is removed from `World/TroopStreams`. BattleController listens to `finished` for both arrival and destruction, then defers the normal battle-state check. `unit_type` has no influence on stream collision arithmetic or target combat in this milestone.

### Combat / capture

```text
TroopStream reaches target
  -> target.resolve_combat(stream.owner_id, stream.amount)
     -> same owner: add amount up to max_garrison
     -> different owner, attack <= defence: subtract attack from garrison
     -> different owner, attack > defence: change owner and keep residual garrison
          -> Structure.owner_changed(structure, previous_owner, new_owner)
          -> capture pulse visual
     -> Structure._update_visuals()
          -> EventBus.structure_updated(id, rounded garrison)
  -> stream.arrived(stream)
  -> stream.finished(stream, ARRIVED)
  -> BattleController._on_troop_stream_finished()
       -> deferred _check_battle_state()
```

When owner flips, BattleController additionally:

1. plays capture SFX;
2. emits `EventBus.structure_captured(id, old_owner, new_owner)`;
3. clears selection if the now-captured Structure was selected and is no longer player-owned;
4. schedules a battle-state check.

Textures and owner glow are selected by `Structure.owner_id`: `player` -> green tower, `neutral` -> grey ruin, all other values -> red enemy tower. `owner` values starting with `enemy` are normalized to `enemy`; other unexpected values remain unchanged but are rendered as enemy by the default branch.

### Victory / defeat decision

`BattleController._process()` calls `_check_battle_state()` every frame unless state is already finished. The deferred callbacks above call it again after capture/arrival. Conditions are:

- **Victory:** no `owner_id == "enemy"` structures and no active stream whose owner is `enemy`.
- **Defeat:** no `owner_id == "player"` structures and no active stream whose owner is `player`.

Neutral structures do not prevent either condition. The active-stream guard avoids declaring a result while that side's final in-flight reinforcement/attack can still affect the board.

The `victory_conditions` / `defeat_conditions` data shape found in alternate level files and ObjectiveTracker is not used by current BattleController.

## Victory / Defeat Flow

### Victory

```text
BattleController._check_battle_state
  -> battle_state = VICTORY
  -> _apply_pause_state(true)
      -> get_tree().paused = true
      -> EventBus.pause_changed(true)
  -> Game.complete_level(level_id, level_data.rewards)
      -> SaveManager.mark_level_completed(level_id, unlock_levels, stars, coins, objectives)
      -> SaveManager.complete_level(...) -> savegame.json
      -> EventBus.battle_won(level_id, result)
  -> VictoryScreen._on_battle_won
      -> victory music, populate labels, visible = true
```

`Game.complete_level` uses `rewards.stars` default 3 and `rewards.coins_reward` default 100. It copies `Game.current_level_data.objectives` into result `completed_objectives`, without individual objective evaluation. `SaveManager.complete_level` retains the maximum star count, maintains the best positive time (currently passed as 0), adds coin reward every successful completion, and rewrites the save.

VictoryScreen is `PROCESS_MODE_WHEN_PAUSED`, so it remains interactive after the controller pauses the tree. Its actions are:

- **Next:** reads `level_index.json`, gets current entry's `next_level`, requires `SaveManager.is_level_unlocked(next)`, then `SceneLoader.goto_battle(next)`; otherwise returns to campaign.
- **Retry:** `SceneLoader.goto_battle(Game.selected_level_id)`.
- **Campaign:** `SceneLoader.goto_campaign()`.

### Defeat

```text
BattleController._check_battle_state
  -> battle_state = DEFEAT
  -> _apply_pause_state(true)
  -> Game.fail_level(level_id)
      -> EventBus.battle_lost(level_id, { tip })
  -> DefeatScreen._on_battle_lost
      -> defeat music, populate tip, visible = true
```

There is no save write on defeat. DefeatScreen also processes while paused and offers Retry/Campaign. It uses `SceneLoader`, which unpauses before changing scene.

## Pause Flow

```text
Esc / HUD Pause button
  -> BattleController.request_pause_toggle()
  -> battle_state RUNNING -> PAUSED
  -> _apply_pause_state(true)
      -> get_tree().paused = true
      -> EventBus.pause_changed(true)
  -> PauseMenu._on_pause_changed(true)
      -> visible only when controller.is_paused()

PauseMenu Resume
  -> BattleController.request_resume()
  -> battle_state PAUSED -> RUNNING
  -> _apply_pause_state(false) -> EventBus.pause_changed(false)
```

`PauseMenu` has `PROCESS_MODE_WHEN_PAUSED`; its nested SettingsScreen does too. It handles Restart and Campaign through controller methods, both of which clear tree pause before SceneLoader transitions. It does not show during victory/defeat because controller state is `VICTORY`/`DEFEAT`, not `PAUSED`, even though the tree is paused for the result screen.

## Edge Cases

| Case | Current behavior | Coverage / limitation |
| --- | --- | --- |
| Stream arrives after target changed owner | Arrival compares `stream.owner_id` with target's **current** `owner_id`; it reinforces if they now match, otherwise attacks. | Explicitly handled by `resolve_combat`; this is a sensible dynamic-state rule. |
| Opposing streams overlap | Marker-sized Area2D resolves the pair once while battle is running; larger remainder continues, equal amounts remove both. | Covered by focused headless arithmetic and physical Area2D smoke test. |
| Allied streams overlap | Same-owner pair is ignored. | They neither block nor merge. |
| Duplicate Area2D signals | Lower instance ID initiator plus resolving/finished flags makes repeated signal a no-op. | Covered by focused test. |
| Neutral stream created by bad data | Setup logs an error and ends stream in transit without reaching a target. | No neutral troop combat is allowed. |
| Several streams arrive at once | Godot processes nodes serially, so each arrival sees state produced by previous processed arrival; each schedules a deferred state check. | No explicit ordering policy or batch resolution. Exact same-frame order is scene-child processing order. |
| Victory while streams are moving | Victory waits for both no enemy structures and no enemy streams. If achieved, tree is paused; remaining friendly streams stop too. | Prevents an enemy stream from being ignored; result freezes any remaining friendly motion. |
| Defeat while streams are moving | Defeat waits for no player structures and no player streams. | Allows last player stream a chance to capture/reinforce before defeat. |
| Capture removes selected source | On `owner_changed`, if selected structure is no longer player-owned, controller clears selection. | Explicitly handled. |
| Player selects invalid target | Error SFX; enemy/neutral click clears selection, player click changes source. | Explicitly handled. |
| Source has too few troops | `can_send_to` requires garrison >= 2; send floors amount and refuses <1. | Explicitly handled. |
| Invalid/missing connection ID in data | LevelLoader pushes an error during validation; neighbor isn't resolved. | Battle can still load the remaining graph; loader does not fail whole level. |
| Invalid/missing level JSON | LevelLoader returns `{}` after push_error. | Controller still starts AI/frames with no structures; it can immediately resolve a result. No user-facing loading/error screen. |
| Owner changes and production cycles | Generation reads current owner in one per-frame accumulator; there are no Timers to duplicate. | Covered by `tests/StructureGenerationTest.tscn`. |
| Disabled or queued-for-removal Structure | `can_generate_units` returns false, and Godot does not normally process such nodes. | Covered by the native generation test. |
| Restart while paused | PauseMenu processes while paused; restart unpauses then changes BattleScene. | Explicitly handled. |
| Exit to campaign while paused | Same path through `request_exit_to_campaign`; unpauses before transition. | Explicitly handled. |
| Result buttons while paused | VictoryScreen/DefeatScreen use `PROCESS_MODE_WHEN_PAUSED`; SceneLoader unpauses before scene change. | Explicitly handled. |
| AI configuration in JSON | Root runtime level data has no active AI configuration consumption; nested `ai.think_interval` is ignored. | Not handled; AI always uses script defaults. |
| Objective/star evaluation | `objectives` are only displayed/copied as completed; current BattleController has no objective evaluator. | Not implemented. |

## Files to Read Before Changing Battle Code

1. `docs/PROJECT_MAP.md` — ownership, data source and project-wide risks.
2. `docs/DATA_MODEL.md` — actual vs intended level/balance contracts.
3. `scripts/battle/BattleController.gd` — state and event boundary.
4. The specific local owner: `Structure.gd`, `TroopStream.gd`, `EnemyAI.gd`, or `LevelLoader.gd`.
5. `scenes/battle/BattleScene.tscn` if changing composition or exported NodePaths.
6. `tests/TroopStreamCollisionTest.tscn` for any change to stream collision/terminal state.

Update this document whenever a battle transition, state condition, input rule, stream contract, scene-tree relation, or level field changes.
