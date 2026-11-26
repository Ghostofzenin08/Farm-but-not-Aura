extends Control

@onready var day_label: Label = $MarginContainer/PanelContainer/HBoxContainer/DayLabel
@onready var gold_label: Label = $MarginContainer/PanelContainer/HBoxContainer/GoldLabel
@onready var energy_label: Label = $MarginContainer/PanelContainer/HBoxContainer/EnergyLabel

func _ready() -> void:
	Data.day_changed.connect(_on_day_changed)
	Data.gold_changed.connect(_on_gold_changed)
	Data.energy_changed.connect(_on_energy_changed)
	update_display()


func update_display() -> void:
	if day_label:
		day_label.text = "Day %d" % Data.day
	if gold_label:
		gold_label.text = "%d G" % Data.gold
	if energy_label:
		energy_label.text = "%d" % int(Data.energy)
		if Data.energy > 50.0:
			energy_label.add_theme_color_override("font_color", Color(0.2, 0.85, 0.3, 1))
		elif Data.energy > 20.0:
			energy_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2, 1))
		else:
			energy_label.add_theme_color_override("font_color", Color(0.9, 0.25, 0.25, 1))


func _on_day_changed(_new_day: int) -> void:
	update_display()


func _on_gold_changed(_new_gold: int) -> void:
	update_display()


func _on_energy_changed(_current: float, _max_val: float) -> void:
	update_display()
