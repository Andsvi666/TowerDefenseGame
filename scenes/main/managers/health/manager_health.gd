class_name ManagerHealth
extends Node

@export var base_health: int = 100
@export var max_health: int = 500
var name_label: Label = null

var current_health: int

signal update_label(sum: int, name_label: Label)
signal game_over

func _ready() -> void:
	await get_tree().process_frame  # wait one frame
	#print_debug("HealthManager initialized with health: ", current_health)

func setup_health(given_label: Label) -> void:
	#print_debug("health set")
	name_label = given_label
	current_health = base_health
	emit_signal("update_label", current_health, name_label)

# Called when enemy reaches base or tower is destroyed
func take_damage(amount: int) -> void:
	current_health = current_health - amount
	emit_signal("update_label", current_health, name_label)
	#print_debug("Base took ", amount, " damage → ", current_health)

	if current_health <= 0:
		_handle_game_over()

func heal(amount: int) -> void:
	if(current_health < max_health):
		#print_debug(amount)
		current_health = current_health + amount
		emit_signal("update_label", current_health, name_label)
	else:
		CoinsMan.add_coins(amount * 10)

func _handle_game_over() -> void:
	# Pause the game
	get_tree().paused = true
	emit_signal("game_over")
