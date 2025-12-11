class_name ManagerFirebase
extends Node

# ==================================================================
# ---------------------------- AUTH --------------------------------
# ==================================================================

var current_user = null 
var test_email := "test@gmail.com"
var test_password := "password123"

func _ready():
	await get_tree().process_frame
	Firebase.Auth.login_succeeded.connect(_on_login_succeeded)
	Firebase.Auth.login_failed.connect(_on_login_failed)
	
	# Automatic login for testing
	login_with_email()


func login_with_email() -> void:
	Firebase.Auth.login_with_email_and_password(test_email, test_password)

func login_with_google():
	# automatic desktop OAuth login
	var port = 8060 # any free port
	Firebase.Auth.get_auth_localhost(Firebase.Auth.get_GoogleProvider(), port)

func _on_login_succeeded(user: Dictionary):
	print("LOGIN SUCCESS:", user)
	current_user = user
	ScreenMan.change_screen("menu")

func _on_login_failed(error_code, message):
	print("LOGIN FAILED:", error_code, message)

func logout_user():
	current_user = null
	Firebase.Auth.logout()

# ==================================================================
# ---------------------------- DATABASE ----------------------------
# ==================================================================

func write_to_db() -> void:
	#clone_doc("wave_standart_1", "wave_standart_2")
	var wave = _generate_wave(70)
	var waveDic = {}
	#print_debug(wave_1)
	var col: FirestoreCollection = Firebase.Firestore.collection('waves')
	var document = await col.add("wave_standart_6", wave)

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
	var document = await col.add(new, wave_doc)

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

func read_api_key() -> String:
	var key = ""
	var col: FirestoreCollection = Firebase.Firestore.collection('AI')
	var doc = await col.get_doc("api key")
	key = doc.get_value("key")
	#print_debug(key)
	return key
	
