extends StaticBody2D

var coord: Vector2i
@export var res: PlantResource
signal death(coord: Vector2i)

func setup(grid_coord: Vector2i, parent: Node2D, new_res: PlantResource, plant_death_func):
	position = grid_coord * Data.TILE_SIZE + Vector2i(8,5)
	parent.add_child(self)
	coord = grid_coord
	res = new_res
	$FlashSprite2D.texture = res.texture
	death.connect(plant_death_func)
	res.connect("changed", update)


func update():
	if res.death_count >= res.death_max:
		death.emit(coord)
		res.dead = true
		queue_free()


func grow(watered: bool):	
	if watered:
		res.grow($FlashSprite2D)
	else:
		res.decay(self)


func _on_collision_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	if res.get_complete() and not res.dead:
		res.dead = true
		var harvest_qty = randi_range(2, 4)
		Data.change_item(res.reward, harvest_qty)
		var item_name = Enum.Item.keys()[res.reward].capitalize()
		Data.spawn_floating_text("+%d %s" % [harvest_qty, item_name], global_position + Vector2(0, -12), Color(0.3, 0.95, 0.4))
		Data.request_camera_shake(0.15)
		death.emit(coord)
		$FlashSprite2D.flash(0.2, 0.4, queue_free)


func damage():
	res.damage()
