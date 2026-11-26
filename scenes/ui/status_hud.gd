extends Control

@onready var day_label: Label = $MarginContainer/PanelContainer/HBoxContainer/DayLabel
@onready var gold_label: Label = $MarginContainer/PanelContainer/HBoxContainer/GoldLabel

func _ready() -> void:
	Data.day_changed.connect(_on_day_changed)
	Data.gold_changed.connect(_on_gold_changed)
	update_display()


func update_display() -> void:
	if day_label:
		day_label.text = "Day %d" % Data.day
	if gold_label:
		gold_label.text = "%d G" % Data.gold


func _on_day_changed(_new_day: int) -> void:
	update_display()


func _on_gold_changed(_new_gold: int) -> void:
	update_display()
