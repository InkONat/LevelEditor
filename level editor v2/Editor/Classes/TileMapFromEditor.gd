## Class that implements [method TileMap._use_tile_data_runtime_update] so non special tiles can be edited and the edited properties are saved. [i]Only use this tilemap if you want to use levels made by the Level Editor. You can use the normal TileMap but edited tiles will [b]not[/b] work.[/i]
class_name TileMapFromEditor extends TileMap


func _use_tile_data_runtime_update(layer: int, coords: Vector2i) -> bool:
	var data : TileData = get_cell_tile_data(layer, coords)
	return data != null
