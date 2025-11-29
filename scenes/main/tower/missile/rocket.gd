extends Area2D
class_name Rocket

@export var speed: float = 0
@export var turn_speed: float = 5.0  # how quickly it turns (radians/sec)
var target: Node2D
var damage: float = 0

func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		queue_free()
		return
	
	# Find direction and desired angle to target
	var to_target = (target.global_position - global_position)
	var desired_angle = to_target.angle()
	
	# Smoothly rotate toward target
	rotation = lerp_angle(rotation, desired_angle, turn_speed * delta)
	
	# Move forward in the direction we're facing
	var velocity = Vector2.RIGHT.rotated(rotation) * speed * delta
	global_position += velocity
	
	# Check proximity for hit using hit radius
	var hit_radius = 50.0  # adjust based on target size
	if global_position.distance_to(target.global_position) < hit_radius:
		if target.has_method("take_damage"):
			target.take_damage(damage)
		queue_free()
