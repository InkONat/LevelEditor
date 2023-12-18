@tool

## Tab used to select tiles from the Level window.
class_name TileTab extends TabBar

## Array of tiles for this tile tab. The icons only appear in game and not in the editor.
@export var tiles : Array[Tile]

## Reference tileset for the normal tiles.
@export var reference_tileset : TileSet

func _ready() -> void:
	if not Engine.is_editor_hint():
		
		var grid : GridContainer = GridContainer.new()
		
		add_child(grid)
		
		for tile in tiles:
			
			if not is_instance_valid(tile):
				continue
			
			else:
				add_tile_icon(tile, grid)

## Adds a tile icon to the tree with [param tile] data as child of [param grid]. Not meant to be used outside of automatically adding/removing tile icons from this TileTab
func add_tile_icon(tile: Tile, grid: GridContainer) -> void:
	var icon : TileIcon = TileIcon.new()
	
	icon.tile = tile
	icon.reference_tileset = reference_tileset
	
	grid.add_child(icon)


func _to_string() -> String:
	return str("TileTab:<TileTab#", get_instance_id(), ">")
