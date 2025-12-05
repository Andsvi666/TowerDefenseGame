class_name ManagerFirebase
extends Node

# ==================================================================
# ---------------------------- AUTH --------------------------------
# ==================================================================

signal login_success
var current_user = null 

func _ready():
	# connect signals
	await get_tree().process_frame
	Firebase.Auth.login_succeeded.connect(_on_login_ok)
	Firebase.Auth.login_failed.connect(_on_login_fail)

	# start login
	var email = "test@gmail.com"
	var password = "123456789"
	Firebase.Auth.login_with_email_and_password(email, password)

	print("Trying to log in...")
	

func _on_login_ok(auth):
	print("LOGIN SUCCESS!")
	current_user = auth
	emit_signal("login_success", auth)
	#print(auth) # contains user info
	# now Firestore works

func _on_login_fail(code, msg):
	print("LOGIN FAILED:", code, msg)

func is_logged_in() -> bool:
	return current_user != null

# ==================================================================
# ---------------------------- DATABASE ----------------------------
# ==================================================================

func write_to_db() -> void:
	var wave = _generate_wave(40)
	#print_debug(wave_1)
	var collection: FirestoreCollection = Firebase.Firestore.collection('waves')
	var document = await collection.add("wave_standart_2", wave)

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
