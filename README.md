# Warbound Realms

`Warbound Realms` is a 2D/2.5D tower-conquest RTS prototype built with `Godot 4.x` and `GDScript`.

The core loop is simple:
- each tower generates units over time
- the player selects a friendly tower
- the player sends part of its garrison to a connected tower
- friendly targets are reinforced
- neutral or enemy targets are attacked and can be captured

The repository currently contains the foundation for:
- main menu and campaign flow
- JSON-driven battle levels
- core tower capture gameplay
- simple enemy AI
- pause, victory, defeat, settings, and save scaffolding
- placeholder-to-prototype visual integration using Kenney assets

## Tech Stack

- `Godot 4.6.x`
- `GDScript`
- data-driven level setup via `JSON`

## Project Structure

```text
res://
├── assets/      # art, audio, fonts
├── data/        # levels, factions, localization, config
├── globals/     # autoload singletons
├── scenes/      # game scenes and UI
├── scripts/     # gameplay, UI, data, utils
└── resources/   # optional .tres/.res configs
```

## Current Gameplay Scope

- `MainMenu -> CampaignMap -> LevelInfoPopup -> BattleScene`
- player can select a tower and send units to connected towers
- towers can be captured
- simple enemy AI attacks on a timer
- battle can end in victory or defeat

## Running The Project

1. Open the project in `Godot 4.6.x`.
2. Run the default scene from `project.godot`.
3. Start the campaign and enter a battle.

Controls in battle:
- `LMB`: select tower / send troops
- `RMB`: clear selection
- `Esc`: toggle pause

## Data

Levels are defined in:

- [data/levels/campaign_01/level_001.json](/Users/rabbanimukhanbediya/dev/DRT/warbound-realms/data/levels/campaign_01/level_001.json:1)
- [data/levels/campaign_01/level_002.json](/Users/rabbanimukhanbediya/dev/DRT/warbound-realms/data/levels/campaign_01/level_002.json:1)
- [data/levels/campaign_01/level_003.json](/Users/rabbanimukhanbediya/dev/DRT/warbound-realms/data/levels/campaign_01/level_003.json:1)

They define:
- tower positions
- ownership
- initial garrison
- production rate
- neighbor connections
- AI config
- rewards / unlocks

## Status

This is an MVP-oriented prototype foundation, not a finished production game.

Major areas still expected to evolve:
- troop movement presentation
- richer map composition
- campaign progression
- balance
- UI polish
- content pipeline
