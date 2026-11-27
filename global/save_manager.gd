extends Node

const SAVE_PATH: String = "user://savegame.json"

signal game_saved
signal game_loaded

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)


func save_game(level: Node2D) -> bool:
	if not is_instance_valid(level):
		return false
	
	var save_dict: Dictionary = {
		"version": 1,
		"timestamp": Time.get_datetime_string_from_system(),
		"data": {
			"day": Data.day,
			"gold": Data.gold,
			"energy": Data.energy,
			"max_energy": Data.max_energy,
			"tutorial_step": Data.tutorial_step,
			"tutorial_completed": Data.tutorial_completed,
			"forecast_rain": Data.forecast_rain,
			"unlocked_styles": Data.unlocked_styles.duplicate(),
			"unlocked_machines": Data.unlocked_machines.duplicate(),
			"items": {},
			"shipped_items": {}
		},
		"player": {},
		"farm": {
			"soil_cells": [],
			"watered_cells": [],
			"plants": [],
			"machines": []
		}
	}
	
	# Serialize inventory items
	for item_key in Data.items.keys():
		save_dict["data"]["items"][str(int(item_key))] = Data.items[item_key]
	
	# Serialize pending shipped items
	for ship_key in Data.shipped_items.keys():
		save_dict["data"]["shipped_items"][str(int(ship_key))] = Data.shipped_items[ship_key]
	
	# Serialize player state
	var player = level.get_node_or_null("Objects/Player")
	if is_instance_valid(player):
		save_dict["player"] = {
			"pos_x": player.position.x,
			"pos_y": player.position.y,
			"current_tool": int(player.current_tool),
			"current_seed": int(player.current_seed),
			"current_style": int(player.current_style),
			"current_style_index": int(player.current_style_index)
		}
	
	# Serialize Soil tiles
	var soil_layer = level.get_node_or_null("Layers/SoilLayer") as TileMapLayer
	if soil_layer:
		for cell in soil_layer.get_used_cells():
			save_dict["farm"]["soil_cells"].append([cell.x, cell.y])
	
	# Serialize Watered Soil tiles
	var water_layer = level.get_node_or_null("Layers/SoilWaterLayer") as TileMapLayer
	if water_layer:
		for cell in water_layer.get_used_cells():
			save_dict["farm"]["watered_cells"].append([cell.x, cell.y])
	
	# Serialize Plants
	for plant in level.get_tree().get_nodes_in_group("Plants"):
		if is_instance_valid(plant) and is_instance_valid(plant.res) and not plant.res.dead:
			save_dict["farm"]["plants"].append({
				"coord": [plant.coord.x, plant.coord.y],
				"age": plant.res.age,
				"death_count": plant.res.death_count,
				"grow_speed": plant.res.grow_speed,
				"h_frames": plant.res.h_frames,
				"death_max": plant.res.death_max,
				"name": plant.res.name,
				"reward": int(plant.res.reward),
				"texture": plant.res.texture.resource_path if plant.res.texture else "",
				"icon_texture": plant.res.icon_texture.resource_path if plant.res.icon_texture else ""
			})
	
	# Serialize Machines
	for machine in level.get_tree().get_nodes_in_group("Machines"):
		if is_instance_valid(machine):
			var m_type = -1
			if machine.scene_file_path.contains("sprinkler"):
				m_type = int(Enum.Machine.SPRINKLER)
			elif machine.scene_file_path.contains("fisher"):
				m_type = int(Enum.Machine.FISHER)
			elif machine.scene_file_path.contains("scare_crow"):
				m_type = int(Enum.Machine.SCARECROW)
			if m_type != -1:
				save_dict["farm"]["machines"].append({
					"type": m_type,
					"pos_x": machine.position.x,
					"pos_y": machine.position.y,
					"coord": [machine.coord.x, machine.coord.y]
				})
	
	# Write JSON file
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("Failed to write save file at " + SAVE_PATH)
		return false
	
	var json_str = JSON.stringify(save_dict, "\t")
	file.store_string(json_str)
	file.close()
	game_saved.emit()
	print("[SaveManager] Game state saved successfully to: ", SAVE_PATH)
	return true


