class_name ManagerGame
extends Node

var endless_mode: bool = false

signal wave_complete_support
var wave_active: bool = false

func setup_fresh_game() -> void:
	HealthMan.setup_health()
	CoinsMan.setup_coins()
	WavesMan.setup_waves()
	wave_active = false

func stop_support_towers() -> void:
	emit_signal("wave_complete_support")

func show_floating_message(text: String) -> void:
	var msg = Label.new()
	msg.text = text
	msg.add_theme_color_override("font_color", Color.RED)
	msg.add_theme_color_override("font_outline_color", Color.BLACK)
	msg.add_theme_constant_override("outline_size", 5)
	msg.add_theme_font_size_override("font_size", 28)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Add label under your UI root instead of the autoload
	var ui_root = get_node_or_null("/root/Main/UIRoot")
	if ui_root:
		ui_root.add_child(msg)
	else:
		print_debug("Could not find UIRoot, adding to self")
		add_child(msg)

	# Center the message on the screen
	var screen_size = get_viewport().get_visible_rect().size
	msg.global_position = screen_size / 2.0 + Vector2(-400, -100)

	# Animate upward + fade out
	var tween = get_tree().create_tween()
	tween.tween_property(msg, "position:y", msg.position.y - 150, 2)
	tween.parallel().tween_property(msg, "modulate:a", 0.0, 1).set_delay(1)
	tween.tween_callback(Callable(msg, "queue_free"))
