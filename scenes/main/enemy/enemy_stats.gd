extends Resource
class_name EnemyStats

@export var movement_speed: float = 0
@export var max_health: int = 0
@export var damage_cost: int = 0
@export var coin_reward: int = 0
@export var group: String = ""
@export var tier: int = 0

# Only the file name, e.g. "tier_1.png"
@export var sprite_name: String = ""

# Helper function to get full path
func get_sprite_path() -> String:
	if sprite_name == "":
		return ""
	return "res://assets/tiles/enemy/" + sprite_name + ".png"
