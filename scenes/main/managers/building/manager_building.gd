class_name ManagerBuilding
extends Node

var hover_panel: Panel = null
var tile_map_layer: TileMapLayer = null
var tile_map_overlay: TileMapLayer = null

const IS_BUILDABLE: String = "buildable"
const TOWER_GROUP: String = "TOWER_GROUP"

# --- Data tracking ---
var used_tiles: Array[Vector2i] = []                  # where towers are built
var towers_by_cell: Dictionary = {}                   # cell_position → tower_node

# --- Tower scenes ---
var turret_tower_scene: PackedScene = preload("res://scenes/main/tower/turret/tower_turret.tscn")
var cannon_tower_scene: PackedScene = preload("res://scenes/main/tower/cannon/tower_cannon.tscn")
var missile_tower_scene: PackedScene = preload("res://scenes/main/tower/missile/tower_missile.tscn")
var support_tower_scene: PackedScene = preload("res://scenes/main/tower/support/tower_support.tscn")

# --- Base tiers ---
var turret_tier: TowerStats = preload("res://scenes/main/tower/turret/tiers/turret_tier_1.tres")
var cannon_tier: TowerStats = preload("res://scenes/main/tower/cannon/tiers/cannon_tier_1.tres")
var missile_tier: TowerStats = preload("res://scenes/main/tower/missile/tiers/missile_tier_1.tres")
var support_tier: TowerStats = preload("res://scenes/main/tower/support/tiers/support_tier_1.tres")

# --- Upgrade tiers ---
var turret_upgrade_tier: TowerStats = preload("res://scenes/main/tower/turret/tiers/turret_tier_2.tres")
var cannon_upgrade_tier: TowerStats = preload("res://scenes/main/tower/cannon/tiers/cannon_tier_2.tres")
var missile_upgrade_tier: TowerStats = preload("res://scenes/main/tower/missile/tiers/missile_tier_2.tres")
var support_upgrade_tier: TowerStats = preload("res://scenes/main/tower/support/tiers/support_tier_2.tres")

# --- Atlas references (for tilemap lookup) ---
const TURRET_ATLAS = Vector2i(15, 1)
const CANNON_ATLAS = Vector2i(17, 1)
const MISSILE_ATLAS = Vector2i(18, 1)
const SUPPORT_ATLAS = Vector2i(16, 1)

# Setup function to inject the TileMap and Overlay
func setup_map(tilemap: TileMapLayer, overlay: TileMapLayer, given_panel: Panel) -> void:
	tile_map_layer = tilemap
	tile_map_overlay = overlay
	hover_panel = given_panel
	reset_towers()

func reset_towers():
	for tower in towers_by_cell.values():
		if is_instance_valid(tower):
			tower.queue_free()

	# Clear tracking arrays
	towers_by_cell.clear()
	used_tiles.clear()

	# Optional: reset available tiles in GameMan
	GameMan.available_tiles_for_towers = {
		"turret_tiles": 18,
		"cannon_tiles": 17,
		"missile_tiles": 9,
		"support_tiles": 7,
	}

	# Optional: reset built towers counts
	GameMan.built_towers = {
		"turret_tier_1": 0, "turret_tier_2": 0,
		"cannon_tier_1": 0, "cannon_tier_2": 0,
		"missile_tier_1": 0, "missile_tier_2": 0,
		"support_tier_1": 0, "support_tier_2": 0
	}

# ==================================================================
# ---------------------------- PROCESS ------------------------------
# ==================================================================
func _process(_delta: float) -> void:
	if tile_map_layer == null:
		return

	var local_mouse_pos = tile_map_layer.get_local_mouse_position()
	var cell = tile_map_layer.local_to_map(local_mouse_pos)

	# --- 1. Hover over existing tower: show "Upgrade" ---
	if towers_by_cell.has(cell):
		var tower: TowerBase = towers_by_cell[cell]
		display_panel_info(tower, "Upgrade", "")
		return

	# --- 2. Hover over buildable tile: show "Build" ---
	var tile_data = tile_map_layer.get_cell_tile_data(cell)
	if tile_data == null or not tile_data.get_custom_data(IS_BUILDABLE):
		hover_panel.visible = false
		return

	var atlas_coords = tile_map_layer.get_cell_atlas_coords(cell)

	match atlas_coords:
		TURRET_ATLAS:
			display_panel_info(null, "Build", "turret")
		CANNON_ATLAS:
			display_panel_info(null, "Build", "cannon")
		MISSILE_ATLAS:
			display_panel_info(null, "Build", "missile")
		SUPPORT_ATLAS:
			display_panel_info(null, "Build", "support")
		_:
			#if mouse is pointing to non building tile
			hover_panel.visible = false

