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

var spawn_point: Marker2D = null
signal update_log

#Waves modes
var wave_data_array: Array = [] 
var is_spawning_wave: bool = false

#Endless mode
var endless_spawn_timer: Timer
var endless_time_timer: Timer
var endless_elapsed_time := 0
signal endless_time_updated(seconds: int)
signal endless_started

signal wave_complete
var active_enemies: Array = []

func _ready() -> void:
	#setup timer for spawning
	endless_spawn_timer = Timer.new()
	endless_spawn_timer.wait_time = 2.0
	endless_spawn_timer.autostart = false
	endless_spawn_timer.one_shot = false
	add_child(endless_spawn_timer)
	endless_spawn_timer.timeout.connect(_spawn_endless_enemy)

	#setup timer for endless game time tracking
	endless_time_timer = Timer.new()
	endless_time_timer.wait_time = 1.0
	endless_time_timer.autostart = false
	endless_time_timer.one_shot = false
	add_child(endless_time_timer)
	endless_time_timer.timeout.connect(_tick_endless_time)

# Setup function to inject the TileMap and Endpoint
func setup_map(spawnPoint: Marker2D) -> void:
	stop_current_wave()
	reset_endless()
	# Inject spawn point
	spawn_point = spawnPoint

func stop_current_wave() -> void:
	is_spawning_wave = false
	wave_data_array.clear()
	active_enemies.clear()

func reset_endless() -> void:
	# Stop timers if running
	if endless_spawn_timer:
		endless_spawn_timer.stop()
	if endless_time_timer:
		endless_time_timer.stop()

	# Reset elapsed time counter
	endless_elapsed_time = 0

	# Clear any active enemies if you want a clean slate
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	active_enemies.clear()

# ==================================================================
# ---------------------------- ENDLESS -----------------------
# ==================================================================


func start_endless_mode() -> void:
	if GameMan.gamemode != "endless":
		return
	GameMan.wave_active = true
	emit_signal("endless_started")
	endless_elapsed_time = 0
	endless_spawn_timer.start()
	endless_time_timer.start()


func stop_endless_mode() -> void:
	endless_spawn_timer.stop()
	endless_time_timer.stop()

func _spawn_endless_enemy() -> void:
	if GameMan.gamemode != "endless":
		return

	spawn_next_enemy("TroopEnemy", 0)

func _tick_endless_time() -> void:
	if GameMan.gamemode != "endless":
		return

	endless_elapsed_time += 1
	emit_signal("endless_time_updated", endless_elapsed_time)

# ==================================================================
# ---------------------------- WAVES -----------------------
# ==================================================================


func start_wave_coroutine(wave_array: Array) -> void:
	if not wave_array or wave_array.is_empty():
		print_debug("Wave is empty")
		return
	
	wave_data_array = wave_array
	is_spawning_wave = true
	
	#print_debug(wave_data_array)
	
	for unit in wave_array:
		var delay = unit["spawn_delay"]
		spawn_next_enemy(unit["type"], unit["tier_index"])
		await get_tree().create_timer(delay, false).timeout
	
	is_spawning_wave = false

func spawn_next_enemy(enemy_type_name: String, tier_index: int) -> void:
	if not enemy_types.has(enemy_type_name):
		push_error("Enemy type '%s' not found!" % enemy_type_name)
		return

	var enemy_info = enemy_types[enemy_type_name]
	var enemy_scene: PackedScene = enemy_info["scene"]
	var enemy = enemy_scene.instantiate()

	if tier_index >= 0 and tier_index < enemy_info["tiers"].size():
		enemy.stats = enemy_info["tiers"][tier_index]

	if spawn_point:
		enemy.global_position = spawn_point.global_position
		spawn_point.get_parent().add_child(enemy)

	# Track enemy
	active_enemies.append(enemy)
	
	if not GameMan.gamemode == "standard":
		var message = "Enemy tier %s %s spawned" % [enemy["tier"], enemy["group"]]
		GameMan.log_event(message)

	if not enemy.is_connected("enemy_died", Callable(self, "_on_enemy_died")):
		enemy.connect("enemy_died", Callable(self, "_on_enemy_died"))


func _on_enemy_died(enemy_node: Node) -> void:
	active_enemies.erase(enemy_node)
	# Only emit wave_complete when all enemies are gone and wave finished spawning
	if not is_spawning_wave and active_enemies.is_empty() and not GameMan.gamemode == "endless":
		emit_signal("wave_complete")
