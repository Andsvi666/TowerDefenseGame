class_name ManagerScreen
extends Node

var login_scene: PackedScene = preload("res://scenes/main/screen/login/canvas_login.tscn")
var menu_scene: PackedScene = preload("res://scenes/main/screen/menu/canvas_menu.tscn")
var game_select: PackedScene = preload("res://scenes/main/screen/select/canvas_select.tscn")
var game_info: PackedScene = preload("res://scenes/main/screen/info/canvas_info.tscn")
var game_scene: PackedScene = preload("res://scenes/main/screen/gameMain/canvas_game_main.tscn")
var game_ui_scene: PackedScene = preload("res://scenes/main/screen/gameUI/canvas_game_ui.tscn")

func change_screen(screen_name: String) -> void:
	# Get the current Main scene dynamically
	var main = get_tree().get_current_scene()
	if main == null:
		push_error("Main scene not found!")
		return
	
	# Remove old children from Main
	for child in main.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Add new scenes
	match screen_name:
		"login":
			main.add_child(login_scene.instantiate())
		"menu":
			main.add_child(menu_scene.instantiate())
		"select":
			main.add_child(game_select.instantiate())
		"info":
			main.add_child(game_info.instantiate())
		"game":
			# Create instances
			var game := game_scene.instantiate()
			var ui := game_ui_scene.instantiate()
			# Add them
			main.add_child(game)
			main.add_child(ui)
			main.setup_new_game()
