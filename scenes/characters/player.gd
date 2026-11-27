extends CharacterBody2D

var direction: Vector2
var last_direction: Vector2 = Vector2.DOWN
var speed := 50
var can_move: bool = true
@onready var move_state_machine = $Animation/AnimationTree.get("parameters/MoveStateMachine/playback")
@onready var tool_state_machine = $Animation/AnimationTree.get("parameters/ToolStateMachine/playback")
var current_tool: Enum.Tool = Enum.Tool.AXE
var current_seed: Enum.Seed
var current_state: Enum.State
var current_style: Enum.Style
var current_style_index: int
var current_machine: Enum.Machine
var current_machine_index: int
const TOOL_ENERGY_COSTS = {
	Enum.Tool.HOE: 2.0,
	Enum.Tool.WATER: 1.0,
	Enum.Tool.AXE: 2.5,
	Enum.Tool.SWORD: 1.5,
	Enum.Tool.FISH: 3.0,
	Enum.Tool.SEED: 0.5,
}
@onready var tool_sounds = {
	Enum.Tool.AXE: $Sounds/Axe,
	Enum.Tool.SWORD: $Sounds/Axe,
	Enum.Tool.FISH: $Sounds/Fish,
	Enum.Tool.HOE: $Sounds/Hoe,
	Enum.Tool.SEED: $Sounds/Seed,
	Enum.Tool.WATER: $Sounds/Water,
}

signal tool_use(tool: Enum.Tool, pos: Vector2)
signal diagnose
signal day_change
signal build(current_machine: Enum.Machine)
signal machine_change(current_machine: Enum.Machine)
signal close_shop
signal help_requested

var camera_trauma: float = 0.0
var max_camera_offset: float = 4.0
var trauma_decay: float = 2.5

func _ready() -> void:
	Data.camera_shake_requested.connect(add_camera_shake)


