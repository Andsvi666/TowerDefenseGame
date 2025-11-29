extends Area2D
class_name Shell

@export var speed: float = 0
var target: Node2D
var damage: float = 0

func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		queue_free()
		return

	# Move toward target
	var direction = (target.global_position - global_position).normalized()
	global_position += direction * speed * delta

	# Check if reached target (or collision)
	if global_position.distance_to(target.global_position) < 5.0:
		if target.has_method("take_damage"):
			target.take_damage(damage)
		queue_free()
