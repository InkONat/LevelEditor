## Editor class with static properties and functions to make the editor work
class_name Editor extends Node

## Current selected tile
static var tile : Tile = null

## Current layer
static var layer : int = 0

## Paint mode, check [enum PaintMode]
static var paint_mode : int = PaintMode.PAINT_MODE_ECHOLESS

## If true, when clicking a tile an edit tab will open up. You will be able to edit special tiles's properties, and for normal tiles their modulate, custom data and layer.
static var edit_mode : bool = false

## If true, the user is currently editing a tile.
static var editing_tile : bool = false

enum PaintMode {
	PAINT_MODE_RECT, ## Will create tiles inside a rectangle defined by your mouse
	PAINT_MODE_LINE, ## Will create tiles in a line (that doesn't have to be straight)
	PAINT_MODE_ECHOLESS, ## Will create tiles normally, but won't be able to hold to paint tiles
	PAINT_MODE_NORMAL, ## Will create tiles normally
	PAINT_MODE_ERASER, ## Will erase clicked tiles
	PAINT_MODE_FILL, ## Will fill same tiles with the selected tile
}

## Creates a new tilemap, adding it to the node [param to] (if [param custom_tilemap] is null, else it will use that tilemap) and sets it's tiles based on [param level_data].
static func compile_level_data(level_data: LevelData, to: Node, custom_tilemap: TileMap) -> LevelData:
	
	var tilemap : TileMap = TileMap.new()
	
	if not is_instance_valid(custom_tilemap):
		
		to.add_child(tilemap)
	
	for dict in level_data.data:
		
		tilemap.set_cell(
			dict["layer"],
			dict["pos"],
			dict["tile"][1],
			dict["tile"][0] if dict["tile"][0] is Vector2i else Vector2i(0, 0),
			dict["tile"][0] if dict["tile"][0] is int else 0
		)
	
	return level_data
	
