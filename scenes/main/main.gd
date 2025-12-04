class_name Main
extends Node2D
@onready var spawner_man: ManagerSpawner = $GameCanvas/TileMapSubViewport/SubViewport/ManagerSpawner

func _ready() -> void:
	WavesMan.connect("wave_ready", Callable(spawner_man, "_on_wave_ready"))
	GameMan.setup_fresh_game()
