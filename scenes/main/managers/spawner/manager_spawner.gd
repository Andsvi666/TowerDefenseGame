class_name ManagerSpawner
extends Node

@export var enemy_types: Dictionary = {
	"TroopEnemy": {
		"scene": preload("res://scenes/main/enemy/troop/enemy_troop.tscn"),
		"tiers": [
			preload("res://scenes/main/enemy/troop/tiers/troop_tier_1.tres"),
			preload("res://scenes/main/enemy/troop/tiers/troop_tier_2.tres"),
			preload("res://scenes/main/enemy/troop/tiers/troop_tier_3.tres")
		]
	},
	"TankEnemy": {
		"scene": preload("res://scenes/main/enemy/tank/enemy_tank.tscn"),
		"tiers": [
			preload("res://scenes/main/enemy/tank/tiers/tank_tier_1.tres"),
			preload("res://scenes/main/enemy/tank/tiers/tank_tier_2.tres"),
			preload("res://scenes/main/enemy/tank/tiers/tank_tier_3.tres")
		]
	},
	"PlaneEnemy": {
		"scene": preload("res://scenes/main/enemy/plane/enemy_plane.tscn"),
		"tiers": [
			preload("res://scenes/main/enemy/plane/tiers/plane_tier_1.tres"),
			preload("res://scenes/main/enemy/plane/tiers/plane_tier_2.tres"),
			preload("res://scenes/main/enemy/plane/tiers/plane_tier_3.tres")
		]
	}
}

var endless_mode_enabled: bool = false 
var wave_mode_enabled: bool = false 
var base_spawn_delay: float = 1.0 
var spawn_point: Marker2D = null

var elapsed_time: float = 0.0 
var timer_count: float = 2.0
var wave_data_array: Array = [] 
var current_data_index: int = 0
var is_spawning_wave: bool = false

signal wave_complete
var active_enemies: Array = []

# Setup function to inject the TileMap and Endpoint
func setup_map(spawnPoint: Marker2D) -> void:
	# Inject spawn point
	spawn_point = spawnPoint

	# --- Reset spawner state for a fresh game ---
	is_spawning_wave = false
	wave_data_array.clear()
	current_data_index = 0
	active_enemies.clear()

func _process(delta: float) -> void:
	if endless_mode_enabled:
		elapsed_time += delta
		if elapsed_time >= timer_count:
			timer_count += base_spawn_delay
			spawn_random_enemy()
	elif wave_mode_enabled and is_spawning_wave:
		# wave mode handled separately via coroutines (see below)
		pass

func _on_wave_ready(wave_array: Array) -> void:
	#print_debug(wave_array)
	start_wave_coroutine(wave_array)

func start_wave_coroutine(wave_array: Array) -> void:
	if not wave_array or wave_array.is_empty():
		print_debug("Wave is empty")
		return
	
	wave_mode_enabled = true
	endless_mode_enabled = false
	wave_data_array = wave_array
	current_data_index = 0
	is_spawning_wave = true
	
	spawn_next_wave_enemy()  # spawn_next_wave_enemy uses await internally

func spawn_next_wave_enemy() -> void:
	if current_data_index >= wave_data_array.size():
		is_spawning_wave = false
		#print_debug("Wave complete")
		return
	
	var wave_data = wave_data_array[current_data_index]
	current_data_index += 1
	
	var enemy_type_name = wave_data["type"]
	if not enemy_types.has(enemy_type_name):
		push_error("Enemy type '%s' not found!" % enemy_type_name)
		return
	
	var enemy_info = enemy_types[enemy_type_name]
	var enemy_scene: PackedScene = enemy_info["scene"]
	var enemy = enemy_scene.instantiate()
	
	if wave_data.has("tier_index"):
		var index = wave_data["tier_index"]
		if index >= 0 and index < enemy_info["tiers"].size():
			enemy.stats = enemy_info["tiers"][index]
	
	if spawn_point:
		enemy.global_position = spawn_point.global_position
		spawn_point.get_parent().add_child(enemy)  # ensures enemy is in the same canvas/layer as towers
	
	# 	track enemy
	active_enemies.append(enemy)
	
	if not enemy.is_connected("enemy_died", Callable(self, "_on_enemy_died")):
		enemy.connect("enemy_died", Callable(self, "_on_enemy_died"))
	
	# spawn next enemy after its delay
	var delay = wave_data["spawn_delay"] if wave_data.has("spawn_delay") else base_spawn_delay
	await get_tree().create_timer(delay, false).timeout
	#print_debug("wait ended")
	spawn_next_wave_enemy()

func _on_enemy_died(enemy_node: Node) -> void:
	active_enemies.erase(enemy_node)
	# Only emit wave_complete when all enemies are gone and wave finished spawning
	if not is_spawning_wave and active_enemies.is_empty():
		emit_signal("wave_complete")

func spawn_random_enemy() -> void:
	var allowed_types: Array = []
	# gradually unlock enemy types
	allowed_types = ["TroopEnemy", "TankEnemy", "PlaneEnemy"]
	
	var enemy_type_name = allowed_types.pick_random()
	var enemy_info = enemy_types[enemy_type_name]
	var enemy_scene: PackedScene = enemy_info["scene"]
	var enemy = enemy_scene.instantiate()
	
	# tier scaling
	var available_tiers = 1
	if elapsed_time > 45:  # unlock tier 2 after 45s
		available_tiers = 2
	if elapsed_time > 120: # unlock tier 3 after 120s
		available_tiers = min(3, enemy_info["tiers"].size())
	
	var tier_index = randi_range(0, available_tiers - 1)
	enemy.stats = enemy_info["tiers"][tier_index]
	
	# --- print_debug for enemy group ---
	#print_debug("Spawned ", enemy.name, " | Group: ", enemy.enemy_group, " | Tier: ", tier_index)
	
	# set position
	if spawn_point:
		#print_debug(spawn_point.global_position)
		enemy.global_position = spawn_point.global_position
		get_parent().add_child(enemy)
	else:
		pass
	
