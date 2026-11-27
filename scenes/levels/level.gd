extends Node2D

var plant_scene = preload("res://scenes/objects/plant.tscn")
var plant_info_scene = preload("res://scenes/ui/plant_info.tscn")
var floating_text_scene = preload("res://scenes/ui/floating_text.tscn")
var projectile_scene = preload("res://scenes/machines/projectile.tscn")
var blob_scene = preload("res://scenes/objects/blob.tscn")
var machine_scenes = {
	Enum.Machine.SPRINKLER: preload("res://scenes/machines/sprinkler.tscn"),
	Enum.Machine.SCARECROW: preload("res://scenes/machines/scare_crow.tscn"),
	Enum.Machine.FISHER: preload("res://scenes/machines/fisher.tscn")}
var used_cells: Array[Vector2i]
var raining: bool:
	set(value):
		raining = value
		$Layers/RainFloorParticles.emitting = value
		$Overlay/RainDropsParticles.emitting = value
		$Music/Rain.playing = value
@onready var player = $Objects/Player
@onready var day_transition_material = $Overlay/CanvasLayer/DayTransitionLayer.material
@export var daytime_color: Gradient
@export var rain_color: Color
@export var volume_curve: Curve

const MACHINE_PREVIEW_TEXTURES = {
	Enum.Machine.SPRINKLER: {'texture':preload("res://graphics/icons/sprinkler.png"), 'offset': Vector2i(0,0)},
	Enum.Machine.FISHER: {'texture':preload("res://graphics/icons/fisher.png"), 'offset': Vector2i(0,-4)},
	Enum.Machine.SCARECROW: {'texture':preload("res://graphics/icons/scarecrow.png"), 'offset': Vector2i(0,-4)},
	Enum.Machine.DELETE: {'texture':preload("res://graphics/icons/delete.png"), 'offset': Vector2i(0,0)}}


func _on_player_tool_use(tool: Enum.Tool, pos: Vector2) -> void:
	var grid_coord: Vector2i = Vector2i(floor(pos.x / float(Data.TILE_SIZE)), floor(pos.y / float(Data.TILE_SIZE)))
	var has_soil = grid_coord in $Layers/SoilLayer.get_used_cells()
	match tool:
		Enum.Tool.HOE:
			var cell = $Layers/GrassLayer.get_cell_tile_data(grid_coord) as TileData
			if cell and cell.get_custom_data('farmable'):
				$Layers/SoilLayer.set_cells_terrain_connect([grid_coord], 0, 0)
				Data.request_camera_shake(0.12)
				Data.spawn_floating_text("Tilled", Vector2(grid_coord * Data.TILE_SIZE) + Vector2(8, 8), Color(0.8, 0.7, 0.4))
				if Data.tutorial_step == 2:
					Data.advance_tutorial(2)
			if raining:
				$Layers/SoilWaterLayer.set_cell(grid_coord, 0, Vector2i(randi_range(0,2),0))
		Enum.Tool.WATER:
			if has_soil:
				$Layers/SoilWaterLayer.set_cell(grid_coord, 0, Vector2i(randi_range(0,2),0))
				Data.request_camera_shake(0.08)
				Data.spawn_floating_text("Watered", Vector2(grid_coord * Data.TILE_SIZE) + Vector2(8, 8), Color(0.35, 0.8, 1.0))
				if Data.tutorial_step == 3:
					Data.advance_tutorial(3)
		Enum.Tool.FISH:
			if not grid_coord in $Layers/GrassLayer.get_used_cells():
				$Objects/Player.start_fishing()
		Enum.Tool.SEED:
			if has_soil and grid_coord not in used_cells:
				var selected_item = {
					Enum.Seed.TOMATO: Enum.Item.TOMATO,
					Enum.Seed.WHEAT: Enum.Item.WHEAT,
					Enum.Seed.CORN: Enum.Item.CORN,
					Enum.Seed.PUMPKIN: Enum.Item.PUMPKIN,
				}[player.current_seed]
				
				if Data.items[selected_item] > 0:
					Data.change_item(selected_item, -1)
					var plant_res = PlantResource.new()
					plant_res.setup($Objects/Player.current_seed, selected_item)
					var plant = plant_scene.instantiate()
					plant.setup(grid_coord, $Objects, plant_res, plant_death)
					used_cells.append(grid_coord)
					Data.request_camera_shake(0.1)
					Data.spawn_floating_text("Planted", Vector2(grid_coord * Data.TILE_SIZE) + Vector2(8, 8), Color(0.5, 0.95, 0.35))
					
					var plant_info = plant_info_scene.instantiate()
					plant_info.setup(plant_res)
					$Overlay/CanvasLayer/PlantInfoContainer.add(plant_info)
					if Data.tutorial_step == 4:
						Data.advance_tutorial(4)
				
		Enum.Tool.AXE, Enum.Tool.SWORD:
			for object in get_tree().get_nodes_in_group('Objects'):
				if is_instance_valid(object) and object.position.distance_to(pos) < 20:
					if object.has_method("hit"):
						object.hit(tool)


