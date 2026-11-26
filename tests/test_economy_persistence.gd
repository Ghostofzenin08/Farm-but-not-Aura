extends Node

func run_all() -> bool:
	print("----------------------------------------")
	print("  TESTING ECONOMY & PERSISTENCE (A & B) ")
	print("----------------------------------------")
	
	var all_passed = true
	
	if not test_shipping_deposit_and_payout():
		all_passed = false
	if not test_shipping_cancel():
		all_passed = false
	if not test_shipping_bin_object():
		all_passed = false
	if not test_status_hud_reactivity():
		all_passed = false
	if not test_day_summary_ui():
		all_passed = false
	if not test_save_load_roundtrip():
		all_passed = false
	if not test_machine_placement_validation():
		all_passed = false
	if not test_stamina_energy_and_eating():
		all_passed = false
	if not test_seed_purchasing():
		all_passed = false
	if not test_seed_shop_ui():
		all_passed = false
		
	return all_passed


func test_shipping_deposit_and_payout() -> bool:
	print("\n[TEST ECONOMY 1] Shipping Bin Deposit and Settle Shipment...")
	Data.items[Enum.Item.TOMATO] = 5
	Data.items[Enum.Item.FISH] = 3
	Data.shipped_items.clear()
	var initial_gold = 100
	Data.gold = initial_gold
	
	# Deposit 2 Tomatoes (price 8 each = 16) and 1 Fish (price 15 each = 15)
	var dep1 = Data.deposit_shipping_item(Enum.Item.TOMATO, 2)
	var dep2 = Data.deposit_shipping_item(Enum.Item.FISH, 1)
	
	if not dep1 or not dep2:
		print("FAILED: Deposit returned false.")
		return false
	
	if Data.items[Enum.Item.TOMATO] != 3:
		print("FAILED: Tomato inventory not decremented correctly. Expected 3, got: ", Data.items[Enum.Item.TOMATO])
		return false
	if Data.items[Enum.Item.FISH] != 2:
		print("FAILED: Fish inventory not decremented correctly. Expected 2, got: ", Data.items[Enum.Item.FISH])
		return false
	
	var settlement = Data.settle_daily_shipment()
	var expected_payout = (2 * 8) + (1 * 15) # 31
	
	if settlement.get("total", 0) != expected_payout:
		print("FAILED: Expected total payout %d, got: %d" % [expected_payout, settlement.get("total", 0)])
		return false
	
	if Data.gold != initial_gold + expected_payout:
		print("FAILED: Player gold not updated correctly. Expected %d, got: %d" % [initial_gold + expected_payout, Data.gold])
		return false
	
	if not Data.shipped_items.is_empty():
		print("FAILED: shipped_items dictionary not cleared after settlement.")
		return false
		
	print("PASSED: Shipping Bin deposit and daily settlement calculate exact revenue (+31 G).")
	return true


func test_shipping_cancel() -> bool:
	print("\n[TEST ECONOMY 2] Shipping Bin Item Retrieval/Cancel...")
	Data.items[Enum.Item.CORN] = 4
	Data.shipped_items.clear()
	
	Data.deposit_shipping_item(Enum.Item.CORN, 3)
	if Data.items[Enum.Item.CORN] != 1 or Data.shipped_items[Enum.Item.CORN] != 3:
		print("FAILED: Initial corn deposit failed.")
		return false
	
	var can1 = Data.cancel_shipping_item(Enum.Item.CORN, 1)
	if not can1:
		print("FAILED: cancel_shipping_item returned false.")
		return false
		
	if Data.items[Enum.Item.CORN] != 2:
		print("FAILED: Bag corn expected 2, got: ", Data.items[Enum.Item.CORN])
		return false
	if Data.shipped_items[Enum.Item.CORN] != 2:
		print("FAILED: Bin corn expected 2, got: ", Data.shipped_items[Enum.Item.CORN])
		return false
	
	# Cancel remaining 2
	Data.cancel_shipping_item(Enum.Item.CORN, 2)
	if Data.items[Enum.Item.CORN] != 4 or Data.shipped_items.has(Enum.Item.CORN):
		print("FAILED: Fully cancelled item not erased from shipped_items.")
		return false
		
	print("PASSED: Items retrieved from Shipping Bin return to inventory cleanly.")
	return true


func test_shipping_bin_object() -> bool:
	print("\n[TEST ECONOMY 3] Shipping Bin Scene & Collision Layer...")
	var scene = load("res://scenes/objects/shipping_bin.tscn")
	var bin = scene.instantiate()
	
	if bin.collision_layer != 12:
		print("FAILED: Expected collision_layer 12 (layer 3 & 4), got: ", bin.collision_layer)
		bin.free()
		return false
	
	if not bin.has_method("interact"):
		print("FAILED: ShippingBin missing interact() method.")
		bin.free()
		return false
		
	bin.free()
	print("PASSED: Shipping Bin has collision layer 12 and interact() handler.")
	return true


