class_name CreateVariableButton
extends MarginContainer

signal create_variable(var_name: String, var_type: String)

@onready var _create_variable_dialog := %CreateVariableDialog
@onready var create_variable_button = %CreateVariable

func _ready():
	create_variable_button.pressed.connect(_on_create_button_pressed)
	_create_variable_dialog.create_variable.connect(_on_create_variable_dialog_create_variable)

func _on_create_button_pressed():
	_create_variable_dialog.visible = true

func _on_create_variable_dialog_create_variable(var_name, var_type):
	create_variable.emit(var_name, var_type)
