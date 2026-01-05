class_name CanvasLogin
extends CanvasLayer

@onready var login_button: Button = $SubViewportContainer/SubViewport/LoginButton
@onready var test_button: Button = $SubViewportContainer/SubViewport/TestButton

func _ready() -> void:
	login_button.pressed.connect(_on_login_button_pressed)
	test_button.pressed.connect(_on_test_button_pressed)


func _on_login_button_pressed():
	FirebaseMan.login_with_google()

func _on_test_button_pressed():
	FirebaseMan.login_with_test_user()
