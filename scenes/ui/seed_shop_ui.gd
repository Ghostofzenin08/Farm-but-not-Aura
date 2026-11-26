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
	Enum.Item.CORN: "Corn Seeds",
	Enum.Item.TOMATO: "Tomato Seeds",
	Enum.Item.PUMPKIN: "Pumpkin Seeds",
	Enum.Item.WHEAT: "Wheat Seeds",
}

const SEEDS_FOR_SALE: Array[Enum.Item] = [
	Enum.Item.TOMATO,
	Enum.Item.CORN,
	Enum.Item.WHEAT,
	Enum.Item.PUMPKIN,
	Enum.Item.APPLE,
]

@onready var gold_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Header/GoldLabel
@onready var items_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ItemsContainer
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
	gold_label.text = "Your Gold: %d G" % Data.gold
	
	for child in items_container.get_children():
		child.queue_free()
	
	for item in SEEDS_FOR_SALE:
		var price = Data.SEED_BUY_PRICES.get(item, 0)
		var in_inventory = Data.items.get(item, 0)
		var max_affordable = int(Data.gold / float(price)) if price > 0 else 0
		
		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 16)
		
		# Icon
		var icon_rect = TextureRect.new()
		icon_rect.texture = ITEM_ICONS.get(item)
		icon_rect.custom_minimum_size = Vector2(28, 28)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon_rect)
		
		# Item info
		var info_label = Label.new()
		info_label.text = "%s (%d G)" % [ITEM_NAMES.get(item, "Seeds"), price]
		info_label.custom_minimum_size = Vector2(170, 0)
		info_label.add_theme_font_size_override("font_size", 18)
		row.add_child(info_label)
		
		# In bag count
		var bag_label = Label.new()
		bag_label.text = "In Bag: %d" % in_inventory
		bag_label.custom_minimum_size = Vector2(120, 0)
		bag_label.add_theme_font_size_override("font_size", 18)
		bag_label.add_theme_color_override("font_color", Color(0.3, 0.75, 0.9, 1))
		row.add_child(bag_label)
		
		# Buy 1 button
		var btn_buy_1 = Button.new()
		btn_buy_1.text = "+1"
		btn_buy_1.disabled = Data.gold < price
		btn_buy_1.add_theme_font_size_override("font_size", 16)
		btn_buy_1.pressed.connect(func(): _buy_item(item, 1))
		row.add_child(btn_buy_1)
		
		# Buy 5 button
		var btn_buy_5 = Button.new()
		btn_buy_5.text = "+5"
		btn_buy_5.disabled = Data.gold < (price * 5)
		btn_buy_5.add_theme_font_size_override("font_size", 16)
		btn_buy_5.pressed.connect(func(): _buy_item(item, 5))
		row.add_child(btn_buy_5)
		
		# Buy Max button
		var btn_buy_max = Button.new()
		btn_buy_max.text = "+Max"
		btn_buy_max.disabled = max_affordable < 1
		btn_buy_max.add_theme_font_size_override("font_size", 16)
		btn_buy_max.pressed.connect(func(): _buy_item(item, max_affordable))
		row.add_child(btn_buy_max)
		
		items_container.add_child(row)


func _buy_item(item: Enum.Item, count: int) -> void:
	if Data.buy_seed(item, count):
		update_view()


func _on_close_pressed() -> void:
	hide()
	close.emit()
