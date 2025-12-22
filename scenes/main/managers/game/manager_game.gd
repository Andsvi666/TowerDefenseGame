class_name ManagerGame
extends Node

signal wave_start_support
signal wave_complete_support
signal game_setup_started
signal update_log
signal game_stopped_by_error

var wave_active: bool = false
var gamemode = null

func _ready() -> void:
	pass

func forced_by_error() -> void:
	emit_signal("game_stopped_by_error")

func setup_fresh_game(tilemap: TileMapLayer, overlay: TileMapLayer, spawnPoint: Marker2D, endPoint: Marker2D, wave_label: Label, health_label: Label, coin_label: Label, hover_panel: Panel) -> void:
	emit_signal("game_setup_started")
	# Reset player stats
	HealthMan.setup_health(health_label)
	if gamemode == "endless":
		CoinsMan.setup_coins(coin_label, 2000)
	else:
		CoinsMan.setup_coins(coin_label, 1000)

	# Reset waves
	WavesMan.setup_waves(wave_label)

	# Setup map-dependent managers
	PathMan.setup_map(tilemap, endPoint)
	BuildingMan.setup_map(tilemap, overlay, hover_panel)
	SpawnerMan.setup_map(spawnPoint)
	
	AiMan.setup()
	
	wave_active = false

func start_support_towers() -> void:
	emit_signal("wave_start_support")

func stop_support_towers() -> void:
	emit_signal("wave_complete_support")

func log_event(message: String) -> void:
	emit_signal("update_log", message)

func show_floating_message(text: String) -> void:
	var msg = Label.new()
	msg.text = text
	msg.add_theme_color_override("font_color", Color.RED)
	msg.add_theme_color_override("font_outline_color", Color.BLACK)
	msg.add_theme_constant_override("outline_size", 5)
	msg.add_theme_font_size_override("font_size", 28)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	add_child(msg)
	
	# Center the message on the screen
	var screen_size = get_viewport().get_visible_rect().size
	msg.global_position = screen_size / 2.0 + Vector2(-400, -100)
	
	# Animate upward + fade out
	var tween = get_tree().create_tween()
	tween.tween_property(msg, "position:y", msg.position.y - 150, 2)
	tween.parallel().tween_property(msg, "modulate:a", 0.0, 1).set_delay(1)
	tween.tween_callback(Callable(msg, "queue_free"))
