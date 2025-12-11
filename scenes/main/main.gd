class_name Main
extends Node2D

func _ready() -> void:
	pass

func setup_new_game() -> void:
	#print_debug("fresh game starting")
	var tilemap = get_node("CanvasGameMain/TileMapSubViewport/SubViewport/TileMapLayer")
	var overlay = get_node("CanvasGameMain/TileMapSubViewport/SubViewport/TileMapOverlay")
	var endPoint = tilemap.get_node("EndPosition")
	var spawnPoint = tilemap.get_node("SpawnPosition")
	var wave_label = get_node_or_null("/root/Main/CanvasGameUI/BarsControl/TopBar/WavePanel/WaveLabel")
	var health_label = get_node_or_null("/root/Main/CanvasGameUI/BarsControl/TopBar/HealthPanel/HealthLabel")
	var coin_label = get_node_or_null("/root/Main/CanvasGameUI/BarsControl/TopBar/CoinPanel/CoinLabel")
	var hover_label = get_node_or_null("/root/Main/CanvasGameUI/HoverLabel")
	
	GameMan.setup_fresh_game(tilemap, overlay, spawnPoint, endPoint, wave_label, health_label, coin_label, hover_label)
