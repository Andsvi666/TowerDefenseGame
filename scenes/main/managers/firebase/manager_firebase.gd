class_name ManagerFirebase
extends Node

# ==================================================================
# ---------------------------- AUTH --------------------------------
# ==================================================================

var current_user = null 
var current_user_standard_completion = false
var current_user_endless_completion = false
var current_user_doc = null
var users_collection = null

var test_email := "test@gmail.com"
var test_password := "password123"

func _ready():
	await get_tree().process_frame
	Firebase.Auth.login_succeeded.connect(_on_login_succeeded)
	Firebase.Auth.login_failed.connect(_on_login_failed)

func login_with_test_user() -> void:
	Firebase.Auth.login_with_email_and_password(test_email, test_password)

func login_with_google() -> void:
	# automatic desktop OAuth login
	var port = 8060 # any free port
	Firebase.Auth.get_auth_localhost(Firebase.Auth.get_GoogleProvider(), port)

func _on_login_succeeded(user: Dictionary):
	#print("LOGIN SUCCESS:", user)
	current_user = user
	users_collection = Firebase.Firestore.collection('users')
	if current_user.has("isnewuser"):
		setup_new_user()
	else:
		var uid = current_user["localid"]
		#print_debug(uid)
		current_user_doc = await users_collection.get_doc(uid)
		#print_debug(current_user_doc)
	ScreenMan.change_screen("menu")

func _on_login_failed(error_code, message) -> void:
	print("LOGIN FAILED:", error_code, message)

func logout_user() -> void:
	current_user = null
	Firebase.Auth.logout()

# ==================================================================
# ---------------------------- DATABASE USER------------------------
# ==================================================================

func setup_new_user() -> void:
	#print_debug(current_user)
	var user_stats = {
		"name" : current_user["fullname"],
		"beat_standard": false,
		"beat_endless": false,
		"total_games_played": 0,
		"total_towers_built": 0,
		"total_enemies_killed": 0,
		"highest_AI_wave": 0,
		"longest_endless_time": 0
	}
	
	var uid = current_user["localid"]
	await users_collection.add(uid, user_stats)
	current_user_doc = await users_collection.get_doc(uid)

func read_user_stats() -> Dictionary:
	var stats = {}
	if current_user_doc == null or current_user_doc.keys() == null:
		push_warning("User stats not found")
		return stats
	
	var keys = current_user_doc.keys()
	#print_debug(keys)
	
	for key in keys:
		stats[key] = current_user_doc.get_value(key)
	if stats["beat_standard"]:
		current_user_standard_completion = true
	else:
		current_user_standard_completion = false
	if stats["beat_endless"]:
		current_user_endless_completion = true
	else:
		current_user_endless_completion = false
	return stats

func user_add_tower() -> void:
	var count = current_user_doc.get_value("total_towers_built")
	count = count + 1
	current_user_doc["total_towers_built"] = count
	await users_collection.update(current_user_doc)

func user_add_enemy() -> void:
	var count = current_user_doc.get_value("total_enemies_killed")
	count = count + 1
	current_user_doc["total_enemies_killed"] = count
	await users_collection.update(current_user_doc)

func user_add_game() -> void:
	var count = current_user_doc.get_value("total_games_played")
	count = count + 1
	current_user_doc["total_games_played"] = count
	await users_collection.update(current_user_doc)

func user_beat_standard() -> void:
	current_user_doc["beat_standard"] = true
	current_user_standard_completion = true
	await users_collection.update(current_user_doc)

func user_beat_endless() -> void:
	current_user_doc["beat_endless"] = true
	current_user_endless_completion = true
	await users_collection.update(current_user_doc)

func user_update_endless(new: int) -> void:
	var current = current_user_doc.get_value("longest_endless_time")
	if new > current:
		current_user_doc["longest_endless_time"] = new
		await users_collection.update(current_user_doc)

func user_update_AI(new: int) -> void:
	var current = current_user_doc.get_value("highest_AI_wave")
	if new > current:
		current_user_doc["highest_AI_wave"] = new
		await users_collection.update(current_user_doc)

# ==================================================================
# ---------------------------- DATABASE WAVES-----------------------
# ==================================================================

