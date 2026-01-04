class_name ManagerWaves
extends Node

var name_label: Label = null

var current_wave_index := 0
var waves_count := 0
var waves_type := "standart"
var is_spawning := false

#signal wave_ready
signal update_label(sum: int, name_label: Label)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func setup_waves(given_label: Label) -> void:
	name_label = given_label
	current_wave_index = 0
	is_spawning = false
	#print_debug("called")
	waves_count = await FirebaseMan.read_waves_count(waves_type)
	if GameMan.gamemode == "AI":
		waves_count = 99999999
	#print_debug(waves_count)
	emit_signal("update_label", current_wave_index, name_label)
	

func start_next_wave_standard() -> void:
	#print_debug(current_wave_index)
	if int(current_wave_index) >= int(waves_count):
		#Force gamer over
		HealthMan.take_damage(1000)
		GameMan.forced_by_error()
		return
	var wave_data = await FirebaseMan.read_wave_from_db(waves_type, String.num_int64(current_wave_index))
	print_debug(wave_data)
	if wave_data.is_empty():
		#Force gamer over
		HealthMan.take_damage(1000)
		GameMan.forced_by_error()
		return
	current_wave_index += 1
	#print_debug(current_wave_index)
	GameMan.wave_active = true
	emit_signal("update_label", current_wave_index, name_label)
	SpawnerMan.start_wave_coroutine(wave_data)

func start_next_wave_AI() -> void:
	var message = "AI starts generating wave %s" % (current_wave_index + 1)
	GameMan.log_event(message)
	FirebaseMan.user_update_AI(current_wave_index)
	#print_debug(current_wave_index)
	var budget = 50 + current_wave_index * 20
	var allowed_enemies = ["troop_tier_1", "tank_tier_1"]
	if current_wave_index >= 2:
		allowed_enemies = ["troop_tier_1", "troop_tier_2", "tank_tier_1"]
	if current_wave_index >= 4:
		allowed_enemies = ["troop_tier_1", "troop_tier_2", "tank_tier_1", "tank_tier_2"]
	if current_wave_index >= 6:
		allowed_enemies = ["troop_tier_1", "troop_tier_2", "tank_tier_1", "tank_tier_2", "plane_tier_1"]
	if current_wave_index >= 8:
		allowed_enemies = ["troop_tier_1", "troop_tier_2", "tank_tier_1", "tank_tier_2", "plane_tier_1", "plane_tier_2"]
	if current_wave_index >= 10:
		allowed_enemies = ["troop_tier_1", "troop_tier_2", "troop_tier_3", "tank_tier_1", "tank_tier_2", "tank_tier_3", "plane_tier_1", "plane_tier_2", "plane_tier_3"]
	#print_debug(allowed_types)
	var wave_data = await AiMan.generate_wave(budget, allowed_enemies)
	#print_debug(wave_data)
	if wave_data.is_empty():
		#Force gamer over
		HealthMan.take_damage(1000)
		GameMan.forced_by_error()
		return
	current_wave_index += 1
	#print_debug(current_wave_index)
	GameMan.wave_active = true
	emit_signal("update_label", current_wave_index, name_label)
	SpawnerMan.start_wave_coroutine(wave_data)

func read_next_wave() -> String:
	var wave = ""
	if int(current_wave_index) >= int(waves_count):
		return "No more waves"
	var wave_data = await FirebaseMan.read_wave_from_db(waves_type, String.num_int64(current_wave_index))
	if wave_data.is_empty():
		return "No more waves"
	for unit in wave_data:
		var tier := int(unit.get("tier_index", 0)) + 1
		var line := "%s, %d" % [
			unit.get("type", ""),
			tier,
		]
		wave += line + ", "
	return wave
