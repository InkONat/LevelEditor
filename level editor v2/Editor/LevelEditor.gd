extends Node2D

signal mouse_released

var initial_rect_or_line_pos : Vector2 = Vector2(0, 0)

var first_press : bool = false:
	set(value):
		
		first_press = value
		
		if value:
			await get_tree().process_frame
			first_press = false

var mouse_held : bool = false:
	set(value):
		
		if value:
			
			if Editor.paint_mode != Editor.PaintMode.PAINT_MODE_ECHOLESS:
				can_echo_paint = true
			
			else:
				var pos : Vector2 = to_global(tilemap.local_to_map(get_local_mouse_position()))
				
				var is_null : bool = not is_instance_valid(Editor.tile)
				_tile_drawing_attempt(
					is_null,
					Editor.layer,
					Editor.tile.special if not is_null else false,
					Editor.tile.atlas_coords if not is_null else Vector2i(0, 0),
					Editor.tile.scene_id if not is_null else 0,
					Editor.tile.source_id if not is_null else 0,
					pos
				)
			
			
		else:
			mouse_released.emit()
			can_echo_paint = false
		
		mouse_held = value

var can_echo_paint : bool = false

@onready var tilemap : TileMap = $TileMapFromEditor
@onready var edit_window : Control = $UI/EditTileWindow

func _ready() -> void:
	for layer_num in range(1000 + 1):
		tilemap.add_layer(layer_num)
		tilemap.set_layer_z_index(layer_num, layer_num)
	
	save_tilemap_data()
	

func _process(_delta: float) -> void:
	
	if can_echo_paint:
		
		var pos : Vector2 = to_global(tilemap.local_to_map(get_local_mouse_position()))
		
		var is_null : bool = not is_instance_valid(Editor.tile)
		_tile_drawing_attempt(
			is_null,
			Editor.layer,
			Editor.tile.special if not is_null else false,
			Editor.tile.atlas_coords if not is_null else Vector2i(0, 0),
			Editor.tile.scene_id if not is_null else 0,
			Editor.tile.source_id if not is_null else 0,
			pos
		)
	
	var info : Label = $UI/Info/Label
	
	info.text = str(
		"Layer: ", Editor.layer, "\n",
		"Global mouse position: ", get_global_mouse_position(), "\n",
		"Mouse position on grid: ", to_global(tilemap.local_to_map(get_local_mouse_position()))
	)

func _on_editor_canvas_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton: return
	
	if not event.pressed:
		mouse_held = false
		first_press = false
	
	if event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		first_press = true
		
		mouse_held = event.pressed
		


func _input(event: InputEvent) -> void:
	
	if event is InputEventKey:
		
		if event.is_released(): return
		
		if event.key_label == KEY_R:
			print(save_tilemap_data().data)
		
		# adding/subtracting 1 from the layer depending on if you pressed up or down
		if event.key_label == KEY_UP:
			
			Editor.layer = min(Editor.layer + 1, 1000 + 1)
		
		elif event.key_label == KEY_DOWN:
			
			Editor.layer = max(Editor.layer - 1, 0)
		
		# changes the modulate to Color.DIM_GRAY of all the other tiles
		for i: int in (range(Editor.layer) + range(Editor.layer + 1, 1000 + 1)):
		
			if i != Editor.layer:
				
				tilemap.set_layer_modulate(i, Color.DIM_GRAY)
		
		tilemap.set_layer_modulate(Editor.layer, Color.WHITE)


# handles both editing and painting
func _tile_drawing_attempt(tile_is_null : bool, layer : int, special : bool, atlas_coords : Vector2i, scene_id : int, source_id : int, pos : Vector2i) -> void:
	
	if not Editor.edit_mode:
		
		if tile_is_null: return
		
		match Editor.paint_mode:
			
			# will run at process
			Editor.PaintMode.PAINT_MODE_RECT:
				
				if first_press:
					initial_rect_or_line_pos = pos
			
			# will run at process
			Editor.PaintMode.PAINT_MODE_LINE:
				
				pass
			
			# echoing stuff is handled in the set function of the mouse being held bool
			# so it only runs once
			Editor.PaintMode.PAINT_MODE_ECHOLESS, Editor.PaintMode.PAINT_MODE_NORMAL:
				
				tilemap.set_cell(
					layer,
					pos,
					source_id,
					atlas_coords if not special else Vector2i(0, 0),
					0 if not special else scene_id
				)
			
			Editor.PaintMode.PAINT_MODE_ERASER:
				
				tilemap.erase_cell(
					layer,
					pos
				)
	
	# for editor, special tiles will be much harder to change since they will need to become a new scene
	elif first_press:
		
		print("what happened")
		
		var new_special_tile_scene : PackedScene = null
		
		print("fnucking")
		
		var tile : Variant = \
			tilemap.get_cell_tile_data(layer, pos) \
			if tilemap.tile_set.get_source(source_id) is TileSetAtlasSource \
			else null # TODO special tile edit
		
		print("fucking")
		
		if tile is TileData:
			
			var properties : Array[Dictionary] = ClassDB.class_get_property_list("TileData")
			
			edit_window.enter(layer, properties, tile, tilemap)


func save_tilemap_data() -> LevelData:
	
	var data : LevelData = LevelData.new()
	
	for layer in tilemap.get_layers_count():
		
		if tilemap.get_used_cells(layer).is_empty():
			continue
		
		for canvas_pos in tilemap.get_used_cells(layer):
			
			var alt_tile : int = tilemap.get_cell_alternative_tile(layer, canvas_pos)
			var properties : Array[Dictionary] = []
			var source : int = tilemap.get_cell_source_id(layer, canvas_pos)
			
			if alt_tile != 0:
				
				var scene : Node = tilemap.tile_set.get_source(source).get_scene_tile_scene(alt_tile).instantiate()
				
				if is_instance_valid(scene.get_script()):
					properties = scene.get_script().get_script_property_list()
			
			# see LevelData's data documentation
			@warning_ignore("incompatible_ternary")
			data.data.append({
				"layer": layer,
				"tile": [
					tilemap.get_cell_atlas_coords(layer, canvas_pos) if alt_tile == 0 else alt_tile,
					source
				],
				"pos": canvas_pos,
				"properties": properties
			})
	
	return data
