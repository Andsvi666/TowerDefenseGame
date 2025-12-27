class_name CanvasInfo
extends CanvasLayer

#buttons
@onready var return_button: Button = $SubViewportContainer/SubViewport/ControlReturn/ButtonReturn
@onready var game_button: Button = $SubViewportContainer/SubViewport/ControlButtons/VBoxContainer/ButtonGame
@onready var how_button: Button = $SubViewportContainer/SubViewport/ControlButtons/VBoxContainer/ButtonHow
@onready var modes_button: Button = $SubViewportContainer/SubViewport/ControlButtons/VBoxContainer/ButtonModes
@onready var enemy_button: Button = $SubViewportContainer/SubViewport/ControlButtons/VBoxContainer/ButtonEnemies
@onready var tower_button: Button = $SubViewportContainer/SubViewport/ControlButtons/VBoxContainer/ButtonTowers

#info controls
@onready var game_block: Control = $SubViewportContainer/SubViewport/ControlTerminus
@onready var how_block: Control = $SubViewportContainer/SubViewport/ControlHow
@onready var modes_block: Control = $SubViewportContainer/SubViewport/ControlGameModes
@onready var enemy_block: Control = $SubViewportContainer/SubViewport/ControlEnemies
@onready var tower_block: Control = $SubViewportContainer/SubViewport/ControlTowers

#unit descriptions
@onready var troop_text_1: RichTextLabel = $SubViewportContainer/SubViewport/ControlEnemies/ScrollContainer/VBoxContainer/HBoxTroopTiers/RichTextLabel
@onready var troop_text_2: RichTextLabel = $SubViewportContainer/SubViewport/ControlEnemies/ScrollContainer/VBoxContainer/HBoxTroopTiers/RichTextLabel2
@onready var troop_text_3: RichTextLabel = $SubViewportContainer/SubViewport/ControlEnemies/ScrollContainer/VBoxContainer/HBoxTroopTiers/RichTextLabel3

@onready var tank_text_1: RichTextLabel = $SubViewportContainer/SubViewport/ControlEnemies/ScrollContainer/VBoxContainer/HBoxTankTiers/RichTextLabel
@onready var tank_text_2: RichTextLabel = $SubViewportContainer/SubViewport/ControlEnemies/ScrollContainer/VBoxContainer/HBoxTankTiers/RichTextLabel2
@onready var tank_text_3: RichTextLabel = $SubViewportContainer/SubViewport/ControlEnemies/ScrollContainer/VBoxContainer/HBoxTankTiers/RichTextLabel3

@onready var plane_text_1: RichTextLabel = $SubViewportContainer/SubViewport/ControlEnemies/ScrollContainer/VBoxContainer/HBoxPlaneTiers/RichTextLabel
@onready var plane_text_2: RichTextLabel = $SubViewportContainer/SubViewport/ControlEnemies/ScrollContainer/VBoxContainer/HBoxPlaneTiers/RichTextLabel2
@onready var plane_text_3: RichTextLabel = $SubViewportContainer/SubViewport/ControlEnemies/ScrollContainer/VBoxContainer/HBoxPlaneTiers/RichTextLabel3

#tower descriptions
@onready var turret_text_1: RichTextLabel = $SubViewportContainer/SubViewport/ControlTowers/ScrollContainer/VBoxContainer/HBoxTurretTiers/RichTextLabel
@onready var turret_text_2: RichTextLabel = $SubViewportContainer/SubViewport/ControlTowers/ScrollContainer/VBoxContainer/HBoxTurretTiers/RichTextLabel2

@onready var cannon_text_1: RichTextLabel = $SubViewportContainer/SubViewport/ControlTowers/ScrollContainer/VBoxContainer/HBoxCannonTiers/RichTextLabel
@onready var cannon_text_2: RichTextLabel = $SubViewportContainer/SubViewport/ControlTowers/ScrollContainer/VBoxContainer/HBoxCannonTiers/RichTextLabel2

@onready var missile_text_1: RichTextLabel = $SubViewportContainer/SubViewport/ControlTowers/ScrollContainer/VBoxContainer/HBoxMissileTiers/RichTextLabel
@onready var missile_text_2: RichTextLabel = $SubViewportContainer/SubViewport/ControlTowers/ScrollContainer/VBoxContainer/HBoxMissileTiers/RichTextLabel2

