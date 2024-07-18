extends MarginContainer

signal pressed

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		pressed.emit()
		print("Emitted press")
		get_viewport().set_input_as_handled()