func add_camera_shake(amount: float) -> void:
	camera_trauma = clampf(camera_trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	if camera_trauma > 0.0:
		camera_trauma = maxf(camera_trauma - trauma_decay * delta, 0.0)
		var shake = camera_trauma * camera_trauma
		var offset_x = randf_range(-1.0, 1.0) * max_camera_offset * shake
		var offset_y = randf_range(-1.0, 1.0) * max_camera_offset * shake
		$Camera2D.offset = Vector2(offset_x, offset_y)
	elif $Camera2D.offset != Vector2.ZERO:
		$Camera2D.offset = Vector2.ZERO


func _physics_process(_delta: float) -> void:
	match current_state:
		Enum.State.DEFAULT:
			if can_move:
				get_basic_input()
				move()
				animate()
		Enum.State.FISHING:
			get_fishing_input()
		Enum.State.BUILDING:
			get_building_input()
			move()
			animate()
		Enum.State.SHOP:
			get_shopping_input()
	if direction:
		last_direction = direction
		$RayCast2D.target_position = direction.normalized() * 20
		
		if not $Sounds/StepTimer.time_left:
			$Sounds/StepTimer.start()
	else:
		$Sounds/StepTimer.stop()


func get_basic_input():
	if Input.is_action_just_pressed("tool_forward") or Input.is_action_just_pressed("tool_backward"):
		var dir = Input.get_axis("tool_backward", "tool_forward")
		current_tool = posmod(current_tool + int(dir), Enum.Tool.size()) as Enum.Tool
		$ToolUI.reveal(true)
		get_tree().get_first_node_in_group("ResourceUI").visible = current_tool == Enum.Tool.SEED
		if Data.tutorial_step == 1 and current_tool == Enum.Tool.HOE:
			Data.advance_tutorial(1)
	
	if Input.is_action_just_pressed("seed_forward"):
		current_seed = posmod(current_seed + 1, Enum.Seed.size()) as Enum.Seed
		$ToolUI.reveal(false)
	
	if Input.is_action_just_pressed("action"):
		var collider = $RayCast2D.get_collider()
		if collider and collider.has_method("interact"):
			collider.interact(self)
		else:
			if Data.energy <= 0.0 and (current_tool == Enum.Tool.AXE or current_tool == Enum.Tool.HOE):
				var resource_ui = get_tree().get_first_node_in_group("ResourceUI")
				if resource_ui:
					resource_ui.reveal(true)
				return
			tool_state_machine.travel(Data.TOOL_STATE_ANIMATIONS[current_tool])
			$Animation/AnimationTree.set("parameters/ToolOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	if Input.is_action_just_pressed("eat"):
		eat_apple()

	if Input.is_action_just_pressed("help"):
		help_requested.emit()
	
	if Input.is_action_just_pressed("diagnose"):
		diagnose.emit()

	if Input.is_action_just_pressed("style_toggle"):
		current_style_index = posmod(current_style_index + 1, Data.unlocked_styles.size())
		current_style = Data.unlocked_styles[current_style_index] as Enum.Style
		$Sprite2D.texture = Data.PLAYER_SKINS[current_style]

	
	if Input.is_action_just_pressed("build"):
		current_state = Enum.State.BUILDING
		current_machine = Data.unlocked_machines[current_machine_index] as Enum.Machine


func get_fishing_input():
	if Input.is_action_just_pressed("action"):
		$FishingGame.action()


func get_building_input():
	if Input.is_action_just_pressed("build"):
		current_state = Enum.State.DEFAULT
	
	if Input.is_action_just_pressed("tool_forward") or Input.is_action_just_pressed("tool_backward"):
		var dir = Input.get_axis("tool_backward", "tool_forward")
		current_machine_index = posmod(current_machine_index + int(dir), Data.unlocked_machines.size())
		current_machine = Data.unlocked_machines[current_machine_index] as Enum.Machine
		machine_change.emit(current_machine)

	if Input.is_action_just_pressed("action"):
		build.emit(current_machine)


func get_shopping_input():
	if Input.is_action_just_pressed("ui_cancel"):
		close_shop.emit()
		get_tree().get_first_node_in_group("ResourceUI").hide()


func move():
	direction = Input.get_vector("left", "right", "up", "down")
	var current_speed = speed * 0.55 if Data.energy <= 0.0 else speed
	velocity = direction * current_speed
	move_and_slide()
	if Data.tutorial_step == 0 and velocity.length_squared() > 1.0:
		Data.advance_tutorial(0)


func animate():
	if direction:
		move_state_machine.travel('Walk')
		var direction_animation = Vector2(round(direction.x),round(direction.y))
		$Animation/AnimationTree.set("parameters/MoveStateMachine/Idle/blend_position", direction_animation)
		$Animation/AnimationTree.set("parameters/MoveStateMachine/Walk/blend_position", direction_animation)
		$Animation/AnimationTree.set("parameters/FishBlendSpace2D/blend_position", direction_animation)
		for animation in Data.TOOL_STATE_ANIMATIONS.values():
			var animation_name: String = "parameters/ToolStateMachine/"+ animation +"/blend_position"
			$Animation/AnimationTree.set(animation_name, direction_animation)
	else:
		move_state_machine.travel('Idle')


func start_fishing():
	$FishingGame.reveal()
	current_state = Enum.State.FISHING
	$Animation/AnimationTree.set("parameters/FishBlend/blend_amount", 1)


func stop_fishing():
	can_move = true
	current_state = Enum.State.DEFAULT
	$Animation/AnimationTree.set("parameters/FishBlend/blend_amount", 0)


func tool_use_emit():
	var cost = TOOL_ENERGY_COSTS.get(current_tool, 1.0)
	Data.change_energy(-cost)
	tool_use.emit(current_tool, position + last_direction * 16 + Vector2(0,4))
	tool_sounds[current_tool].play()


func eat_apple() -> bool:
	if Data.items.get(Enum.Item.APPLE, 0) > 0 and Data.energy < Data.max_energy:
		Data.change_item(Enum.Item.APPLE, -1)
		Data.change_energy(25.0)
		Data.spawn_floating_text("+25 Energy", position + Vector2(0, -20), Color(0.25, 0.9, 0.35))
		if has_node("Sounds/Eat"):
			$Sounds/Eat.pitch_scale = randf_range(0.9, 1.1)
			$Sounds/Eat.play()
		if Data.tutorial_step == 5:
			Data.advance_tutorial(5)
		return true
	return false


func _on_animation_tree_animation_started(_anim_name: StringName) -> void:
	can_move = false


func _on_animation_tree_animation_finished(_anim_name: StringName) -> void:
	can_move = true


func day_change_emit():
	day_change.emit()


func get_machine_coord() -> Vector2i:
	var pos = position + last_direction * 20 + Vector2(0,8)
	var tile_x = int(floor(pos.x / float(Data.TILE_SIZE)))
	var tile_y = int(floor(pos.y / float(Data.TILE_SIZE)))
	return Vector2i(tile_x, tile_y) * Data.TILE_SIZE + Vector2i(8,8)


func _on_step_timer_timeout() -> void:
	$Sounds/Step.play()
