extends Control

signal guide_requested

const STEPS = [
	{
		"title": "1. Stroll Your Farm",
		"hint": "Move around using WASD or Arrow Keys.",
	},
	{
		"title": "2. Equip Your Hoe",
		"hint": "Press Q or E to cycle tools to the Hoe.",
	},
	{
		"title": "3. Till the Soil",
		"hint": "Face grassy farm soil and press Space to till.",
	},
	{
		"title": "4. Water the Ground",
		"hint": "Switch to Water Can (Q/E) & press Space.",
	},
	{
		"title": "5. Sow Crop Seeds",
		"hint": "Select Seeds (Q/E), pick with C, press Space.",
	},
	{
		"title": "6. Eat an Apple",
		"hint": "Press F to eat an apple for Energy (+25).",
	},
	{
		"title": "7. Shipping Bin",
		"hint": "Walk to bin near house and press Space.",
	},
	{
		"title": "8. Rest in Bed",
		"hint": "Go inside house and press Space on Bed to sleep.",
	}
]

var is_collapsed: bool = false

@onready var title_label: Label = $MarginContainer/PanelContainer/VBoxContainer/Header/TitleLabel
@onready var hint_label: Label = $MarginContainer/PanelContainer/VBoxContainer/Content/HintLabel
@onready var progress_bar: ProgressBar = $MarginContainer/PanelContainer/VBoxContainer/Content/ProgressBar
@onready var collapse_btn: Button = $MarginContainer/PanelContainer/VBoxContainer/Header/CollapseButton
@onready var guide_btn: Button = $MarginContainer/PanelContainer/VBoxContainer/Header/GuideButton
@onready var content_box: VBoxContainer = $MarginContainer/PanelContainer/VBoxContainer/Content


func _ready() -> void:
	Data.tutorial_step_advanced.connect(_on_tutorial_step_advanced)
	Data.tutorial_completed_signal.connect(_on_tutorial_completed)
	collapse_btn.pressed.connect(_toggle_collapse)
	guide_btn.pressed.connect(_on_guide_pressed)
	update_display()


func update_display() -> void:
	if not title_label or not hint_label or not progress_bar:
		return
	
	if Data.tutorial_completed:
		title_label.text = "All Quests Done!"
		title_label.add_theme_color_override("font_color", Color(0.2, 0.85, 0.3, 1))
		hint_label.text = "You're ready to grow your farm! Press H for Guide."
		progress_bar.max_value = STEPS.size()
		progress_bar.value = STEPS.size()
		return
	
	var step_idx = clamp(Data.tutorial_step, 0, STEPS.size() - 1)
	var step_info = STEPS[step_idx]
	title_label.text = "[%d/%d] %s" % [step_idx + 1, STEPS.size(), step_info["title"]]
	title_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1))
	hint_label.text = step_info["hint"]
	progress_bar.max_value = STEPS.size()
	progress_bar.value = step_idx


func _on_tutorial_step_advanced(_new_step: int) -> void:
	update_display()


func _on_tutorial_completed() -> void:
	update_display()


func _toggle_collapse() -> void:
	is_collapsed = !is_collapsed
	content_box.visible = !is_collapsed
	collapse_btn.text = "+" if is_collapsed else "-"


func _on_guide_pressed() -> void:
	guide_requested.emit()