func display_panel_info(tower: TowerBase, type: String, tower_name: String) -> void:
	#print_debug(type)
	var tower_name_set = ""
	var title = hover_panel.get_node_or_null("LabelTitle")
	var info = hover_panel.get_node_or_null("LabelInfo")
	var price = hover_panel.get_node_or_null("LabelPrice")
	if tower == null:
		tower_name_set = tower_name
	else:
		tower_name_set = tower.stats.tower_name
		if tower.upgraded:
			type = ""
			price.text = "Tower is fully upgraded"
	hover_panel.visible = true
	hover_panel.global_position = get_mouse_ui_pos()  + Vector2(-90, -70)
	if tower_name_set == "turret":
		title.text = type + " Turret Tower"
		info.text = "Tower only attacks troop units"
		if type == "Upgrade":
			price.text = "Upgrade price: " + String.num_int64(turret_upgrade_tier.build_cost) + " coins"
		if type == "Build":
			price.text = "Build price: 	" + String.num_int64(turret_tier.build_cost) + " coins"
	if tower_name_set == "cannon":
		title.text = type + " Cannon Tower"
		info.text = "Tower only attacks tank units"
		if type == "Upgrade":
			price.text = "Upgrade price: " +String.num_int64(cannon_upgrade_tier.build_cost) + " coins"
		if type == "Build":
			price.text =  "Build price: 	" + String.num_int64(cannon_tier.build_cost) + " coins"
	if tower_name_set == "missile":
		title.text = type + " Missile Tower"
		info.text = "Tower only attacks plane units"
		if type == "Upgrade":
			price.text = "Upgrade price: " + String.num_int64(missile_upgrade_tier.build_cost) + " coins"
		if type == "Build":
			price.text =  "Build price: " + String.num_int64(missile_tier.build_cost) + " coins"
	if tower_name_set == "support":
		title.text = type + " Support Tower"
		info.text = "Tower heals base and generates coins"
		if type == "Upgrade":
			price.text = "Upgrade price: " + String.num_int64(support_upgrade_tier.build_cost) + " coins"
		if type == "Build":
			price.text =  "Build price: 	"+ String.num_int64(support_tier.build_cost) + " coins"


# ==================================================================
# ------------------------- INPUT HANDLING --------------------------
# ==================================================================
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		#print_debug("clicked")
		if tile_map_layer == null:
			return
	
		var local_mouse_pos: Vector2 = tile_map_layer.get_local_mouse_position()
		var cell: Vector2i = tile_map_layer.local_to_map(local_mouse_pos)
		handle_tile_click(cell)

func handle_tile_click(cell_position: Vector2i) -> void:
	#print_debug(cell_position)
	# --- 1. Upgrade case ---
	if towers_by_cell.has(cell_position):
		var tower: TowerBase = towers_by_cell[cell_position]
		if tower.upgraded:
			return # already upgraded once
		upgrade_tower(tower)
		return

	# --- 2. Build case ---
	if not check_valid_tower_placement(cell_position):
		return
	var result = get_tower_for_tile(cell_position)
	if result.is_empty():
		return

	var tower_scene = result["scene"]
	var tower_stats = result["stats"]
	place_tower(cell_position, tower_scene, tower_stats)

# ==================================================================
# --------------------------- BUILDING ------------------------------
# ==================================================================
func get_tower_for_tile(cell_position: Vector2i) -> Dictionary:
	var tile_data = tile_map_layer.get_cell_tile_data(cell_position)
	if tile_data == null:
		return {}
	
	var atlas_coords: Vector2i = tile_map_layer.get_cell_atlas_coords(cell_position)
	match atlas_coords:
		TURRET_ATLAS:
			return {"scene": turret_tower_scene, "stats": turret_tier, "upgrade": turret_upgrade_tier}
		CANNON_ATLAS:
			return {"scene": cannon_tower_scene, "stats": cannon_tier, "upgrade": cannon_upgrade_tier}
		MISSILE_ATLAS:
			return {"scene": missile_tower_scene, "stats": missile_tier, "upgrade": missile_upgrade_tier}
		SUPPORT_ATLAS:
			return {"scene": support_tower_scene, "stats": support_tier, "upgrade": support_upgrade_tier}
		_:
			return {}


