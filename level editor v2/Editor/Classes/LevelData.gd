class_name LevelData extends Resource

## Level data is stored in an array of dictionaries: [br]
## [code]"layer"[/code]: the layer of the tile, more specifically it's z_index [br]
## [code]"tile"[/code]: will be an array: [br]The first element will either be the atlas coordinate of the tile or the scene id (an [class int]) depending if it is special or not; [br]The second element will be the source id for the tile, being an integer; [br]
## [code]"pos[/code]: will be the position of the tile, a Vector2; [br]
## [code]"properties"[/code]: all script properties of the tile if it is a special tile (empty array if it isnt), used for tile editing [br]
@export var data : Array[Dictionary] = []

func _init(_data: Array[Dictionary] = []) -> void:
	data = _data
