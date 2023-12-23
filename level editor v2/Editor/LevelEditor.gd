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
		
		if not value:
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

# we really need structs in gdscript like I BEG PLEASE I HATE USING DICTIONARIES FOR THIS SHIT PLEASE JUAN

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
	
	print(undoredo_history, "\n")


# NOTICE: handles rect painting too
func _on_editor_canvas_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton: return
	
	if not event.pressed:
		
		if current_rect != Rect2i(0, 0, 0, 0):
			set_tile_rect(current_rect, Editor.layer, Editor.tile.source_id, Editor.tile.atlas_coords, Editor.tile.special, Editor.tile.scene_id)
		
		mouse_held = false
		previous_rect_state = Rect2i(0, 0, 0, 0)
		current_rect = Rect2i(0, 0, 0, 0)
	
	if event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		
		if Editor.paint_mode != Editor.PaintMode.PAINT_MODE_ECHOLESS or Editor.paint_mode != Editor.PaintMode.PAINT_MODE_FILL and not event.is_released():
			can_echo_paint = true
			
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
		
		# undo
		if event.ctrl_pressed and event.key_label == KEY_Z:
			print(undoredo_history[0]["action_name"])
			undo_redo(true)

# NOTICE: handles both editing and painting
# TODO:
# 1 - PENDING_FEATURE: edit mode implementation
func _tile_drawing_attempt(tile_is_null : bool, layer : int, special : bool, atlas_coords : Vector2i, scene_id : int, source_id : int, pos : Vector2i) -> void:
	
	# handling first press here so it will be in the state i want for this function
	
	rect_mouse_pos = pos
	
	if not Editor.edit_mode:
		
		if tile_is_null: return
		
		match Editor.paint_mode:
			
			
			
			# will run at process
			# the actual rect setting shit is done on the canvas gui input and
			# on the set_tile_rect() func
			Editor.PaintMode.PAINT_MODE_RECT:
				
				if first_press:
					initial_rect_or_line_pos = pos
				
				var rect : Rect2i = Rect2i(initial_rect_or_line_pos, rect_mouse_pos).abs()
				current_rect = rect
			
			
			
			
			
			# will run at process
			Editor.PaintMode.PAINT_MODE_LINE:
				
				pass
			
			
			
			
			
			# ran at the set function of the mouse beinhg held bool so it only runs once
			Editor.PaintMode.PAINT_MODE_FILL:
				
				fill_with_tile(layer, pos, source_id, atlas_coords, scene_id)
			
			
			
			
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
	
	# FUTURE CODE, IGNORE
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


# UNTESTED
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


func set_cell(layer : int, coords : Vector2i, source_id : int, atlas_coords : Vector2i, alt_tile : int, undone : bool = false) -> void:
	
	if tilemap.get_cell_source_id(layer, coords) == source_id \
		and \
		tilemap.get_cell_alternative_tile(layer, coords) == alt_tile \
		and \
		tilemap.get_cell_atlas_coords(layer, coords) == atlas_coords:
			
			return
	
	if not undone:
		undoredo_history.push_front({
			"action_name": "Set Cell",
			"method_name": "set_cell",
			"params": [layer, coords, source_id, atlas_coords, alt_tile],
			"undo_method": "erase_cell",
			"undo_params": [layer, coords, true]
		})
	
	tilemap.set_cell(layer, coords, source_id, atlas_coords, alt_tile)


# TODO:
# 1 - REFACTOR_NEEDED: set_recursive doesnt work
func fill_with_tile(layer : int, init_pos : Vector2i, source_id : int, atlas_coords : Vector2i, alt_tile : int, undone : bool = false) -> void:
	
	if not undone:
		#undoredo
		undoredo_history.push_front({
			"action_name": "Fill Area",
			"method_name": "fill_with_tile",
			"params": [layer, init_pos, source_id, atlas_coords, alt_tile],
			"undo_method": "fill_with_tile",
			"undo_params": [
				layer,
				init_pos,
				tilemap.get_cell_source_id(layer, init_pos),
				tilemap.get_cell_atlas_coords(layer, init_pos),
				tilemap.get_cell_alternative_tile(layer, init_pos),
				true
			],
		})
	
	var ref_tile : Tile = Tile.new()
	
	ref_tile.atlas_coords = tilemap.get_cell_atlas_coords(layer, init_pos)
	ref_tile.scene_id = tilemap.get_cell_alternative_tile(layer, init_pos)
	ref_tile.source_id = tilemap.get_cell_source_id(layer, init_pos)
	
	set_recursive(layer, init_pos, Editor.tile, ref_tile)
	