func place_tower(cell_position: Vector2i, tower_scene: PackedScene, tower_stats: TowerStats) -> void:
	if tower_scene == null or tower_stats == null:
		return

	# Check if player can afford to build
	if not CoinsMan.spend_coins(tower_stats.build_cost):
		GameMan.show_floating_message("Not enough coins to build " + tower_stats.tower_name + " tower!")
		return

	replace_tile_with_base(cell_position)

	var tower: TowerBase = tower_scene.instantiate()
	tower.z_index = 10
	tile_map_layer.add_child(tower)  # place under TileMap/SubViewport
	tower.position = (cell_position * tile_map_layer.tile_set.tile_size) + (tile_map_layer.tile_set.tile_size / 2)
	tower.stats = tower_stats
	tower.apply_stats()
	tower.add_to_group(TOWER_GROUP)

	# Track which cell has a tower
	used_tiles.append(cell_position)
	towers_by_cell[cell_position] = tower
	
	FirebaseMan.user_add_tower()
	
	# Update Game Manager counts
	if tower_stats.tower_name == "turret":
		GameMan.built_towers["turret_tier_1"] += 1
		GameMan.available_tiles_for_towers["turret_tiles"] -= 1
	elif tower_stats.tower_name == "cannon":
		GameMan.built_towers["cannon_tier_1"] += 1
		GameMan.available_tiles_for_towers["cannon_tiles"] -= 1
	elif tower_stats.tower_name == "missile":
		GameMan.built_towers["missile_tier_1"] += 1
		GameMan.available_tiles_for_towers["missile_tiles"] -= 1
	elif tower_stats.tower_name == "support":
		GameMan.built_towers["support_tier_1"] += 1
		GameMan.available_tiles_for_towers["support_tiles"] -= 1


# ==================================================================
# --------------------------- UPGRADING -----------------------------
# ==================================================================
func upgrade_tower(tower: TowerBase) -> void:
	var tower_name = tower.stats.tower_name.to_lower()
	var new_stats: TowerStats = null

	match tower_name:
		"turret":
			new_stats = turret_upgrade_tier
		"cannon":
			new_stats = cannon_upgrade_tier
		"missile":
			new_stats = missile_upgrade_tier
		"support":
			new_stats = support_upgrade_tier

	if new_stats == null:
		return

	if not CoinsMan.spend_coins(new_stats.build_cost):
		GameMan.show_floating_message("Not enough coins to upgrade " + tower_name + " tower!")
		#print_debug("Not enough coins to upgrade " + tower_name)
		return

	# Update GameMan counts BEFORE applying new stats
	match tower_name:
		"turret":
			GameMan.built_towers["turret_tier_1"] -= 1
			GameMan.built_towers["turret_tier_2"] += 1
		"cannon":
			GameMan.built_towers["cannon_tier_1"] -= 1
			GameMan.built_towers["cannon_tier_2"] += 1
		"missile":
			GameMan.built_towers["missile_tier_1"] -= 1
			GameMan.built_towers["missile_tier_2"] += 1
		"support":
			GameMan.built_towers["support_tier_1"] -= 1
			GameMan.built_towers["support_tier_2"] += 1

	tower.stats = new_stats
	tower.upgraded = true
	tower.apply_stats()

	#print_debug(tower_name + " upgraded successfully!")

# ==================================================================
# ------------------------- TILE HANDLING ---------------------------
# ==================================================================
func replace_tile_with_base(cell_position: Vector2i) -> void:
	if tile_map_layer == null or tile_map_overlay == null:
		return
	
	var grass_atlas = Vector2i(1, 10)
	var base_atlas = Vector2i(20, 7)
	
	# Clear existing tiles first
	tile_map_layer.set_cell(cell_position, -1)
	tile_map_overlay.set_cell(cell_position, -1)
	
	tile_map_layer.set_cell(cell_position, 0, grass_atlas, 0)
	tile_map_overlay.set_cell(cell_position, 0, base_atlas, 0)

func check_valid_tower_placement(cell_position: Vector2i) -> bool:
	if used_tiles.has(cell_position):
		return false
	if tile_map_layer == null:
		return false	
	var cell_data = tile_map_layer.get_cell_tile_data(cell_position)
	if cell_data == null:
		return false
	return cell_data.get_custom_data(IS_BUILDABLE)

func get_mouse_ui_pos() -> Vector2:
	return get_tree().root.get_mouse_position()
