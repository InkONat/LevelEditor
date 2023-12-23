## TextureRect that can select a tile. [b]Does not do anything inside the editor.[/b]
class_name TileIcon extends TextureRect

## The tile this icon will select when clicked.
@export var tile : Tile

## Reference tileset for this TileIcon.
var reference_tileset : TileSet

## Used to control highlighting
static var icons : Array[TileIcon]

func _ready() -> void:
	
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	icons.append(self)
	
	# ".." means parent, "../.." means grandparent
	if not get_node("..") is GridContainer:
		printerr("Tile icon parent is not a GridContainer. Will have buggy behavior.")
	
	if not get_node("../..") is TileTab:
		printerr("Tile icon grandparent is not a TileTab. Will have buggy behavior.")
	
	clip_contents = true
	
	custom_minimum_size = Vector2(32, 32)
	
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var source : TileSetSource = reference_tileset.get_source(tile.source_id)
	
	# get_source either returns a TileSetAtlasSource or a TileSetScenesCollectionSource
	
	if source is TileSetAtlasSource:
		
		var atlas : AtlasTexture = AtlasTexture.new()
		atlas.atlas = source.texture
		
		var rect : Rect2i = source.get_tile_texture_region(tile.atlas_coords)
		atlas.region = rect
		
		texture = atlas
	
	elif source is TileSetScenesCollectionSource:
		
		var inst : Node2D = source.get_scene_tile_scene(tile.scene_id).instantiate()
		
		add_child(inst)
		
		var found_texture : bool = false
		
		# first possibility: scene is a sprite2d
		if inst is Sprite2D:
			texture = inst.texture
			found_texture = true
		
		# second possibility: scene has an "icon" property
		elif "icon" in inst:
			var icon : Node2D = inst.icon
			
			if icon is Sprite2D:
				texture = inst.icon.texture
			
			elif icon is AnimatedSprite2D:
				texture = icon.sprite_frames.get_frame_texture(icon.sprite.animation, 0)
			
			found_texture = true
		
		# third possibility: scene has at least one sprite2d node
		
		if not found_texture:
			
			for child: Node2D in inst.get_children():
				
				if child is Sprite2D:
					texture = child.texture
					found_texture = true
					break
		
		inst.free()
		
		# if none of those are true then add the placeholder texture
		
		if not found_texture:
			push_warning("Texture was not provided for the tile. Using the placeholder icon.")
			texture = preload("res://Editor/Placeholder Assets/placeholder_icon.png")


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			
			if Editor.tile != tile:
				
				Editor.tile = tile
				
				# setting the highlight
				modulate = Color.GREEN
				
				# removing highlight on the other tiles
				for icon in icons:
					
					if icon != self: icon.modulate = Color.WHITE
			
			else:
				
				Editor.tile = null
				modulate = Color.WHITE
			


func _exit_tree() -> void:
	icons.erase(self)


func _to_string() -> String:
	return str("TileIcon:<TileIcon#", get_instance_id(), ">")
