extends Node2D

@export var grid_line_color : Color = Color.DIM_GRAY
@export var grid_line_size_modifier : int = 3

@onready var camera : Camera2D = get_node("../../Camera2D")
@onready var grid_size : Vector2 = get_node("../../TileMapFromEditor").tile_set.tile_size

func _process(_delta: float) -> void:
	
	queue_redraw()

@warning_ignore("narrowing_conversion")
func _draw() -> void:
	
	var vp_size : Vector2 = get_viewport().size
	var cam_pos : Vector2 = camera.global_position
	var vp_right : int = vp_size.x * camera.zoom.x
	var vp_bottom : int = vp_size.y * camera.zoom.y
	
	var leftmost : int = (-vp_right * grid_line_size_modifier) + cam_pos.x
	var topmost : int = (-vp_bottom * grid_line_size_modifier) + cam_pos.y
	var bottommost : int = (vp_bottom * grid_line_size_modifier) + cam_pos.y
	var rightmost : int = (vp_right * grid_line_size_modifier) + cam_pos.x
	
	var left : int = ceili(leftmost / grid_size.x) * grid_size.x
	
	for x in range(0, vp_size.x / camera.zoom.x):
		draw_line(Vector2(left, topmost), Vector2(left, bottommost), grid_line_color)
		left += grid_size.x

	var top : int = ceili(topmost / grid_size.y) * grid_size.y
	
	for y in range(0, vp_size.y / camera.zoom.y):
		draw_line(Vector2(leftmost, top), Vector2(rightmost, top), grid_line_color)
		top += grid_size.y
