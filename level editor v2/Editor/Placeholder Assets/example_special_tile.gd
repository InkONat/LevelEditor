extends Node2D

# For a tile, its important to add an "icon" property to the script of the root scene.
# That will be the icon for it's tile icon in the editor.
# If you don't want to add that, the class will get the first Sprite2D child of this node.
# You can also add a custom icon to the TileIcon if you want.

@onready var icon : Sprite2D = $Sprite2D
