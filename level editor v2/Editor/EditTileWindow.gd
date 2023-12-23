extends Control


func enter(layer : int, properties : Array[Dictionary], node : Object, origin_tilemap : TileMap) -> void:
	
	visible = true
	
	var container : VBoxContainer = VBoxContainer.new()
	$ScrollContainer.add_child(container)
	
	for property : Dictionary in properties:
		
		if property["name"].ends_with(".gd"):
			continue
		
		if not property["name"] in node:
			continue
		
		if typeof(node.get(property["name"])) == TYPE_OBJECT:
			continue
		
		var h_container : HBoxContainer = HBoxContainer.new()
		var label : Label = Label.new()
		var input : LineEdit = LineEdit.new()
		
		container.add_child(h_container)
		
		h_container.add_child(label)
		h_container.add_child(input)
		
		label.text = property["name"]
		input.text = var_to_str(node.get(property["name"]))
		
		input.text_submitted.connect(func(text: String) -> void:
			node.set(property["name"], str_to_var(text))
			origin_tilemap.notify_runtime_tile_data_update(layer)
			print(node.get(property["name"]))
			)
