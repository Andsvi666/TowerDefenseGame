class_name EnemyBase
extends CharacterBody2D

@export var movement_speed: float = 200
@export var damage_cost: int = 50
@export var max_health: int = 100
@export var coin_reward: int = 50

var current_health: int
var path_array: Array[Vector2i] = []

signal enemy_died

func _ready() -> void:
	add_to_group("ENEMY_GROUP")
	current_health = max_health
	
	if ManagerPathfinding.instance != null:
		path_array = ManagerPathfinding.instance.get_valid_path(global_position / 64)
	else:
		push_warning("No PathfindingManager found in scene!")

func _process(delta: float) -> void:
	get_path_to_position()
	move_and_slide()
	rotate_sprite_toward_velocity()

func rotate_sprite_toward_velocity() -> void:
	# Only rotate if we actually have a sprite node
	if velocity.length() > 0 and has_node("Sprite2D"):
		$Sprite2D.rotation = velocity.angle()

func get_path_to_position() -> void:
	if path_array.size() > 0:
		var direction: Vector2 = global_position.direction_to(path_array[0])
		velocity = direction * movement_speed
		if global_position.distance_to(path_array[0]) <= 10:
			path_array.remove_at(0)
	else:
		# Reached the end (or no path found)
		if HealthMan:
			HealthMan.take_damage(damage_cost)
		emit_signal("enemy_died", self)
		queue_free()

func take_damage(amount: int) -> void:
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)

	# Optional: Update health ring if present
	if has_node("HealthRing"):
		$HealthRing.set_health_ratio(float(current_health) / float(max_health))

	if current_health <= 0:
		die()

func die() -> void:
	if CoinsMan:
		CoinsMan.add_coins(coin_reward)
	# emit signal before freeing
	emit_signal("enemy_died", self)
	
	queue_free()
