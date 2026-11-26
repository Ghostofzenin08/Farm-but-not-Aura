class_name Machine extends StaticBody2D

var coord: Vector2i

func setup(pos: Vector2i, _level: Node2D, parent: Node2D):
	coord = Vector2i(floor(float(pos.x) / Data.TILE_SIZE), floor(float(pos.y) / Data.TILE_SIZE))
	position = pos
	parent.add_child(self)


func delete(delete_coord):
	if coord == delete_coord:
		queue_free()
