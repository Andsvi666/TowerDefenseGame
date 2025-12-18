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
	#print_debug(waves_count)
	emit_signal("update_label", current_wave_index, name_label)
	

func start_next_wave() -> void:
	#print_debug(current_wave_index)
	if int(current_wave_index) >= int(waves_count):
		#Force gamer over
		HealthMan.take_damage(1000)
		return
	var wave_data = await FirebaseMan.read_wave_from_db(waves_type, String.num_int64(current_wave_index))
	#print_debug(wave_data)
	if wave_data.is_empty():
		#Force gamer over
		HealthMan.take_damage(1000)
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
