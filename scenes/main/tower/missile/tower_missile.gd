extends TowerBase
class_name TowerMissile

@export var stats: TowerStats  # resource containing sprite, range, cooldown, damage, target group # optional: small sprite for muzzle flash

func _ready() -> void:
	# Apply stats if resource assigned
	if stats != null:
		apply_stats()

func _process(delta: float) -> void:
	if stats == null:
		return
	var target = get_nearest_target()
	#print_debug(target)
	if target:
		# Rotate towards the target
		look_at(target.global_position)
		# Shoot if ready
		if can_attack:
			shoot(target)

func apply_stats() -> void:
	attack_range = stats.attack_range
	attack_cooldown = stats.attack_cooldown
	attack_damage = stats.attack_damage
	build_cost = stats.build_cost
	target_group = stats.target_group
	tower_sprite = stats.tower_sprite
	#firing_sprite = stats.firing_sprite
	projectile_sprite = stats.projectile_sprite
	projectile_speed = stats.projectile_speed
	if has_node("TowerSprite") and stats.tower_sprite != "":
		$TowerSprite.texture = load(stats.get_sprite_path(tower_sprite))
	#print_debug('applied')

func shoot(target: Node2D) -> void:
	if not can_attack or target == null:
		return
	
	can_attack = false
	
	# Spawn a rocket
	if stats.projectile_scene != null:
		var rocket = stats.projectile_scene.instantiate() as Rocket
		#print_debug("Projectile scene is:", stats.projectile_scene)
		get_parent().add_child(rocket)  # Add to scene so it can move
		rocket.global_position = $Muzzle.global_position
		rocket.target = target
		rocket.damage = attack_damage
		rocket.speed = projectile_speed
		# Optionally assign sprite texture if your Shell has a Sprite child
		if projectile_sprite != "":
			var sprite = rocket.get_node("RocketSprite") as Sprite2D
			if sprite:
				sprite.texture = load(stats.get_sprite_path(projectile_sprite))
	
	# Cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
