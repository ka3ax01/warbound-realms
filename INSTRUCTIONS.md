# Developer Instructions

This document describes the current development rules and architectural intent for `Warbound Realms`.

## Goals

The project is targeting an indie-friendly MVP:
- simple architecture
- data-driven levels
- clear ownership of gameplay systems
- minimal overengineering

Prefer pragmatic solutions over abstract patterns.

## Engine

- `Godot 4.6.x`
- `GDScript`

Do not introduce C# or plugins unless there is a clear project need.

## Core Architecture

### Autoloads

- `Game.gd`
  high-level game state and level/session flow
- `SaveManager.gd`
  persistence for progress and settings
- `AudioManager.gd`
  music and SFX control
- `SceneLoader.gd`
  scene transitions
- `EventBus.gd`
  global signals for gameplay/UI coordination
- `LocalizationManager.gd`
  locale switching

### Battle Runtime

- `BattleController`
  main coordinator for a match
- `LevelLoader`
  builds the battle scene from JSON
- `Structure`
  tower gameplay state and input surface
- `TroopStream`
  moving troop entity
- `EnemyAI`
  simple CPU decision-maker
- `ObjectiveTracker`
  win/lose checks

Keep these responsibilities separated. Avoid moving global progression or UI logic into `Structure` or `TroopStream`.

## Data Rules

### JSON

Use JSON for:
- level definitions
- campaign indexing
- faction catalog data
- commander catalog data

### Resources

Use `.tres` / `.res` for:
- balancing presets
- AI tuning presets
- theme/style configs

If data needs heavy designer iteration inside the editor, consider migrating that specific slice from JSON to `Resource`.

## Scene Rules

### Scenes

- `scenes/menu/`
  main menu, campaign, popups, settings
- `scenes/battle/`
  battle root and battle UI
- `scenes/world/`
  tower, troop stream, world visuals
- `scenes/common/`
  reusable shared scenes

### Scene Ownership

- `BattleScene` owns the battle runtime composition
- `Structure.tscn` should remain reusable and instanceable from data
- UI should subscribe through `EventBus` when possible instead of reaching into gameplay nodes arbitrarily

## Coding Conventions

- Prefer typed GDScript where practical
- Keep methods short and specific
- Use explicit names over clever names
- Avoid deep inheritance trees
- Avoid service/factory patterns unless a concrete problem appears

When adding gameplay logic:
- first ask which node/class truly owns the behavior
- keep local state local
- emit events upward instead of introducing circular dependencies

## Content Workflow

### Levels

Add or edit levels in:
- `data/levels/campaign_01/`
- `data/levels/level_index.json`

Each structure entry should include:
- `id`
- `position`
- `owner`
- `type`
- `garrison`
- `max_garrison`
- `production_rate`
- `neighbors`

### Art

Current art is organized in:
- `assets/art/structures/`
- `assets/art/backgrounds/`
- `assets/art/details/`

When replacing prototype art:
- preserve stable asset paths where possible
- update scripts only if the asset contract changes

## Input / UX

Current battle controls:
- `LMB`: select / send
- `RMB`: clear selection
- `Esc`: pause

If input changes, update both:
- the actual gameplay scripts
- visible HUD hints

## Testing Checklist

Before merging gameplay changes, verify:
- project opens without parser errors
- entering a battle works
- selecting a player tower works
- sending troops works
- pause/resume works
- exit from pause works
- victory/defeat screens still respond

Recommended validation:

```bash
'/Users/rabbanimukhanbediya/Downloads/Godot.app/Contents/MacOS/Godot' --headless --path /Users/rabbanimukhanbediya/dev/DRT/warbound-realms --quit
```

This checks scene/script loading, but it does not replace manual gameplay testing.

## Near-Term Priorities

Recommended next improvements:
- troop visual polish and route readability
- drag-to-send UX
- better campaign map presentation
- stronger AI heuristics
- content authoring workflow for more levels
