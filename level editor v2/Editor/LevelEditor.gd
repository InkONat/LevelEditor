extends Node2D

signal mouse_released

# a lot of these variables are for the rect paint mode

# wait 1 frame to set it
var previous_rect_state : Rect2i:
	set(value):
		await get_tree().process_frame
		previous_rect_state = value

# used for the rect and line paint mode, when you click the canvas
# with one of those modes, this var will be set to the position of the click on the grid
var initial_rect_or_line_pos : Vector2i = Vector2i(0, 0)

var current_rect : Rect2i
var past_rect_mouse_pos : Vector2i
var past_rect_mouse_pos_pass : int = 0

var rect_mouse_pos : Vector2i:
	set(value):
		if value == rect_mouse_pos:
			mouse_diff_dir = Vector2i.ZERO
			return
		
		else:
			
			mouse_diff_dir = Vector2i(
				signi(absi(value.x) - absi(rect_mouse_pos.x)),
				signi(absi(value.y) - absi(rect_mouse_pos.y))
			)
			
			rect_mouse_pos = value
			
			if rect_mouse_pos != past_rect_mouse_pos:
				
				past_rect_mouse_pos_pass += 1
			
			if past_rect_mouse_pos_pass >= 2:
				
				past_rect_mouse_pos = rect_mouse_pos
				past_rect_mouse_pos_pass = 0

var mouse_diff_dir : Vector2i

var first_press : bool = false

var mouse_held : bool = false:
	set(value):
		
		if value:
			
			if Editor.paint_mode != Editor.PaintMode.PAINT_MODE_ECHOLESS:
				can_echo_paint = true
			
			else:
				var pos : Vector2 = (tilemap.local_to_map(get_local_mouse_position()))
				
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

# my implementation of undo and redo
# UndoRedo is fucked up
# i will be using htis instead

# format:
# {
# "action_name" : <optional name for the action>
# "method_name" : <name of the method as a String>
# "params" : <array of parameters>
# "undo_method" : <name of the undo method>
# "Undo_params" : <array of parameters>
# }
var undoredo_history : Array[Dictionary]
var last_undone_action : Dictionary

func _ready() -> void:
	for layer_num in range(1000 + 1):
		tilemap.add_layer(layer_num)
		tilemap.set_layer_z_index(layer_num, layer_num)
	
	save_tilemap_data()
	

func _process(_delta: float) -> void:
	
	if can_echo_paint:
		
		var pos : Vector2 = (tilemap.local_to_map(get_local_mouse_position()))
		
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
		"Mouse position on grid: ", (tilemap.local_to_map(get_local_mouse_position()))
	)