func _on_player_diagnose() -> void:
	$Overlay/CanvasLayer/PlantInfoContainer.visible = not $Overlay/CanvasLayer/PlantInfoContainer.visible


func _on_player_day_change() -> void:
	day_restart()


func can_build_machine(m_type: int, tile: Vector2i) -> bool:
	if m_type == Enum.Machine.DELETE:
		for machine in get_tree().get_nodes_in_group('Machines'):
			if is_instance_valid(machine) and machine.get("coord") == tile:
				return true
		return false
	
	for existing in get_tree().get_nodes_in_group('Machines'):
		if is_instance_valid(existing) and existing.get("coord") == tile:
			return false
	
	var grass_layer = $Layers/GrassLayer as TileMapLayer
	if not grass_layer:
		return false
	var tile_data = grass_layer.get_cell_tile_data(tile) as TileData
	
	match m_type:
		Enum.Machine.FISHER:
			return tile_data != null and tile_data.get_custom_data('coast') != null and tile_data.get_custom_data('coast') != Vector2i.ZERO
		Enum.Machine.SPRINKLER, Enum.Machine.SCARECROW:
			if not tile_data:
				return false
			var water_layer = $Layers/WaterLayer as TileMapLayer
			if water_layer and water_layer.get_cell_tile_data(tile) != null:
				return false
			return true
	return false


func _on_player_build(current_machine: int) -> void:
	var machine_pos = player.get_machine_coord()
	var machine_tile = Vector2i(floor(float(machine_pos.x) / Data.TILE_SIZE), floor(float(machine_pos.y) / Data.TILE_SIZE))
	if not can_build_machine(current_machine, machine_tile):
		return
	if current_machine != Enum.Machine.DELETE:
		var machine = machine_scenes[current_machine].instantiate()
		machine.setup(machine_pos, self, $Objects)
	else:
		for machine in get_tree().get_nodes_in_group('Machines'):
			if is_instance_valid(machine):
				machine.delete(machine_tile)


func _on_player_machine_change(current_machine: int) -> void:
	$Overlay/MachinePreviewSprite.texture = MACHINE_PREVIEW_TEXTURES[current_machine]['texture']


func _on_player_close_shop() -> void:
	$Overlay/CanvasLayer/ShopUI.hide()
	player.current_state = Enum.State.DEFAULT


func open_shipping_bin() -> void:
	if Data.tutorial_step == 6:
		Data.advance_tutorial(6)
	var shipping_ui = $Overlay/CanvasLayer.get_node_or_null("ShippingBinUI")
	if shipping_ui:
		shipping_ui.reveal()
		player.current_state = Enum.State.SHOP


func _on_shipping_bin_close() -> void:
	var shipping_ui = $Overlay/CanvasLayer.get_node_or_null("ShippingBinUI")
	if shipping_ui:
		shipping_ui.hide()
	player.current_state = Enum.State.DEFAULT


