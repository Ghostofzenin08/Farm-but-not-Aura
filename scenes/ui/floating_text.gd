extends Node2D

@onready var label: Label = $Label

func setup(text: String, start_pos: Vector2, color: Color = Color.WHITE, duration: float = 0.8) -> void:
	position = start_pos
	modulate = Color(1, 1, 1, 1)
	scale = Vector2(0.6, 0.6)
	
	if not is_node_ready():
		await ready
	
	label.text = text
	label.add_theme_color_override("font_color", color)
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	
	var move_tween = create_tween()
	move_tween.tween_property(self, "position:y", position.y - 24.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var fade_tween = create_tween()
	fade_tween.tween_interval(duration * 0.4)
	fade_tween.tween_property(self, "modulate:a", 0.0, duration * 0.6)
	fade_tween.tween_callback(queue_free)