func _on_editor_canvas_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton: return
	
	if not event.pressed:
		mouse_held = false
		previous_rect_state = Rect2i(0, 0, 0, 0)
	
	if event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		
		mouse_held = event.pressed
		first_press = true # set to false on the tile drawing attempt func
		


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
	
	# handling first press here so it will be in the state i want for this function
	
	rect_mouse_pos = pos
	
	if not Editor.edit_mode:
		
		if tile_is_null: return
		
		match Editor.paint_mode:
			
			
			
			# will run at process
			Editor.PaintMode.PAINT_MODE_RECT:
				
				if first_press:
					initial_rect_or_line_pos = pos
				
				var rect : Rect2i = Rect2i(initial_rect_or_line_pos, rect_mouse_pos).abs()
				previous_rect_state = rect # the previous_rect_state set func awaits a frame to set it, so this should work
				
				# some math stuff
				var rect_x_len : int = absi(rect.size.x - rect.position.x)
				var rect_y_len : int = absi(rect.size.y - rect.position.y)
				
				var x : int
				while x < rect_x_len:
					
					# directly next to the initial pos
					set_cell(
						layer,
						Vector2i(initial_rect_or_line_pos.x + x, initial_rect_or_line_pos.y),
						source_id,
						atlas_coords if not special else Vector2i(0, 0),
						0 if not special else scene_id
					)
					
					# parallel side
					set_cell(
						layer,
						Vector2i(initial_rect_or_line_pos.x + x, initial_rect_or_line_pos.y + rect_y_len),
						source_id,
						atlas_coords if not special else Vector2i(0, 0),
						0 if not special else scene_id
					)
					
					x += 1
				
				
				var y : int
				
				while y < rect_y_len:
					
					# right next to the initial pos
					set_cell(
						layer,
						Vector2i(initial_rect_or_line_pos.x, initial_rect_or_line_pos.y + y),
						source_id,
						atlas_coords if not special else Vector2i(0, 0),
						0 if not special else scene_id
					)
					
					# parallel side
					set_cell(
						layer,
						Vector2i(initial_rect_or_line_pos.x + rect_x_len, initial_rect_or_line_pos.y + y),
						source_id,
						atlas_coords if not special else Vector2i(0, 0),
						0 if not special else scene_id
					)
					
					y += 1
				
				# now we will be deleting previous rects
				# i dont know how to fix but this will 100% delete unrelated tiles
				# TODO: make that not happen
				
				if mouse_diff_dir != Vector2i.ZERO and previous_rect_state != Rect2i(0, 0, 0, 0):
					
					var prev_rect_x_len : int = absi(previous_rect_state.size.x - previous_rect_state.position.x)
					var prev_rect_y_len : int = absi(previous_rect_state.size.y - previous_rect_state.position.y)
					
					var prev_x : int
					while prev_x < prev_rect_x_len:
						
						erase_cell(
							layer,
							Vector2i(prev_x + initial_rect_or_line_pos.x,
								initial_rect_or_line_pos.y)
						)
						
						erase_cell(
							layer,
							Vector2i(prev_x + initial_rect_or_line_pos.x,
								initial_rect_or_line_pos.y + prev_rect_y_len)
						)
						
						prev_x += 1
					
					var prev_y : int
					while prev_y < prev_rect_y_len:
						
						erase_cell(
							layer,
							Vector2i(initial_rect_or_line_pos.x,
								prev_y + initial_rect_or_line_pos.y)
						)
						
						erase_cell(
							layer,
							Vector2i(initial_rect_or_line_pos.x + prev_rect_x_len,
								prev_y + initial_rect_or_line_pos.y)
						)
						
						prev_y += 1
					
					# setting the tile at the corner
					set_cell(
						layer,
						Vector2i(initial_rect_or_line_pos.x + rect_x_len,
							initial_rect_or_line_pos.y + rect_y_len),
						source_id,
						atlas_coords if not special else Vector2i(0, 0),
						0 if not special else scene_id
					)
					
					# erasing the prev tile at the corner
					erase_cell(
						layer,
						Vector2i(initial_rect_or_line_pos.x + prev_rect_x_len,
							initial_rect_or_line_pos.y + prev_rect_y_len)
					)
				
				current_rect = rect
			
			
			
			
			
			# will run at process
			Editor.PaintMode.PAINT_MODE_LINE:
				
				pass
			
			
			
			
			
			Editor.PaintMode.PAINT_MODE_FILL:
				
				# tiles left to be added to paint_needed_on_tiles
				var tiles_left : Array[Vector2i]
				var paint_needed_on_tiles : Array[Vector2i]
				
				paint_needed_on_tiles.append(pos)
				
				# tiles left to append to the paint needed on tiles array
				# obviously, wherever you clicked will need to be painted
				var tiles_left_to_append : Array[Vector2i] = [pos]
				
				# the tile identifier (atlas coords or alt tile/scene id) of the tile you clicked.
				# this will be used to determine if a tile will be painted with the tile
				# you have selected
				var ref_paint_tile : Variant  = \
					atlas_coords if not special \
					else scene_id
				
				while tiles_left_to_append.size() > 0:
					
					# cap to how many tiles can be filled so if you for example fill the entire canvas
					# on accident, this will stop that from happening
					if paint_needed_on_tiles.size() >= 400:
						paint_needed_on_tiles = [] # so basically cancelling the whole thing
						break
					
					var surrounding_cells : Array[Vector2i] = tilemap.get_surrounding_cells(tiles_left_to_append[0])
					
					# we will do the same iteration later, theres probably a
					# more elegant way of doing this
					for neighbor_cell in surrounding_cells:
						
						if neighbor_cell in tiles_left_to_append:
							
							surrounding_cells.erase(neighbor_cell)
					
					tiles_left_to_append.append_array(surrounding_cells)
					
					for neighbor_cell in surrounding_cells:
						
						var cell : Variant = \
							tilemap.get_cell_atlas_coords(layer, neighbor_cell) \
							if tilemap.get_cell_alternative_tile(layer, neighbor_cell) == 0 \
							else tilemap.get_cell_atlas_coords(layer, neighbor_cell)
						
						if cell == ref_paint_tile:
							
							tiles_left_to_append.erase(neighbor_cell)
							paint_needed_on_tiles.append(neighbor_cell)
						
					
					
					
					
				print(tiles_left_to_append)
			
			
			
			
			# echoing stuff is handled in the set function of the mouse being held bool
			# so it only runs once
			Editor.PaintMode.PAINT_MODE_ECHOLESS, Editor.PaintMode.PAINT_MODE_NORMAL:
				
				set_cell(
					layer,
					pos,
					source_id,
					atlas_coords if not special else Vector2i(0, 0),
					0 if not special else scene_id
				)
			
			
			
			
			
			Editor.PaintMode.PAINT_MODE_ERASER:
				
				erase_cell(
					layer,
					pos
				)
	
	# TODO editor unfortunately not implemented just yet
	#if first_press and Editor.edit_mode:
		#
		#var new_special_tile_scene : PackedScene = null
		#
		#var tile : Variant = \
			#tilemap.get_cell_tile_data(layer, pos) \
			#if tilemap.tile_set.get_source(source_id) is TileSetAtlasSource \
			#else null # special tile edit soon i am guessing
		#
		#if tile is TileData:
			#
			#var properties : Array[Dictionary] = ClassDB.class_get_property_list("TileData")
			#
			#edit_window.enter(layer, properties, tile, tilemap)
	
	
	if first_press:
		first_press = false

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


