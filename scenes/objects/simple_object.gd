@tool
extends StaticBody2D

@export_range(0,3,1) var size: int = 0:
	set(value):
		size = value
		_update_sprite()
@export_enum('Bush', 'Rock') var style: int = 0:
	set(value):
		style = value
		_update_sprite()
@export var random: bool
@export_tool_button('Randomize', "Callable") var randomizer = randomize

func _update_sprite() -> void:
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.frame_coords = Vector2i(size, style)
	var col = get_node_or_null("CollisionShape2D")
	if col:
		col.disabled = size < 2
	z_index = -1 if size < 2 else 0

func _ready() -> void:
	if random and has_node("Sprite2D"):
		size = randi_range(0, $Sprite2D.hframes - 1)
		style = [0,1].pick_random()
	_update_sprite()

func randomize():
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		size = randi_range(0, sprite.hframes - 1)
		style = [0,1].pick_random()
		_update_sprite()