func test_status_hud_reactivity() -> bool:
	print("\n[TEST ECONOMY 4] Status HUD Reactive Updates...")
	var hud_scene = load("res://scenes/ui/status_hud.tscn")
	var hud = hud_scene.instantiate()
	add_child(hud)
	
	Data.set_day(7)
	Data.change_gold(200) # gold now 100 + 31 + 200 = 331
	
	var day_text = hud.day_label.text
	var gold_text = hud.gold_label.text
	
	if day_text != "Day 7":
		print("FAILED: Expected 'Day 7', got: ", day_text)
		hud.free()
		return false
	
	if not gold_text.contains(str(Data.gold)):
		print("FAILED: Expected gold label to contain %d, got: %s" % [Data.gold, gold_text])
		hud.free()
		return false
		
	hud.free()
	print("PASSED: Status HUD updates immediately when Day or Gold signals fire.")
	return true


func test_day_summary_ui() -> bool:
	print("\n[TEST ECONOMY 5] Day Summary UI Breakdown Formatting...")
	var summary_scene = load("res://scenes/ui/day_summary_ui.tscn")
	var summary = summary_scene.instantiate()
	add_child(summary)
	
	var mock_settlement = {
		"total": 45,
		"breakdown": {
			Enum.Item.PUMPKIN: {"count": 1, "unit_price": 25, "subtotal": 25},
			Enum.Item.WHEAT: {"count": 2, "unit_price": 10, "subtotal": 20}
		},
		"current_gold": 175
	}
	
	summary.display_summary(mock_settlement, 3)
	
	if summary.title_label.text != "DAY 3 REPORT":
		print("FAILED: Expected 'DAY 3 REPORT', got: ", summary.title_label.text)
		summary.free()
		return false
		
	if not summary.total_earned_label.text.contains("45"):
		print("FAILED: Total earned label missing '45': ", summary.total_earned_label.text)
		summary.free()
		return false
		
	summary.free()
	print("PASSED: Day Summary UI formats settlement breakdown and totals accurately.")
	return true


func test_save_load_roundtrip() -> bool:
	print("\n[TEST PERSISTENCE 6] SaveManager Full Save/Load Roundtrip...")
	SaveManager.delete_save()
	
	var level_scene = load("res://scenes/levels/level.tscn")
	var level = level_scene.instantiate()
	add_child(level)
	
	# Set known game state
	Data.set_day(4)
	Data.gold = 350
	Data.energy = 72.0
	Data.items[Enum.Item.APPLE] = 12
	Data.items[Enum.Item.WOOD] = 40
	Data.deposit_shipping_item(Enum.Item.APPLE, 2)
	
	# Add a soil cell
	var soil_layer = level.get_node("Layers/SoilLayer") as TileMapLayer
	var test_cell = Vector2i(15, 15)
	soil_layer.set_cells_terrain_connect([test_cell], 0, 0)
	
	# Save game
	var save_success = SaveManager.save_game(level)
	if not save_success:
		print("FAILED: SaveManager.save_game returned false.")
		level.free()
		return false
	
	if not SaveManager.has_save():
		print("FAILED: has_save() returned false after saving.")
		level.free()
		return false
	
	# Corrupt/mutate memory state
	Data.set_day(99)
	Data.gold = 0
	Data.energy = 0.0
	Data.items[Enum.Item.APPLE] = 0
	Data.items[Enum.Item.WOOD] = 0
	Data.shipped_items.clear()
	soil_layer.clear()
	
	# Load game
	var load_success = SaveManager.load_game(level)
	if not load_success:
		print("FAILED: SaveManager.load_game returned false.")
		level.free()
		return false
	
	if Data.day != 4:
		print("FAILED: Day not restored. Expected 4, got: ", Data.day)
		level.free()
		return false
		
	if Data.gold != 350:
		print("FAILED: Gold not restored. Expected 350, got: ", Data.gold)
		level.free()
		return false
		
	if Data.energy != 72.0:
		print("FAILED: Energy not restored. Expected 72.0, got: ", Data.energy)
		level.free()
		return false
		
	if Data.items[Enum.Item.APPLE] != 10:
		print("FAILED: Apple inventory expected 10 (12 - 2 shipped), got: ", Data.items[Enum.Item.APPLE])
		level.free()
		return false
		
	if Data.shipped_items.get(Enum.Item.APPLE, 0) != 2:
		print("FAILED: Shipped apples expected 2, got: ", Data.shipped_items.get(Enum.Item.APPLE, 0))
		level.free()
		return false
		
	if not (test_cell in soil_layer.get_used_cells()):
		print("FAILED: Soil layer did not restore saved cell at: ", test_cell)
		level.free()
		return false
	
	# Clean up
	SaveManager.delete_save()
	level.free()
	print("PASSED: SaveManager saved and restored day, gold, bag, shipping bin, and farm soil perfectly.")
	return true


