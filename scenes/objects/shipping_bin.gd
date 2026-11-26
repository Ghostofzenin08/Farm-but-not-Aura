extends StaticBody2D

signal open_shipping_bin

func interact(_player: CharacterBody2D) -> void:
	var level = get_tree().current_scene
	if level and level.has_method("open_shipping_bin"):
		level.open_shipping_bin()
	else:
		open_shipping_bin.emit()
