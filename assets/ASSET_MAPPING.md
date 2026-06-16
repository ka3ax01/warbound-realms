# Warbound Realms Asset Mapping

## Integrated Assets

- `player tower`: `res://assets/art/towers/player/kenney_td_player_tower_green_01.png`
- `enemy tower`: `res://assets/art/towers/enemy/kenney_td_enemy_tower_red_01.png`
- `neutral tower`: `res://assets/art/towers/neutral/kenney_td_neutral_ruin_grey_01.png`
- `selected player tower overlay`: `res://assets/ui/frames/selection_ring.svg`
- `ground tile`: `res://assets/art/tiles/ground/grass_tile_01.svg`
- `path shadow/base`: `res://assets/art/tiles/ground/dirt_tile_01.svg`
- `road tile`: `res://assets/art/tiles/roads/road_tile_01.svg`
- `decor tree`: `res://assets/art/decor/trees/trees_4.png`
- `decor rock`: `res://assets/art/decor/rocks/rocks_4.png`
- `UI panel`: `res://assets/ui/panels/panel_fantasy_01.svg`
- `UI button`: `res://assets/ui/buttons/button_primary.svg`
- `main menu icon`: `res://assets/ui/icons/structure_tower.png`
- `victory icon`: `res://assets/ui/icons/trophy_white_2x.png`
- `defeat icon`: `res://assets/ui/icons/defeat_shield_source_128.png`
- `menu music`: `res://assets/audio/music/Menu.mp3`
- `battle music`: `res://assets/audio/music/Battle.mp3`
- `victory music`: `res://assets/audio/music/victory.mp3`
- `defeat music`: `res://assets/audio/music/defeat.mp3`
- `button click SFX`: `res://assets/audio/sfx/ui/button_soft_01.ogg`
- `tower select SFX`: `res://assets/audio/sfx/battle/tower_selected_01.ogg`
- `send troops SFX`: `res://assets/audio/sfx/battle/troops_sent_01.ogg`
- `capture SFX`: `res://assets/audio/sfx/capture/tower_capture_01.ogg`
- `upgrade placeholder SFX`: `res://assets/audio/sfx/ui/upgrade_01.ogg`
- `error action SFX`: `res://assets/audio/sfx/ui/error_locked_01.ogg`

## Scene Usage

- `res://scenes/world/Structure.tscn`: player/enemy/neutral tower visuals and selected overlay
- `res://scenes/battle/BattleScene.tscn`: battle music via `BattleScene.gd`
- `res://scripts/battle/BattleBackground.gd`: ground, road, tree, rock assets
- `res://scenes/battle/HUD.tscn`: panel/button assets
- `res://scenes/battle/PauseMenu.tscn`: panel/button assets
- `res://scenes/battle/VictoryScreen.tscn`: panel/button/victory icon
- `res://scenes/battle/DefeatScreen.tscn`: panel/button/defeat icon
- `res://scenes/menu/MainMenu.tscn`: panel/button/main menu icon
- `res://scripts/ui/MainMenu.gd`: menu music
- `res://scripts/ui/CampaignMap.gd`: menu music and button SFX

## Fonts

- No font binaries were included in the archive.
- Source notes were copied to `res://assets/fonts/FONT_SOURCES.md` and `res://assets/fonts/FONT_USAGE.md`.

## TODO

- Add actual font binaries under `res://assets/fonts/` and wire them into a shared `Theme` resource.
- Replace the reused `upgrade_01.ogg` placeholder if a dedicated upgrade SFX is later provided.
- Expand decorative set for battle maps if per-level biome variation is needed.
