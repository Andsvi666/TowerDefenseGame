class_name ManagerCoins
extends Node

@export var starting_coins: int = 5000
@onready var name_label: Label = get_node("/root/Main/UIRoot/TopBar/CoinLabel")

signal update_label(sum: int, name_label: Label)

var coins: int = 0

#func _ready() -> void:
	#await get_tree().process_frame  # wait one frame

func setup_coins() -> void:
	name_label = get_node_or_null("/root/Main/UIRoot/TopBar/CoinLabel")
	coins = starting_coins
	emit_signal("update_label", coins, name_label)

func add_coins(amount: int) -> void:
	coins += amount
	emit_signal("update_label", coins, name_label)

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		emit_signal("update_label", coins, name_label)
		return true
	return false  # Not enough coins