func _ready() -> void:
	$Timers/DayTimer.timeout.connect(day_restart)
	if SaveManager.has_save():
		SaveManager.load_game(self)
	else:
		Data.forecast_rain = [true, false].pick_random()
	for character in get_tree().get_nodes_in_group('Characters'):
		character.connect('open_shop', open_shop)
	
	var shipping_bin = $Objects.get_node_or_null("ShippingBin")
	if shipping_bin and not shipping_bin.open_shipping_bin.is_connected(open_shipping_bin):
		shipping_bin.open_shipping_bin.connect(open_shipping_bin)
	
	var seed_ui = $Overlay/CanvasLayer.get_node_or_null("SeedShopUI")
	if seed_ui and not seed_ui.close.is_connected(_on_seed_shop_close):
		seed_ui.close.connect(_on_seed_shop_close)
	
	player.help_requested.connect(open_tutorial_guide)
	var guide_ui = $Overlay/CanvasLayer.get_node_or_null("TutorialGuideUI")
	if guide_ui and not guide_ui.close.is_connected(_on_tutorial_guide_close):
		guide_ui.close.connect(_on_tutorial_guide_close)
	var quest_hud = $Overlay/CanvasLayer.get_node_or_null("TutorialQuestHUD")
	if quest_hud and not quest_hud.guide_requested.is_connected(open_tutorial_guide):
		quest_hud.guide_requested.connect(open_tutorial_guide)
	var status_hud = $Overlay/CanvasLayer.get_node_or_null("StatusHUD")
	if status_hud and not status_hud.guide_requested.is_connected(open_tutorial_guide):
		status_hud.guide_requested.connect(open_tutorial_guide)
	Data.floating_text_requested.connect(_on_floating_text_requested)


func _process(_delta: float) -> void:
	var daytime_point = 1 - ($Timers/DayTimer.time_left / $Timers/DayTimer.wait_time)
	var color = daytime_color.sample(daytime_point).lerp(rain_color, 0.5 if raining else 0.0)
	$Music/BGMusic.volume_db = volume_curve.sample(daytime_point)
	$Overlay/DayTimeColor.color = color
	
	# machine preview 
	var is_building = player.current_state == Enum.State.BUILDING
	$Overlay/MachinePreviewSprite.visible = is_building
	if is_building:
		var machine_pos = player.get_machine_coord()
		var machine_tile = Vector2i(floor(float(machine_pos.x) / Data.TILE_SIZE), floor(float(machine_pos.y) / Data.TILE_SIZE))
		$Overlay/MachinePreviewSprite.position = machine_pos + MACHINE_PREVIEW_TEXTURES[player.current_machine]['offset']
		var is_valid = can_build_machine(player.current_machine, machine_tile)
		$Overlay/MachinePreviewSprite.modulate = Color(0.4, 1.0, 0.4, 0.85) if is_valid else Color(1.0, 0.3, 0.3, 0.85)
	
	# tile cursor highlight
	var show_tile_cursor = player.current_state == Enum.State.DEFAULT and player.current_tool in [Enum.Tool.HOE, Enum.Tool.WATER, Enum.Tool.SEED]
	var tile_cursor = $Overlay.get_node_or_null("TileCursor")
	if tile_cursor:
		tile_cursor.visible = show_tile_cursor
		if show_tile_cursor:
			var target_pos = player.position + player.last_direction.normalized() * 16.0
			var target_tile = Vector2i(floor(target_pos.x / 16.0), floor(target_pos.y / 16.0))
			tile_cursor.position = Vector2(target_tile * 16)
			
			var grass_cell = $Layers/GrassLayer.get_cell_tile_data(target_tile)
			var has_target_soil = target_tile in $Layers/SoilLayer.get_used_cells()
			var has_target_water = target_tile in $Layers/SoilWaterLayer.get_used_cells()
			
			match player.current_tool:
				Enum.Tool.HOE:
					if grass_cell and grass_cell.get_custom_data('farmable') and not has_target_soil:
						tile_cursor.set_cursor_style(Color(0.4, 0.95, 0.4, 0.8), Color(0.3, 0.9, 0.3, 0.2))
					else:
						tile_cursor.set_cursor_style(Color(0.9, 0.9, 0.9, 0.5), Color(1.0, 1.0, 1.0, 0.1))
				Enum.Tool.WATER:
					if has_target_soil and not has_target_water:
						tile_cursor.set_cursor_style(Color(0.3, 0.75, 1.0, 0.85), Color(0.2, 0.6, 1.0, 0.25))
					else:
						tile_cursor.set_cursor_style(Color(0.5, 0.7, 0.9, 0.5), Color(0.4, 0.6, 0.9, 0.1))
				Enum.Tool.SEED:
					var has_plant = target_tile in used_cells
					if has_target_soil and not has_plant:
						tile_cursor.set_cursor_style(Color(0.95, 0.85, 0.3, 0.85), Color(0.9, 0.8, 0.2, 0.2))
					else:
						tile_cursor.set_cursor_style(Color(0.8, 0.8, 0.8, 0.4), Color(0.8, 0.8, 0.8, 0.1))

