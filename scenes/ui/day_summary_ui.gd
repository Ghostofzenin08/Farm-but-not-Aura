extends Control

signal confirmed

const ITEM_ICONS = {
	Enum.Item.WOOD: preload("res://graphics/icons/wood.png"),
	Enum.Item.APPLE: preload("res://graphics/icons/apple.png"),
	Enum.Item.FISH: preload("res://graphics/icons/goldfish.png"),
	Enum.Item.CORN: preload("res://graphics/icons/corn.png"),
	Enum.Item.TOMATO: preload("res://graphics/icons/tomato.png"),
	Enum.Item.PUMPKIN: preload("res://graphics/icons/pumpkin.png"),
	Enum.Item.WHEAT: preload("res://graphics/icons/wheat.png"),
}

const ITEM_NAMES = {
	Enum.Item.WOOD: "Wood",
	Enum.Item.APPLE: "Apple",
	Enum.Item.FISH: "Fish",
	Enum.Item.CORN: "Corn",
	Enum.Item.TOMATO: "Tomato",
	Enum.Item.PUMPKIN: "Pumpkin",
	Enum.Item.WHEAT: "Wheat",
}

@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Title
@onready var breakdown_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/BreakdownContainer
@onready var total_earned_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TotalEarnedLabel
@onready var current_gold_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CurrentGoldLabel
@onready var continue_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinueButton

func _ready() -> void:
	hide()
	continue_button.pressed.connect(_on_continue_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("action") or event.is_action_pressed("ui_accept") or event.is_action_pressed("day_change")):
		_on_continue_pressed()
		get_viewport().set_input_as_handled()


func display_summary(settlement: Dictionary, day_number: int) -> void:
	title_label.text = "DAY %d REPORT" % day_number
	
	for child in breakdown_container.get_children():
		child.queue_free()
	
	var breakdown: Dictionary = settlement.get("breakdown", {})
	if breakdown.is_empty():
		var no_sales = Label.new()
		no_sales.text = "No items shipped last night."
		no_sales.add_theme_font_size_override("font_size", 18)
		no_sales.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
		no_sales.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		breakdown_container.add_child(no_sales)
	else:
		for item_key in breakdown.keys():
			var item_enum = int(item_key) as Enum.Item
			var item_data: Dictionary = breakdown[item_key]
			var count = int(item_data.get("count", 0))
			var subtotal = int(item_data.get("subtotal", 0))
			
			var row = HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 16)
			
			var icon_rect = TextureRect.new()
			icon_rect.texture = ITEM_ICONS.get(item_enum)
			icon_rect.custom_minimum_size = Vector2(24, 24)
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(icon_rect)
			
			var name_label = Label.new()
			name_label.text = "%s  x%d" % [ITEM_NAMES.get(item_enum, "Item"), count]
			name_label.custom_minimum_size = Vector2(180, 0)
			name_label.add_theme_font_size_override("font_size", 18)
			row.add_child(name_label)
			
			var subtotal_label = Label.new()
			subtotal_label.text = "+%d G" % subtotal
			subtotal_label.custom_minimum_size = Vector2(90, 0)
			subtotal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			subtotal_label.add_theme_font_size_override("font_size", 18)
			subtotal_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.3, 1))
			row.add_child(subtotal_label)
			
			breakdown_container.add_child(row)
	
	var total = int(settlement.get("total", 0))
	total_earned_label.text = "Total Overnight Profit: +%d G" % total
	current_gold_label.text = "Current Balance: %d G" % int(settlement.get("current_gold", Data.gold))
	
	show()
	continue_button.grab_focus()


func _on_continue_pressed() -> void:
	hide()
	confirmed.emit()
