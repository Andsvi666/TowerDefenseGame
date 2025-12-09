class_name CanvasLogin
extends CanvasLayer

@onready var login_button: Button = $SubViewportContainer/SubViewport/LoginButton

func _ready() -> void:
	login_button.pressed.connect(_on_login_button_pressed)

func _on_login_button_pressed():
	ScreenMan.change_screen("menu")