func day_restart():
	var tween = create_tween()
	tween.tween_property(day_transition_material, "shader_parameter/progress", 1.0, 1.0)
	await tween.finished
	
	var settlement = Data.settle_daily_shipment()
	if Data.tutorial_step == 7:
		Data.advance_tutorial(7)
	Data.set_day(Data.day + 1)
	level_reset()
	SaveManager.save_game(self)
	
	if settlement.get("total", 0) > 0:
		Data.spawn_floating_text("+%d G Earned!" % settlement.get("total", 0), player.position + Vector2(0, -25), Color(0.95, 0.85, 0.2))
		var summary = $Overlay/CanvasLayer.get_node_or_null("DaySummaryUI")
		if summary:
			player.current_state = Enum.State.SHOP
			summary.display_summary(settlement, Data.day)
			await summary.confirmed
			player.current_state = Enum.State.DEFAULT
	
	var fade_in = create_tween()
	fade_in.tween_property(day_transition_material, "shader_parameter/progress", 0.0, 1.0)


func level_reset():
	Data.change_energy(Data.max_energy)
	for plant in get_tree().get_nodes_in_group('Plants'):
		plant.grow(plant.coord in $Layers/SoilWaterLayer.get_used_cells())
	$Layers/SoilWaterLayer.clear()
	$Overlay/CanvasLayer/PlantInfoContainer.update_all()
	
	$Timers/DayTimer.start()
	for blob in get_tree().get_nodes_in_group('Blobs'):
		if is_instance_valid(blob):
			blob.queue_free()
	for object in get_tree().get_nodes_in_group('Objects'):
		if is_instance_valid(object) and 'reset' in object:
			object.reset()

	raining = Data.forecast_rain
	Data.forecast_rain = [true, false].pick_random()
	
	if raining:
		for cell in $Layers/SoilLayer.get_used_cells():
			$Layers/SoilWaterLayer.set_cell(cell, 0, Vector2i(randi_range(0,2),0))


func plant_death(coord: Vector2i):
	used_cells.erase(coord)


func create_projectile(start_pos: Vector2, dir: Vector2):
	var projectile = projectile_scene.instantiate()
	projectile.setup(start_pos, dir)
	$Objects.add_child(projectile)


func water_plants(coord: Vector2i):
	const SOIL_DIRECTIONS = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1,  0),Vector2i(1,0), Vector2i(-1,  1), 
		Vector2i(0,  1), Vector2i(1,  1)]
	for dir in SOIL_DIRECTIONS:
		var cell = coord + dir
		if cell in $Layers/SoilLayer.get_used_cells():
			$Layers/SoilWaterLayer.set_cell(cell, 0, Vector2i(randi_range(0,2),0))


func _on_blob_timer_timeout() -> void:
	var plants = get_tree().get_nodes_in_group('Plants')
	if plants:
		var blob = blob_scene.instantiate()
		var pos = $BlobSpawnPositions.get_children().pick_random().position
		blob.setup(pos, plants.pick_random(), $Objects)


func open_shop(shop_type: Enum.Shop):
	if shop_type == Enum.Shop.SEED:
		open_seed_shop()
	else:
		$Overlay/CanvasLayer/ShopUI.reveal(shop_type)
		player.current_state = Enum.State.SHOP


func open_seed_shop():
	var seed_ui = $Overlay/CanvasLayer.get_node_or_null("SeedShopUI")
	if seed_ui:
		seed_ui.reveal()
		player.current_state = Enum.State.SHOP


func _on_seed_shop_close():
	var seed_ui = $Overlay/CanvasLayer.get_node_or_null("SeedShopUI")
	if seed_ui:
		seed_ui.hide()
	player.current_state = Enum.State.DEFAULT


func open_tutorial_guide():
	var guide_ui = $Overlay/CanvasLayer.get_node_or_null("TutorialGuideUI")
	if guide_ui:
		guide_ui.reveal()
		player.current_state = Enum.State.SHOP


func _on_tutorial_guide_close():
	var guide_ui = $Overlay/CanvasLayer.get_node_or_null("TutorialGuideUI")
	if guide_ui:
		guide_ui.hide()
	player.current_state = Enum.State.DEFAULT


func _on_floating_text_requested(text: String, world_pos: Vector2, color: Color) -> void:
	var ft = floating_text_scene.instantiate()
	ft.setup(text, world_pos, color)
	$Overlay.add_child(ft)
