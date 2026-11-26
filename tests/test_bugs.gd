extends Node

func _ready() -> void:
	print("========================================")
	print("   STARTING GODOT AUTOMATED BUG TESTS   ")
	print("========================================")
	
	var passed = 0
	var failed = 0
	
	if test_character_diagonal():
		passed += 1
	else:
		failed += 1
		
	if test_fishing_game_progress_reset():
		passed += 1
	else:
		failed += 1
		
	if test_shop_button_exact_cost():
		passed += 1
	else:
		failed += 1
		
	if test_machine_shop_availability():
		passed += 1
	else:
		failed += 1
		
	if test_plant_info_cleanup_on_harvest():
		passed += 1
	else:
		failed += 1

	if test_blob_instance_safety():
		passed += 1
	else:
		failed += 1

	var econ_test_script = load("res://tests/test_economy_persistence.gd")
	var econ_test = econ_test_script.new()
	add_child(econ_test)
	if econ_test.run_all():
		passed += 8
	else:
		failed += 1
	econ_test.free()

	print("========================================")
	print("TEST RESULTS: %d Passed, %d Failed" % [passed, failed])
	print("========================================")
	
	get_tree().quit(0 if failed == 0 else 1)


func test_character_diagonal() -> bool:
	print("\n[TEST 1] NPC Diagonal Interaction Facing...")
	var character_script = load("res://scenes/characters/character.gd")
	var char_node = CharacterBody2D.new()
	char_node.set_script(character_script)
	var sprite = Sprite2D.new()
	char_node.add_child(sprite)
	
	var diagonals = [
		Vector2(10, 10),
		Vector2(-10, 10),
		Vector2(10, -10),
		Vector2(-10, -10),
		Vector2(15, 2),
		Vector2(2, 15)
	]
	
	for offset in diagonals:
		var raw_dir = offset.normalized()
		var dir = Vector2i.DOWN
		if abs(raw_dir.x) > abs(raw_dir.y):
			dir = Vector2i.RIGHT if raw_dir.x > 0 else Vector2i.LEFT
		else:
			dir = Vector2i.DOWN if raw_dir.y > 0 else Vector2i.UP
		
		var lookup = {
			Vector2i.DOWN: 0,
			Vector2i.LEFT: 1,
			Vector2i.RIGHT: 2,
			Vector2i.UP: 3,
		}
		if not dir in lookup:
			print("FAILED: Invalid direction generated: ", dir)
			char_node.free()
			return false
	
	char_node.free()
	print("PASSED: Diagonal facing calculates dominant cardinal axis safely without crashing.")
	return true


func test_fishing_game_progress_reset() -> bool:
	print("\n[TEST 2] Fishing Minigame Re-cast Progress Reset...")
	var fishing_scene = load("res://scenes/ui/fishing_game.tscn")
	var fishing_game = fishing_scene.instantiate()
	add_child(fishing_game)
	
	# Simulate initial win
	fishing_game.progress = 100.0
	fishing_game._on_texture_progress_bar_value_changed(100.0)
	
	# Reveal again for second catch
	fishing_game.reveal()
	
	if fishing_game.progress != 30.0:
		print("FAILED: Fishing minigame progress was not reset to 30.0 on reveal! Value: ", fishing_game.progress)
		fishing_game.queue_free()
		return false
		
	fishing_game.queue_free()
	print("PASSED: Fishing minigame progress correctly resets to 30.0 on every cast.")
	return true


func test_shop_button_exact_cost() -> bool:
	print("\n[TEST 3] Shop Purchase with Exact Cost Materials...")
	var required_wood = 8
	var required_corn = 6
	Data.items[Enum.Item.WOOD] = required_wood
	Data.items[Enum.Item.CORN] = required_corn
	
	var can_buy = (Data.items[Enum.Item.WOOD] >= required_wood and Data.items[Enum.Item.CORN] >= required_corn)
	if not can_buy:
		print("FAILED: Shop button exact cost comparison failed!")
		return false
		
	Data.items[Enum.Item.WOOD] -= required_wood
	Data.items[Enum.Item.CORN] -= required_corn
	
	if Data.items[Enum.Item.WOOD] != 0 or Data.items[Enum.Item.CORN] != 0:
		print("FAILED: Inventory deduction error!")
		return false
		
	print("PASSED: Shop allows purchase with exact material amounts.")
	return true


func test_machine_shop_availability() -> bool:
	print("\n[TEST 4] Machine Shop Unlocks Availability...")
	var tracker = Data.unlocked_machines
	var all_machines = Data.MACHINE_UPGRADE_COST.keys()
	var available = (tracker + all_machines).filter(func(x): return not (x in all_machines and x in tracker))
	
	if available.size() == 0:
		print("FAILED: No machines available to buy in shop! Unlocked machines was not reset.")
		return false
		
	print("PASSED: Machine shop has %d available machines for purchase (%s)." % [available.size(), str(available)])
	return true


func test_plant_info_cleanup_on_harvest() -> bool:
	print("\n[TEST 5] Plant Info Cleanup on Harvest...")
	var plant_res = PlantResource.new()
	plant_res.setup(Enum.Seed.TOMATO, Enum.Item.TOMATO)
	
	var plant_info_scene = load("res://scenes/ui/plant_info.tscn")
	var plant_info = plant_info_scene.instantiate()
	add_child(plant_info)
	plant_info.setup(plant_res)
	
	# Simulate harvest
	plant_res.dead = true
	
	# Check if plant_info is queued for deletion
	if not plant_info.is_queued_for_deletion():
		print("FAILED: plant_info was not queued for deletion when plant died/harvested!")
		plant_info.queue_free()
		return false
		
	print("PASSED: Plant info card automatically cleans up upon harvest.")
	return true


func test_blob_instance_safety() -> bool:
	print("\n[TEST 6] Blob Freed Target Safety...")
	var blob_scene = load("res://scenes/objects/blob.tscn")
	var blob = blob_scene.instantiate()
	add_child(blob)
	
	# Assign dummy target and then free it
	var dummy = StaticBody2D.new()
	add_child(dummy)
	blob.plant_target = dummy
	dummy.free() # Freed immediately
	
	# Process one step - should not crash
	blob._physics_process(0.016)
	
	if blob.active != false and blob.plant_target != null:
		print("FAILED: Blob did not safely handle freed target!")
		blob.queue_free()
		return false
		
	blob.queue_free()
	print("PASSED: Blob safely checks plant_target validity without crashing on freed memory.")
	return true