# TODO:
# 1 - CRITICAL: doesnt even work lmao
func set_recursive(layer : int, at : Vector2i, tile: Tile, ref_tile : Tile) -> void:
	
	if not ( \
		tilemap.get_cell_atlas_coords(layer, at) == ref_tile.atlas_coords \
		and \
		tilemap.get_cell_alternative_tile(layer, at) == ref_tile.scene_id \
		and \
		tilemap.get_cell_source_id(layer, at) == ref_tile.source_id ):
			
			return
	
	tilemap.set_cell(layer, at, tile.source_id, tile.atlas_coords, tile.scene_id)
	
	for neighbor in tilemap.get_surrounding_cells(at):
		tilemap.set_cell(layer, neighbor, tile.source_id, tile.atlas_coords, tile.scene_id)
		set_recursive(layer, neighbor, tile, ref_tile)


# TODO:
# 1 - BUG: when setting a rect without being from a point to a point with bigger x and y,
#          the rect isnt set correctly (LIKELY because of Rect2 (and Rect2i) not accepting
#          negative values for the size
# 2 - REFACTOR_NEEDED: undoredo will erase the tiles that were on the rect before,
#                      so these are not preserved (so the undo doesnt work correctly)
#                      CAUSE: the way undoredo is set for this function (lines 394-409)
func set_tile_rect(rect : Rect2i, layer : int, source_id : int, atlas_coords : Vector2i, special : bool, scene_id : int, undone : bool = false) -> void:
	
	# undoredo
	# will basically erase the tiles that were on the rect before
	# unfortunately i dont have time to make the undo actually work
	# unfortunate innit
	# TODO: make the undo actually work
	if not undone:
		undoredo_history.push_front({
			"action_name": "Set Rect",
			"method_name": "set_tile_rect",
			"params": [rect, layer, source_id, atlas_coords, special, scene_id],
			"undo_method": "set_tile_rect",
			"undo_params": [
				rect,
				layer,
				-1,
				Vector2i(-1, -1),
				false,
				-1,
				true
			]
		})
	# some math stuff
	var rect_x_len : int = absi(rect.size.x - rect.position.x)
	var rect_y_len : int = absi(rect.size.y - rect.position.y)
	
	var x_increment : int = signi(rect.size.x - initial_rect_or_line_pos.x)
	var x : int
	var i : int
	while i <= rect_x_len:
		
		# directly next to the initial pos
		tilemap.set_cell(
			layer,
			Vector2i(initial_rect_or_line_pos.x + x, initial_rect_or_line_pos.y),
			source_id,
			atlas_coords if not special else Vector2i(0, 0),
			0 if not special else scene_id
		)
		
		# parallel side
		tilemap.set_cell(
			layer,
			Vector2i(initial_rect_or_line_pos.x + x, initial_rect_or_line_pos.y + rect_y_len),
			source_id,
			atlas_coords if not special else Vector2i(0, 0),
			0 if not special else scene_id
		)
		x += x_increment
		i += 1
	
	var y_increment : int = signi(rect.size.y - initial_rect_or_line_pos.y)
	var y : int
	var j : int
	while j <= rect_y_len:
		
		# right next to the initial pos
		tilemap.set_cell(
			layer,
			Vector2i(initial_rect_or_line_pos.x, initial_rect_or_line_pos.y + y),
			source_id,
			atlas_coords if not special else Vector2i(0, 0),
			0 if not special else scene_id
		)
		
		# parallel side
		tilemap.set_cell(
			layer,
			Vector2i(initial_rect_or_line_pos.x + rect_x_len, initial_rect_or_line_pos.y + y),
			source_id,
			atlas_coords if not special else Vector2i(0, 0),
			0 if not special else scene_id
		)
		
		y += y_increment
		j += 1


func erase_cell(layer : int, coords : Vector2i, undone : bool = false) -> void:
	
	if not undone:
		undoredo_history.push_front({
			"action_name": "Erase Cell",
			"method_name": "set_cell",
			"params": [layer, coords],
			"undo_method": "erase_cell",
			"undo_params": [
				layer,
				coords,
				tilemap.get_cell_source_id(layer, coords),
				tilemap.get_cell_atlas_coords(layer, coords),
				tilemap.get_cell_alternative_tile(layer, coords),
				true
			]
		})
	
	tilemap.erase_cell(layer, coords)


func undo_redo(undo : bool) -> void:
	
	if undoredo_history.is_empty(): return
	
	if undo:
		
		var action : Dictionary = undoredo_history[0]
		
		callv(action["undo_method"], action["undo_params"])
		
		last_undone_action = action
		
		undoredo_history.erase(action)
		
	
	else:
		
		if last_undone_action.is_empty(): return
		
		callv(last_undone_action["method_name"], last_undone_action["params"])
		
		undoredo_history.push_front(last_undone_action)
		
		last_undone_action = {}
