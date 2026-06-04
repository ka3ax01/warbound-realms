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

## First Run

### 1. Install Godot

Install `Godot 4.6.x` from the official website:

- https://godotengine.org/download

Use the standard editor build for your OS.

### 2. Get The Project

Clone the repository and open the project folder locally.

Example:

```bash
git clone <your-repo-url>
cd warbound-realms
```

### 3. Open The Project In Godot

1. Launch Godot.
2. Click `Import`.
3. Select the project folder.
4. Open `project.godot`.
5. Confirm the import.

On first open, Godot will generate its local `.godot/` import cache automatically.

### 4. Run The Game

1. Open the imported project in Godot.
2. Press `F5`, or click `Run Project`.
3. The game starts from the default scene configured in `project.godot`.

### 5. Start A Battle

1. In `MainMenu`, start the campaign.
2. Choose a level on the campaign map.
3. Open the level info popup.
4. Start the battle.

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

- `data/levels/campaign_01/level_001.json`
- `data/levels/campaign_01/level_002.json`
- `data/levels/campaign_01/level_003.json`

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