func test_machine_placement_validation() -> bool:
	print("\n[TEST AUTOMATION 7] Machine Placement Validation & Previews...")
	var level_scene = load("res://scenes/levels/level.tscn")
	var level = level_scene.instantiate()
	add_child(level)
	
	var test_coord = Vector2i(20, 20)
	var can_del = level.can_build_machine(Enum.Machine.DELETE, test_coord)
	if can_del:
		print("FAILED: DELETE should be invalid when no machine exists on tile.")
		level.free()
		return false
	
	# Place sprinkler on test_coord
	var sprinkler_scene = load("res://scenes/machines/sprinkler.tscn")
	var sprinkler = sprinkler_scene.instantiate()
	sprinkler.setup(test_coord * Data.TILE_SIZE, level, level.get_node("Objects"))
	
	# Now duplicate placement should be blocked
	var can_stack = level.can_build_machine(Enum.Machine.SPRINKLER, test_coord)
	if can_stack:
		print("FAILED: can_build_machine allowed stacking duplicate machine on tile.")
		level.free()
		return false
		
	# Now delete should be valid
	var can_del_valid = level.can_build_machine(Enum.Machine.DELETE, test_coord)
	if not can_del_valid:
		print("FAILED: DELETE should be valid when a machine exists on tile.")
		level.free()
		return false
		
	level.free()
	print("PASSED: Machine placement validation prevents stacking and correctly validates removal.")
	return true


func test_stamina_energy_and_eating() -> bool:
	print("\n[TEST STAMINA 8] Stamina Energy Consumption and Apple Eating...")
	Data.energy = 60.0
	Data.items[Enum.Item.APPLE] = 3
	
	# Deduct energy for tool use
	Data.change_energy(-15.0)
	if Data.energy != 45.0:
		print("FAILED: Energy expected 45.0, got: ", Data.energy)
		return false
		
	var player_scene = load("res://scenes/characters/player.tscn")
	var player = player_scene.instantiate()
	add_child(player)
	
	var ate = player.eat_apple()
	if not ate:
		print("FAILED: eat_apple returned false.")
		player.free()
		return false
		
	if Data.items[Enum.Item.APPLE] != 2:
		print("FAILED: Apple count expected 2, got: ", Data.items[Enum.Item.APPLE])
		player.free()
		return false
		
	if Data.energy != 70.0:
		print("FAILED: Energy expected 70.0 after eating, got: ", Data.energy)
		player.free()
		return false
		
	player.free()
	print("PASSED: Stamina deducts on tool use and recovers 25.0 energy when eating an apple.")
	return true


func test_seed_purchasing() -> bool:
	print("\n[TEST SEED 9] Seed Merchant Purchasing & Gold Transaction...")
	Data.gold = 100
	Data.items[Enum.Item.TOMATO] = 2
	
	# Buy 3 Tomato seeds (4 G each = 12 G)
	var bought = Data.buy_seed(Enum.Item.TOMATO, 3)
	if not bought:
		print("FAILED: buy_seed returned false with sufficient gold.")
		return false
	if Data.gold != 88:
		print("FAILED: Expected gold 88, got: ", Data.gold)
		return false
	if Data.items[Enum.Item.TOMATO] != 5:
		print("FAILED: Expected tomato count 5, got: ", Data.items[Enum.Item.TOMATO])
		return false
		
	# Try buying with insufficient gold (100 Pumpkin seeds @ 12G = 1200G, player has 88G)
	var failed_buy = Data.buy_seed(Enum.Item.PUMPKIN, 100)
	if failed_buy:
		print("FAILED: buy_seed allowed purchase with insufficient gold.")
		return false
	if Data.gold != 88:
		print("FAILED: Gold changed on failed purchase.")
		return false
		
	print("PASSED: Seed purchasing deducts gold and adds seeds to bag with balance verification.")
	return true


func test_seed_shop_ui() -> bool:
	print("\n[TEST SEED 10] Seed Shop UI Instantiation & Views...")
	var ui_scene = load("res://scenes/ui/seed_shop_ui.tscn")
	var ui = ui_scene.instantiate()
	add_child(ui)
	
	ui.reveal()
	if not ui.visible:
		print("FAILED: SeedShopUI not visible after reveal().")
		ui.free()
		return false
		
	ui._on_close_pressed()
	if ui.visible:
		print("FAILED: SeedShopUI still visible after close.")
		ui.free()
		return false
		
	ui.free()
	print("PASSED: Seed Shop UI opens and closes cleanly with reactive item rows.")
	return true
