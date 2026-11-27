extends Node2D

var border_color: Color = Color(1.0, 1.0, 1.0, 0.6)
var fill_color: Color = Color(1.0, 1.0, 1.0, 0.12)
var pulse_time: float = 0.0

func _process(delta: float) -> void:
	pulse_time += delta * 4.0
	var alpha_factor = 0.75 + sin(pulse_time) * 0.25
	modulate.a = alpha_factor
	queue_redraw()

func set_cursor_style(new_border: Color, new_fill: Color) -> void:
	border_color = new_border
	fill_color = new_fill
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 16, 16), fill_color, true)
	draw_rect(Rect2(0, 0, 16, 16), border_color, false, 1.0)
