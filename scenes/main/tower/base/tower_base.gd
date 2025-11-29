class_name TowerBase
extends Node2D

@export var attack_range : float = 0
@export var attack_cooldown : float = 0
@export var attack_damage : float = 0
@export var build_cost : float = 0
@export var target_group : String = "none"  # e.g., "troop", "tank", "plane"
@export var tower_sprite: String = "none"
@export var firing_sprite: String = "none"
@export var projectile_sprite: String = "none"
@export var projectile_speed: float = 0
@export var projectile_scene: PackedScene  # assign Shell.tscn here

var can_attack : bool = true
var upgraded: bool = false

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	var target = get_nearest_target()
	if target:
		look_at(target.global_position)
		if can_attack:
			shoot(target)

func get_nearest_target() -> Node2D:
	#print_debug(target_group)
	if target_group == "":
		return null
	var enemies = get_tree().get_nodes_in_group(target_group)
	#print_debug(enemies)
	var nearest : Node2D = null
	var min_distance = attack_range
	for e in enemies:
		var dist = global_position.distance_to(e.global_position)
		if dist < min_distance:
			min_distance = dist
			nearest = e
	return nearest

func shoot(target: Node2D) -> void:
	# To be implemented in child scripts
	pass
