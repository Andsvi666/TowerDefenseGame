# ActivationNode.gd
extends Node2D
class_name ActivationNode

@export var size: float = 56
@export var color: Color = Color(0.235, 0.361, 0.929, 0.502)
@export var thickness: float = 10.0
@export var fade_duration: float = 2.0

func _ready() -> void:
	queue_redraw()  # trigger _draw safely

	var tween = get_tree().create_tween()
	tween.tween_property(self, "color:a", 0.0, fade_duration)
	tween.tween_callback(Callable(self, "queue_free"))

func _draw() -> void:
	var half = size / 2
	var points = [
		Vector2(0, -half),   # top
		Vector2(half, 0),    # right
		Vector2(0, half),    # bottom
		Vector2(-half, 0),   # left
		Vector2(0, -half)    # back to top to close loop
	]
	draw_polyline(points, color, thickness)
