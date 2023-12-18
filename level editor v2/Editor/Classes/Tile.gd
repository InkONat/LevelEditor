@tool
## Resource that holds data for a TileIcon to be made inside a TileTab.
class_name Tile extends Resource

## If this tile is special, it will be based on a scene file instead of a normal TileMap based tile.
@export var special : bool = false:
	set(value):
		special = value
		notify_property_list_changed()

## ID of the special tile in the [TileSetScenesCollectionSource] of the [TileSet].
var scene_id : int = 0

## Custom icon image for the TileIcon of this tile. Leave as empty for the icon to get it's own texture or get the scene node's sprite property (if the node has that property) for the texture.
var custom_icon_image : Texture2D = null

## Atlas coordinates of the normal tile in the tilemap.
var atlas_coords : Vector2i = Vector2i(0, 0)

## ID of the [TileSetSource] of this tile in the [TileSet].
@export var source_id : int = 0

func _get_property_list() -> Array[Dictionary]:
	var properties : Array[Dictionary] = []
	
	var property_usage_atlas_coords : int = PROPERTY_USAGE_DEFAULT
	var property_usage_scene_id : int = PROPERTY_USAGE_NO_EDITOR
	
	if special:
		property_usage_atlas_coords = PROPERTY_USAGE_NO_EDITOR
		property_usage_scene_id = PROPERTY_USAGE_DEFAULT
	
	properties.append({
		"name": "scene_id",
		"type": TYPE_INT,
		"usage": property_usage_scene_id,
	})
	properties.append({
		"name": "atlas_coords",
		"type": TYPE_VECTOR2I,
		"usage": property_usage_atlas_coords,
	})
	
	return properties


func _to_string() -> String:
	return str("Tile:<Tile#", get_instance_id(), ">")