@onready var support_text_1: RichTextLabel = $SubViewportContainer/SubViewport/ControlTowers/ScrollContainer/VBoxContainer/HBoxSupportTiers/RichTextLabel
@onready var support_text_2: RichTextLabel = $SubViewportContainer/SubViewport/ControlTowers/ScrollContainer/VBoxContainer/HBoxSupportTiers/RichTextLabel2

func _ready() -> void:
	setup_values()
	return_button.pressed.connect(_on_return_button_pressed)
	game_button.pressed.connect(func() -> void:
		_on_switch_info(game_block))
	how_button.pressed.connect(func() -> void:
		_on_switch_info(how_block))
	modes_button.pressed.connect(func() -> void:
		_on_switch_info(modes_block))
	enemy_button.pressed.connect(func() -> void:
		_on_switch_info(enemy_block))
	tower_button.pressed.connect(func() -> void:
		_on_switch_info(tower_block))

func _on_return_button_pressed() -> void:
	ScreenMan.change_screen("menu")

func _on_switch_info(selected_block: Control) -> void:
	game_block.visible = false
	how_block.visible = false
	modes_block.visible = false
	enemy_block.visible = false
	tower_block.visible = false
	
	selected_block.visible = true

func setup_values() -> void:
	#enemy
	var stats_enemy = AiMan.get_enemy_stats_summary()
	display_text_lines_enemy(1, troop_text_1, stats_enemy["troop_tier_1"])
	display_text_lines_enemy(2, troop_text_2, stats_enemy["troop_tier_2"])
	display_text_lines_enemy(3, troop_text_3, stats_enemy["troop_tier_3"])
	display_text_lines_enemy(1, tank_text_1, stats_enemy["tank_tier_1"])
	display_text_lines_enemy(2, tank_text_2, stats_enemy["tank_tier_2"])
	display_text_lines_enemy(3, tank_text_3, stats_enemy["tank_tier_3"])
	display_text_lines_enemy(1, plane_text_1, stats_enemy["plane_tier_1"])
	display_text_lines_enemy(2, plane_text_2, stats_enemy["plane_tier_2"])
	display_text_lines_enemy(3, plane_text_3, stats_enemy["plane_tier_3"])
	#towers
	var stats_tower = AiMan.get_tower_stats_summary()
	display_text_lines_tower(1, turret_text_1, stats_tower["turret_tier_1"])
	display_text_lines_tower(2, turret_text_2, stats_tower["turret_tier_2"])
	display_text_lines_tower(1, cannon_text_1, stats_tower["cannon_tier_1"])
	display_text_lines_tower(2, cannon_text_2, stats_tower["cannon_tier_2"])
	display_text_lines_tower(1, missile_text_1, stats_tower["missile_tier_1"])
	display_text_lines_tower(2, missile_text_2, stats_tower["missile_tier_2"])
	display_text_lines_tower(1, support_text_1, stats_tower["support_tier_1"])
	display_text_lines_tower(2, support_text_2, stats_tower["support_tier_2"])
	

func display_text_lines_enemy(tier: int, label: RichTextLabel, stats: Dictionary) -> void:
	label.clear()
	label.append_text("Unit Tier: %s\n" % tier)
	label.append_text("Unit Health: %.0f\n" % stats.health)
	label.append_text("Unit Speed: %.1f\n" % stats.speed)
	label.append_text("Unit Damage: %.0f\n" % stats.damage)
	label.append_text("Unit Reward: %d coins\n" % stats.reward)

func display_text_lines_tower(tier: int, label: RichTextLabel, stats: Dictionary) -> void:
	label.clear()
	label.append_text("Tower Tier: %s\n" % tier)
	label.append_text("Tower Damage: %.0f\n" % stats.damage)
	label.append_text("Tower Firerate: %.1f\n" % stats.firerate)
	label.append_text("Tower Range: %.0f\n" % stats.range)
	label.append_text("Tower Price: %d coins\n" % stats.cost)
