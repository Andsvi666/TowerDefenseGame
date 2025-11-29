extends Resource
class_name TowerStats

@export var tower_name: String = ""
@export var attack_range: float = 0
@export var attack_cooldown: float = 0
@export var attack_damage: float = 0
@export var build_cost: int = 0
@export var projectile_speed: float = 0
@export var target_group: String = "select"  # e.g., "troop", "tank", "plane"
# Only the file name of the sprite, e.g. "turret_1	"
@export var tower_sprite: String = "select subfolder and name"
@export var firing_sprite: String = "select subfolder and name"
@export var projectile_sprite: String = "select subfolder and name"
@export var projectile_scene: PackedScene  # assign Shell.tscn here

func get_sprite_path(name: String) -> String:
	if name == "":
		return ""
	return "res://assets/tiles/tower/" + name + ".png"
