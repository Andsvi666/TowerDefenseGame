extends TowerBase
class_name TowerTurret

@export var stats: TowerStats  # resource containing sprite, range, cooldown, damage, target group # optional: small sprite for muzzle flash
@export var firing_duration: float = 0.1  # seconds

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
	firing_sprite = stats.firing_sprite
	#projectile_sprite = stats.projectile_sprite
	if has_node("TowerSprite") and stats.tower_sprite != "":
		$TowerSprite.texture = load(stats.get_sprite_path(tower_sprite))
	if has_node("FiringSprite") and stats.firing_sprite != "":
		$FiringSprite.texture = load(stats.get_sprite_path(firing_sprite))
	#print_debug('applied')

func shoot(target: Node2D) -> void:
	if not can_attack or target == null:
		return  # Exit if still on cooldown or target missing
	can_attack = false
	# Rotate to face target
	look_at(target.global_position)
	# Deal damage
	target.take_damage(attack_damage)
	# Optional: show firing sprite
	if firing_sprite:
		$FiringSprite.visible = true
		await get_tree().create_timer(firing_duration).timeout
		$FiringSprite.visible = false
	# Wait for cooldown before next shot
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
