extends Control

signal close

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

const SHIPPING_ITEMS: Array[Enum.Item] = [
	Enum.Item.TOMATO,
	Enum.Item.CORN,
	Enum.Item.WHEAT,
	Enum.Item.PUMPKIN,
	Enum.Item.FISH,
	Enum.Item.APPLE,
	Enum.Item.WOOD
]

@onready var items_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ItemsContainer
@onready var total_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Footer/TotalLabel
@onready var close_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Footer/CloseButton

func _ready() -> void:
	hide()
	close_button.pressed.connect(_on_close_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("day_change")):
		_on_close_pressed()
		get_viewport().set_input_as_handled()


func reveal() -> void:
	update_view()
	show()
	close_button.grab_focus()


func update_view() -> void:
	for child in items_container.get_children():
		child.queue_free()
	
	var total_pending = 0
	
	for item in SHIPPING_ITEMS:
		var price = Data.ITEM_PRICES.get(item, 0)
		var in_inventory = Data.items.get(item, 0)
		var in_bin = Data.shipped_items.get(item, 0)
		total_pending += in_bin * price
		
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		
		# Icon
		var icon_rect = TextureRect.new()
		icon_rect.texture = ITEM_ICONS.get(item)
		icon_rect.custom_minimum_size = Vector2(28, 28)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon_rect)
		
		# Info label
		var info_label = Label.new()
		info_label.text = "%s (%d G)" % [ITEM_NAMES.get(item, "Item"), price]
		info_label.custom_minimum_size = Vector2(160, 0)
		info_label.add_theme_font_size_override("font_size", 18)
		row.add_child(info_label)
		
		# Counts label
		var count_label = Label.new()
		count_label.text = "Bag: %d  |  Bin: %d" % [in_inventory, in_bin]
		count_label.custom_minimum_size = Vector2(180, 0)
		count_label.add_theme_font_size_override("font_size", 18)
		if in_bin > 0:
			count_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.3, 1))
		row.add_child(count_label)
		
		# Buttons
		var btn_plus_one = Button.new()
		btn_plus_one.text = "+1"
		btn_plus_one.disabled = in_inventory < 1
		btn_plus_one.add_theme_font_size_override("font_size", 16)
		btn_plus_one.pressed.connect(func(): _ship_item(item, 1))
		row.add_child(btn_plus_one)
		
		var btn_plus_all = Button.new()
		btn_plus_all.text = "+All"
		btn_plus_all.disabled = in_inventory < 1
		btn_plus_all.add_theme_font_size_override("font_size", 16)
		btn_plus_all.pressed.connect(func(): _ship_item(item, in_inventory))
		row.add_child(btn_plus_all)
		
		var btn_minus_one = Button.new()
		btn_minus_one.text = "-1"
		btn_minus_one.disabled = in_bin < 1
		btn_minus_one.add_theme_font_size_override("font_size", 16)
		btn_minus_one.pressed.connect(func(): _cancel_item(item, 1))
		row.add_child(btn_minus_one)
		
		items_container.add_child(row)
	
	total_label.text = "Estimated Overnight Payout: %d G" % total_pending


func _ship_item(item: Enum.Item, amount: int) -> void:
	if Data.deposit_shipping_item(item, amount):
		update_view()


func _cancel_item(item: Enum.Item, amount: int) -> void:
	if Data.cancel_shipping_item(item, amount):
		update_view()


func _on_close_pressed() -> void:
	hide()
	close.emit()
