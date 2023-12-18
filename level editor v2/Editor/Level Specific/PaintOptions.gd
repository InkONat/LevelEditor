extends OptionButton

func _on_item_selected(index: int) -> void:
	Editor.paint_mode = index

func _ready() -> void:
	selected = Editor.paint_mode


# dont wanna create another script for a single signal so ill just do it here
func _on_edit_mode_toggled(toggled_on: bool) -> void:
	Editor.edit_mode = toggled_on
