class_name HealthRingGeneric
extends Node2D

@export var radius: float = 24.0
@export var thickness: float = 4.0
@export var lost_color: Color = Color.DARK_RED
@export var current_color: Color = Color.GREEN

var health_ratio: float = 1.0  # 1.0 = full, 0.0 = dead

func _draw() -> void:
	# Draw lost health
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, lost_color, thickness)
	# Draw current health
	draw_arc(Vector2.ZERO, radius, 0, TAU * health_ratio, 32, current_color, thickness)

func set_health_ratio(ratio: float) -> void:
	health_ratio = clamp(ratio, 0.0, 1.0)
	queue_redraw()
