class_name MouseDraggable extends Node

var position:Vector2:
	get:
		return get_parent().position
	set(v):
		get_parent().position = v

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_parent().mouse_filter = Control.MOUSE_FILTER_STOP
	get_parent().mouse_entered.connect(on_mouse_entered)
	get_parent().mouse_exited.connect(on_mouse_exited)

func on_mouse_entered():
	App.hovering_thing = self
	
func on_mouse_exited():
	if App.hovering_thing == self:
		App.hovering_thing = null
		
