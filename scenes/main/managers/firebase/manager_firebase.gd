class_name ManagerFirebase
extends Node

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
	#print(auth) # contains user info
	# now Firestore works

func _on_login_fail(code, msg):
	print("LOGIN FAILED:", code, msg)

func write_to_db() -> void:
	var collection: FirestoreCollection = Firebase.Firestore.collection('test')
	var document = await collection.get_doc('testing')
	print(document)

func _generate_wave_1() -> Array:
	var wave := []
	for i in range(10):
		var tier = clamp(i / 5, 0, 2)  # tier 0, 1, 2
		var delay = max(0.2, 3.0 - (i * 0.1))
		if i == 9:
			delay = 0.0  # last enemy
		wave.append({
			"type": "TroopEnemy",
			"tier_index": int(tier),
			"spawn_delay": delay
		})
	return wave
