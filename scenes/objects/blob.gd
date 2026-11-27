extends CharacterBody2D

var direction: Vector2
var speed := 20
var push_distance := 130
var push_direction: Vector2
var health := 3:
	set(value):
		health = value
		if health <= 0:
			death()
var plant_target: StaticBody2D
var active: bool = true

@onready var player = get_tree().get_first_node_in_group('Player')

func setup(start_pos, target, parent):
	position = start_pos
	parent.add_child(self)
	plant_target = target


func _physics_process(_delta: float) -> void:
	if not active:
		return
	if is_instance_valid(plant_target):
		direction = (plant_target.position - position).normalized()
		velocity = direction * speed + push_direction
		move_and_slide()
		if position.distance_to(plant_target.position) < 10 and active:
			plant_target.damage()
			active = false
			death()
	else:
		var plants = get_tree().get_nodes_in_group('Plants')
		if plants:
			plant_target = plants.pick_random()
		else:
			death()


func push(dir = Vector2.ZERO):
	var tween = get_tree().create_tween()
	var target_dir = dir if dir else (player.position - position).normalized()
	var target =  target_dir * -1 * push_distance
	tween.tween_property(self, "push_direction", target, 0.1)
	tween.tween_property(self, "push_direction", Vector2.ZERO, 0.2)


func death():
	active = false
	speed = 0
	remove_from_group("Blobs")
	remove_from_group("Objects")
	Data.request_camera_shake(0.45)
	$AnimationPlayer.play("explode")


func hit(tool: Enum.Tool, dir = Vector2.ZERO):
	if not active or health <= 0:
		return
	if tool == Enum.Tool.SWORD:
		$FlashSprite2D.flash()
		push(dir)
		health -= 1
		Data.request_camera_shake(0.3)
		Data.spawn_floating_text("-1", global_position + Vector2(0, -12), Color(1.0, 0.35, 0.2))
		if has_node("AudioStreamPlayer2D"):
			$AudioStreamPlayer2D.pitch_scale = randf_range(1.2, 1.4)
			$AudioStreamPlayer2D.play()
