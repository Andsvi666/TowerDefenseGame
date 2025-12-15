class_name CanvasSelect
extends CanvasLayer

@onready var return_button: Button = $SubViewportContainer/SubViewport/ColorRect/ButtonReturn
@onready var play_standart_button: Button = $SubViewportContainer/SubViewport/ControlStandart/ButtonPlay
@onready var play_endless_button: Button = $SubViewportContainer/SubViewport/ControlEndless/ButtonPlay
@onready var play_AI_button: Button = $SubViewportContainer/SubViewport/ControlAI/ButtonPlay

func _ready() -> void:
	return_button.pressed.connect(_on_return_button_pressed)
	play_standart_button.pressed.connect(_on_play_standart_button_pressed)
	play_endless_button.pressed.connect(_on_play_endless_button_pressed)
	play_AI_button.pressed.connect(_on_play_AI_button_pressed)

func _on_return_button_pressed() -> void:
	ScreenMan.change_screen("menu")

func _on_play_standart_button_pressed() -> void:
	ScreenMan.change_screen("game")

func _on_play_endless_button_pressed() -> void:
	pass

func _on_play_AI_button_pressed() -> void:
	pass