func write_to_db() -> void:
	#clone_doc("wave_standart_1", "wave_standart_2")
	var wave = _generate_wave(70)
	var waveDic = {}
	#print_debug(wave_1)
	var col: FirestoreCollection = Firebase.Firestore.collection('waves')
	await col.add("wave_standart_6", wave)

func clone_doc(origin: String, new: String) -> void:
	var wave_doc := {}
	var i = 0
	var col: FirestoreCollection = Firebase.Firestore.collection('waves')
	var doc = await col.get_doc(origin)
	var units = doc.keys()
	#print_debug(units)
	# sort numerically based on the number after "enemy_"
	units.sort_custom(func(a, b) -> bool:
		var a_index = int(a.replace("enemy_", ""))
		var b_index = int(b.replace("enemy_", ""))
		return a_index < b_index  # return true if a comes before b
	)
	print_debug(units)
	for unit in units:
		var key = "enemy_%04d" % (i + 1)
		print_debug(key)
		var unit_data = doc.get_value(unit)
		wave_doc[key] = [
			unit_data[0],
			unit_data[1],
			unit_data[2]
		]
		i = i + 1
	await col.add(new, wave_doc)

func _generate_wave(count: int) -> Dictionary:
	var wave_doc := {}

	for i in range(count):
		# zero-pad to 4 digits
		var key = "enemy_%04d" % (i + 1)
		wave_doc[key] = [
			0,       # type
			0,       # tier
			1.0      # delay
		]
	
	return wave_doc

func read_waves_count(type: String) -> int:
	var col: FirestoreCollection = Firebase.Firestore.collection('waves')
	var doc = await col.get_doc("counts")
	#print_debug(doc)
	
	#print_debug(doc.keys())
	if doc == null or doc.keys() == null:
		return 0
	
	# build the key, e.g., "standart_count"
	var key = type + "_count"
	
	if doc.is_null_value(key):
		return 0
	
	# extract the integerValue
	var value = doc.get_value(key)
	
	# Check if it has integerValue
	if typeof(value) != TYPE_INT:
		return 0
	
	#print_debug(value)
	
	return value

func read_wave_from_db(type: String, index: String) -> Array:
	var wave = []
	var col: FirestoreCollection = Firebase.Firestore.collection('waves')
	var doc_name = "wave_" + type + "_" + index
	#print_debug(doc_name)
	var doc = await col.get_doc(doc_name)
	
	if doc == null or doc.keys() == null:
		return wave
	
	var units = doc.keys()
	#print_debug(units)
	# sort numerically based on the number after "enemy_"
	units.sort_custom(func(a, b) -> bool:
		var a_index = int(a.replace("enemy_", ""))
		var b_index = int(b.replace("enemy_", ""))
		return a_index < b_index  # return true if a comes before b
	)
	#print_debug(units) 
	
	for unit in units:
		var unit_data = doc.get_value(unit)
		var enemyType = ""
		if unit_data[0] == 0:
			enemyType = "TroopEnemy"
		elif unit_data[0] == 1:
			enemyType = "TankEnemy"
		elif unit_data[0] == 2:
			enemyType = "PlaneEnemy"
		wave.append({
			"type": enemyType,
			"tier_index": int(unit_data[1]),
			"spawn_delay": float(unit_data[2])
		})
	
	return wave

func parse_wave_data(firestore_data: Dictionary) -> Array:
	var enemies := []
	
	# Extract keys like "enemy_0", "enemy_1", ...
	var keys := firestore_data.keys()
	keys.sort_custom(func(a, b):
		var a_index = int(a.replace("enemy_", ""))
		var b_index = int(b.replace("enemy_", ""))
		return a_index - b_index
	)
	
	for key in keys:
		var arr = firestore_data[key]["arrayValue"]["values"]
		enemies.append({
			"type": arr[0]["stringValue"],
			"tier_index": int(arr[1]["integerValue"]),
			"spawn_delay": float(arr[2]["doubleValue"])
		})
	
	return enemies

func read_api_key(doc_name: String) -> String:
	var key = ""
	var col: FirestoreCollection = Firebase.Firestore.collection('AI')
	var doc = await col.get_doc(doc_name)
	key = doc.get_value("key")
	#print_debug(key)
	return key
	
