extends EnemyBase
class_name EnemyPlane

@export var stats: EnemyStats

func _ready() -> void:
	super()
	if stats != null:
		apply_stats()

func apply_stats() -> void:
	movement_speed = stats.movement_speed
	max_health = stats.max_health
	damage_cost = stats.damage_cost
	coin_reward = stats.coin_reward
	add_to_group(stats.group)

	# set sprite texture
	if has_node("Sprite2D") and stats.sprite_name != "":
		$Sprite2D.texture = load(stats.get_sprite_path())

	current_health = max_health
