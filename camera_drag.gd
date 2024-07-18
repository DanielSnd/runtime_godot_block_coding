extends Camera2D

var mouse_starting_position
var starting_position
var is_dragging = false

func _ready():
	RenderingServer.global_shader_parameter_set("screen_res", get_viewport_rect().size)
#
#func _process(_delta: float) -> void:
	#RenderingServer.global_shader_parameter_set("cam_pos_zoom", Vector3(global_position.x,global_position.y,zoom.x))
	
func _input(event):
	if event is InputEventMouseButton and event.button_index == 2:
		if event.is_pressed():
			starting_position = position
			mouse_starting_position = event.position
			is_dragging = true
		else: 
			is_dragging = false
	if event is InputEventMouseMotion and is_dragging:
		position = starting_position - zoom * (event.position - mouse_starting_position)
