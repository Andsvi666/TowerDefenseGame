class_name ManagerWaves
extends Node

@onready var name_label: Label = get_node("/root/Main/UIRoot/TopBar/WaveLabel")

# --- Wave datasets ---
var wave_1 := []
var wave_2 := []
var wave_3 := []

var waves := []
var current_wave_index := 0
var is_spawning := false

signal wave_ready
signal update_label(sum: int, name_label: Label)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_generate_waves()

func setup_waves() -> void:
	name_label = get_node_or_null("/root/Main/UIRoot/TopBar/WaveLabel")
	current_wave_index = 0
	is_spawning = false
	emit_signal("update_label", current_wave_index, name_label)

func start_next_wave() -> void:
	if current_wave_index >= waves.size():
		print("No more waves")
		return
	
	var wave_data = waves[current_wave_index]
	current_wave_index += 1
	#print_debug(current_wave_index)
	GameMan.wave_active = false
	emit_signal("update_label", current_wave_index, name_label)
	emit_signal("wave_ready", wave_data)

func _generate_waves() -> void:
	# --- Wave 1: 20 random troops ---
	var wave_length = 5
	for i in range(wave_length):
		var tier = clamp(i / 7, 0, 2)
		var delay = 3.0 - (i * 0.1)
		
		# Last enemy has 0 spawn delay
		if i == wave_length - 1:  # last index
			delay = 0.0
		else:
			delay = max(0.2, delay)
		
		wave_1.append({
			"type": "TroopEnemy",
			"tier_index": int(tier),
			"spawn_delay": delay
		})

	# --- Wave 2: troops + tanks ---
	# First 5 troops
	for i in range(5):
		wave_2.append({"type": "TroopEnemy", "tier_index": 0, "spawn_delay": 1.0})

	# 30 troops and 30 tanks interleaved
	for i in range(30):
		var tier_troop = clamp(i / 15, 0, 2)
		var tier_tank = clamp(i / 20, 0, 3)
		wave_2.append({"type": "TroopEnemy", "tier_index": int(tier_troop), "spawn_delay": 0.8})
		wave_2.append({"type": "TankEnemy", "tier_index": int(tier_tank), "spawn_delay": 1.2})

	# End of wave: only tanks
	for i in range(10):
		var tier = clamp(i / 5, 0, 3)
		wave_2.append({"type": "TankEnemy", "tier_index": int(tier), "spawn_delay": 1.0})
		
	waves = [wave_1, wave_2, wave_3]
