class_name ManagerCoins
extends Node

var name_label: Label = null

signal update_label(sum: int, name_label: Label)

var coins: int = 0

#func _ready() -> void:
	#await get_tree().process_frame  # wait one frame

func setup_coins(given_label: Label, sum: int) -> void:
	name_label = given_label
	coins = sum
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