func load_game(level: Node2D) -> bool:
	if not has_save() or not is_instance_valid(level):
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	
	var content = file.get_as_text()
	file.close()
	
	var test_json = JSON.new()
	if test_json.parse(content) != OK:
		push_error("[SaveManager] Error parsing save game JSON.")
		return false
	
	var save_dict: Dictionary = test_json.data
	
	# Restore Data singleton state
	var g_data = save_dict.get("data", {})
	Data.set_day(int(g_data.get("day", 1)))
	Data.gold = int(g_data.get("gold", 50))
	Data.gold_changed.emit(Data.gold)
	Data.energy = float(g_data.get("energy", 100.0))
	Data.max_energy = float(g_data.get("max_energy", 100.0))
	Data.energy_changed.emit(Data.energy, Data.max_energy)
	Data.tutorial_step = int(g_data.get("tutorial_step", 0))
	Data.tutorial_completed = bool(g_data.get("tutorial_completed", false))
	Data.forecast_rain = bool(g_data.get("forecast_rain", false))
	
	if g_data.has("unlocked_styles"):
		Data.unlocked_styles.clear()
		for s in g_data["unlocked_styles"]:
			Data.unlocked_styles.append(int(s))
			
	if g_data.has("unlocked_machines"):
		Data.unlocked_machines.clear()
		for m in g_data["unlocked_machines"]:
			Data.unlocked_machines.append(int(m))
	
	# Restore inventory
	if g_data.has("items"):
		for item_str in g_data["items"].keys():
			var item_id = int(item_str)
			Data.items[item_id] = int(g_data["items"][item_str])
	
	# Restore shipped items
	Data.shipped_items.clear()
	if g_data.has("shipped_items"):
		for ship_str in g_data["shipped_items"].keys():
			Data.shipped_items[int(ship_str)] = int(g_data["shipped_items"][ship_str])
	
	# Restore Player
	var p_data = save_dict.get("player", {})
	var player = level.get_node_or_null("Objects/Player")
	if is_instance_valid(player) and not p_data.is_empty():
		player.position = Vector2(p_data.get("pos_x", player.position.x), p_data.get("pos_y", player.position.y))
		player.current_tool = int(p_data.get("current_tool", 0)) as Enum.Tool
		player.current_seed = int(p_data.get("current_seed", 0)) as Enum.Seed
		player.current_style = int(p_data.get("current_style", 0)) as Enum.Style
		player.current_style_index = int(p_data.get("current_style_index", 0))
		if Data.PLAYER_SKINS.has(player.current_style):
			player.get_node("Sprite2D").texture = Data.PLAYER_SKINS[player.current_style]
	
	# Restore Soil
	var farm_data = save_dict.get("farm", {})
	var soil_layer = level.get_node_or_null("Layers/SoilLayer") as TileMapLayer
	if soil_layer and farm_data.has("soil_cells"):
		soil_layer.clear()
		var soil_cells: Array[Vector2i] = []
		for pair in farm_data["soil_cells"]:
			soil_cells.append(Vector2i(int(pair[0]), int(pair[1])))
		if soil_cells.size() > 0:
			soil_layer.set_cells_terrain_connect(soil_cells, 0, 0)
	
	# Restore Watered soil
	var water_layer = level.get_node_or_null("Layers/SoilWaterLayer") as TileMapLayer
	if water_layer and farm_data.has("watered_cells"):
		water_layer.clear()
		for pair in farm_data["watered_cells"]:
			water_layer.set_cell(Vector2i(int(pair[0]), int(pair[1])), 0, Vector2i(randi_range(0, 2), 0))
	
	# Clear existing plants and plant info
	for plant in level.get_tree().get_nodes_in_group("Plants"):
		plant.queue_free()
	level.used_cells.clear()
	
	var info_container = level.get_node_or_null("Overlay/CanvasLayer/PlantInfoContainer")
	if info_container:
		for child in info_container.get_children():
			child.queue_free()
	
	# Restore Plants
	var plant_scene = load("res://scenes/objects/plant.tscn")
	var plant_info_scene = load("res://scenes/ui/plant_info.tscn")
	var objects_parent = level.get_node_or_null("Objects")
	
	if farm_data.has("plants") and objects_parent:
		for p_info in farm_data["plants"]:
			var coord = Vector2i(int(p_info["coord"][0]), int(p_info["coord"][1]))
			var plant_res = PlantResource.new()
			plant_res.age = float(p_info.get("age", 0.0))
			plant_res.death_count = int(p_info.get("death_count", 0))
			plant_res.grow_speed = float(p_info.get("grow_speed", 1.0))
			plant_res.h_frames = int(p_info.get("h_frames", 3))
			plant_res.death_max = int(p_info.get("death_max", 3))
			plant_res.name = str(p_info.get("name", "Crop"))
			plant_res.reward = int(p_info.get("reward", 0)) as Enum.Item
			if p_info.get("texture", "") != "":
				plant_res.texture = load(p_info["texture"])
			if p_info.get("icon_texture", "") != "":
				plant_res.icon_texture = load(p_info["icon_texture"])
			
			var plant = plant_scene.instantiate()
			plant.setup(coord, objects_parent, plant_res, level.plant_death)
			plant.get_node("FlashSprite2D").frame = int(plant_res.age)
			level.used_cells.append(coord)
			
			if plant_info_scene and info_container:
				var plant_info = plant_info_scene.instantiate()
				plant_info.setup(plant_res)
				info_container.add(plant_info)
	
	# Restore Machines
	for machine in level.get_tree().get_nodes_in_group("Machines"):
		machine.queue_free()
	
	if farm_data.has("machines") and objects_parent:
		for m_info in farm_data["machines"]:
			var m_type = int(m_info["type"]) as Enum.Machine
			if level.machine_scenes.has(m_type):
				var machine = level.machine_scenes[m_type].instantiate()
				var m_pos = Vector2i(int(m_info["pos_x"]), int(m_info["pos_y"]))
				machine.setup(m_pos, level, objects_parent)
	
	game_loaded.emit()
	print("[SaveManager] Game state loaded successfully.")
	return true
