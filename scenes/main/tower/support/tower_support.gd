extends TowerBase
class_name TowerSupport

@export var stats: TowerStats  # contains heal_amount, cooldown, build_cost
@export var firing_duration: float = 0.1  # optional effect duration
var can_attack_cooldown = true

func _ready() -> void:
	can_attack = false
	if GameMan.wave_active:
		can_attack = true
	GameMan.connect("wave_start_support", Callable(self, "_on_wave_started"))
	
		# Make sure GameMan has the signal before connecting
	if GameMan.has_signal("wave_complete_support"):
		#print_debug("GameMan has signal")
		GameMan.connect("wave_complete_support", Callable(self, "_on_wave_ended"))
	
	if stats != null:
		apply_stats()


func apply_stats() -> void:
	attack_cooldown = stats.attack_cooldown  # used as heal cooldown
	attack_damage = stats.attack_damage      # used as heal amount
	build_cost = stats.build_cost
	tower_sprite = stats.tower_sprite
	if has_node("TowerSprite") and stats.tower_sprite != "":
		$TowerSprite.texture = load(stats.get_sprite_path(tower_sprite))


func _process(delta: float) -> void:
	if can_attack and can_attack_cooldown:
		#print_debug('attacks')
		shoot(null)

func shoot(target: Node2D) -> void:
	_shoot_effect()
	can_attack_cooldown = false
	HealthMan.heal(attack_damage)
	CoinsMan.add_coins(attack_damage * 10)
	await get_tree().create_timer(attack_cooldown, false).timeout
	can_attack_cooldown = true

func _shoot_effect():
	var diamond = ActivationNode.new()
	diamond.position = Vector2.ZERO  # relative to tower
	add_child(diamond)

func _on_wave_started() -> void:
	#print_debug("wave start")
	can_attack = true

func _on_wave_ended() -> void:
	#print_debug("wave over")
	can_attack = false
