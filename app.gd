extends Node

var hovering_thing: Node = null:
	set(v):
		if hovering_thing == v:
			return
		hovering_thing = v

var dragging_starting_position:Vector2 = Vector2.ZERO
var dragging_mouse_starting_position:Vector2 = Vector2.ZERO
var dragging_node:Node = null
var is_dragging:bool = false
func _input(event: InputEvent) -> void:
	#print("unhandled input ",(hovering_thing != null and is_instance_valid(hovering_thing)))
	if (hovering_thing != null and is_instance_valid(hovering_thing)) or (dragging_node != null and is_instance_valid(dragging_node)):
		if dragging_node == null or not is_instance_valid(dragging_node):
			dragging_node = hovering_thing
		if event is InputEventMouseButton and event.button_index == 1:
			if event.is_pressed():
				dragging_node = hovering_thing
				dragging_starting_position = dragging_node.position
				dragging_mouse_starting_position = event.position
				is_dragging = true
			else: 
				is_dragging = false
				dragging_node = null
		if event is InputEventMouseMotion and is_dragging:
			dragging_node.position = dragging_starting_position + Vector2.ONE * (event.position - dragging_mouse_starting_position)
