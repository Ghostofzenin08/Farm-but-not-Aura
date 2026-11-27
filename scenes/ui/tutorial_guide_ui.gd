extends Control

signal close

var current_page: int = 0

const PAGES = [
	{
		"title": "Controls & Keybindings",
		"items": [
			{"key": "W, A, S, D / Arrows", "desc": "Walk and explore the farm and farmhouse"},
			{"key": "Space", "desc": "Use equipped tool / Interact with objects, villagers & bed"},
			{"key": "Q / E", "desc": "Cycle equipped tools (Hoe, Water Can, Seeds, Axe, Sword, Fish)"},
			{"key": "C", "desc": "Cycle seed type when Seeds tool is equipped"},
			{"key": "F", "desc": "Eat an Apple from inventory to restore +25 Energy"},
			{"key": "M", "desc": "Cycle blueprints for farm automation machines"},
			{"key": "H", "desc": "Toggle this Farmer's Handbook anytime"},
			{"key": "Esc", "desc": "Close open shops or menus"}
		]
	},
	{
		"title": "Farming 101: Soil to Harvest",
		"items": [
			{"key": "1. Till Soil", "desc": "Equip Hoe (Q/E) and press Space on grassy land to prepare soil."},
			{"key": "2. Hydrate Plots", "desc": "Equip Watering Can and press Space on tilled soil. Wet dirt turns dark."},
			{"key": "3. Natural Rain", "desc": "On rainy days, all your soil plots are watered automatically!"},
			{"key": "4. Sow Seeds", "desc": "Equip Seeds (Q/E), choose crop with C, press Space on wet soil."},
			{"key": "5. Harvest", "desc": "Plants grow every day you water them. Press Space to harvest when ripe!"}
		]
	},
	{
		"title": "Village Economy & Shops",
		"items": [
			{"key": "Shipping Bin", "desc": "Located left of your house. Deposit crops, wood, or fish."},
			{"key": "Nightly Settlement", "desc": "Every night when you sleep, shipped items are sold for gold!"},
			{"key": "Seed Merchant", "desc": "Talk to the friendly woman near your house to buy fresh seeds."},
			{"key": "Machine Cat", "desc": "Unlocks automated sprinklers, harvesters, and scarecrows."},
			{"key": "Hat Mouse", "desc": "Sells stylish cosmetic hats to personalize your farmer!"}
		]
	},
	{
		"title": "Energy, Night Survival & Saving",
		"items": [
			{"key": "Energy Meter", "desc": "Every tool swing consumes stamina. Low energy causes exhaustion!"},
			{"key": "Eating Food", "desc": "Press F to eat apples gathered from trees for quick stamina (+25)."},
			{"key": "Night Blobs", "desc": "Dangerous slime blobs roam after dark. Equip Sword (Q/E) to defeat them!"},
			{"key": "Sleep to Save", "desc": "Walk up to the Bed inside your farmhouse and press Space to sleep."},
			{"key": "Full Recovery", "desc": "Sleeping in bed saves your game and restores your energy to 100%!"}
		]
	}
]

@onready var page_title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Header/PageTitle
@onready var content_list: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContentList
@onready var page_num_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Footer/PageNumLabel
@onready var prev_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Footer/PrevButton
@onready var next_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Footer/NextButton
@onready var close_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Footer/CloseButton


func _ready() -> void:
	hide()
	prev_btn.pressed.connect(_on_prev_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	close_btn.pressed.connect(_on_close_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("help"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_on_prev_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_on_next_pressed()
		get_viewport().set_input_as_handled()


func reveal() -> void:
	current_page = 0
	render_page()
	show()
	close_btn.grab_focus()


func render_page() -> void:
	var page_data = PAGES[current_page]
	page_title_label.text = "%s" % page_data["title"]
	page_num_label.text = "Page %d / %d" % [current_page + 1, PAGES.size()]
	
	prev_btn.disabled = (current_page == 0)
	next_btn.disabled = (current_page == PAGES.size() - 1)
	
	for child in content_list.get_children():
		child.queue_free()
	
	for item in page_data["items"]:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		
		var key_label = Label.new()
		key_label.text = item["key"]
		key_label.custom_minimum_size = Vector2(190, 0)
		key_label.add_theme_font_size_override("font_size", 16)
		key_label.add_theme_color_override("font_color", Color(0.15, 0.45, 0.75, 1.0))
		row.add_child(key_label)
		
		var desc_label = Label.new()
		desc_label.text = item["desc"]
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.add_theme_font_size_override("font_size", 15)
		desc_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1.0))
		row.add_child(desc_label)
		
		content_list.add_child(row)


func _on_prev_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		render_page()


func _on_next_pressed() -> void:
	if current_page < PAGES.size() - 1:
		current_page += 1
		render_page()


func _on_close_pressed() -> void:
	hide()
	close.emit()
