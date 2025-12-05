class_name Main
extends Node2D
@onready var spawner_man: ManagerSpawner = $GameCanvas/TileMapSubViewport/SubViewport/ManagerSpawner

func _ready() -> void:
	if FirebaseMan.is_logged_in():
		_on_login_success(FirebaseMan.current_user)
	else:
		FirebaseMan.connect("login_success", Callable(self, "_on_login_success"))

func _on_login_success(auth):
	#print_debug("game starts")
	WavesMan.connect("wave_ready", Callable(spawner_man, "_on_wave_ready"))
	GameMan.setup_fresh_game()