func set_cell(layer : int, coords : Vector2i, source_id : int, atlas_coords : Vector2i, alt_tile : int) -> void:
	undoredo_history.append({
		"action_name": "Set Cell",
		"method_name": "set_cell",
		"params": [layer, coords, source_id, atlas_coords, alt_tile],
		"undo_method": "erase_cell",
		"undo_params": [layer, coords]
	})
	
	tilemap.set_cell(layer, coords, source_id, atlas_coords, alt_tile)


func erase_cell(layer : int, coords : Vector2i) -> void:
	undoredo_history.append({
		"action_name": "Erase Cell",
		"method_name": "set_cell",
		"params": [layer, coords],
		"undo_method": "erase_cell",
		"undo_params": [
			layer,
			coords,
			tilemap.get_cell_source_id(layer, coords),
			tilemap.get_cell_atlas_coords(layer, coords),
			tilemap.get_cell_alternative_tile(layer, coords)
		]
	})
	
	tilemap.erase_cell(layer, coords)


func undo_redo(undo : bool) -> void:
	
	if undo:
		
		var action : Dictionary = undoredo_history[0]
		
		callv(action["undo_method"], action["undo_params"])
		
		last_undone_action = action
		
	
	else:
		
		if last_undone_action == {}: return
		
		callv(last_undone_action["method_name"], last_undone_action["params"])
		
		undoredo_history.append(last_undone_action)
		
		last_undone_action = {}
