class_name BlockSystemEditor
extends Control
@onready var _drag_manager: DragManager = %DragManager
@onready var _block_canvas: BlockCanvas = %BlockCanvas
@onready var _picker: BlockPicker = %BlockPicker
@onready var _collapse_button: Button = %CollapseButton
@onready var _save_button: Button = %SaveButton
@onready var _picker_split: HSplitContainer = %PickerSplit

@onready var _icon_delete := ThemeDB.get_default_theme().get_icon("Remove", "EditorIcons")
@onready var _icon_collapse := preload("res://block_code_system/icons/backward.png")
@onready var _icon_expand := preload("res://block_code_system/icons/forward.png")

var current_editing_block_script:BlockScriptData = null
var _collapsed: bool = false

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_picker.block_picked.connect(_drag_manager.copy_picked_block_and_drag)
	_block_canvas.reconnect_block.connect(_drag_manager.connect_block_canvas_signals)
	_save_button.pressed.connect(save_script)
	_collapse_button.pressed.connect(_on_collapse_button_pressed)
	_collapse_button.icon = _icon_collapse
	#_drag_manager.block_dropped.connect(save_script)
	#_drag_manager.block_modified.connect(save_script)
	await get_tree().process_frame
	if current_editing_block_script == null:
		if not load_script("user://tree_test.blocktree"):
			current_editing_block_script = BlockScriptData.new([])
		
	switch_script(current_editing_block_script)

func toggle_collapse():
	_collapsed = not _collapsed

	_collapse_button.icon = _icon_expand if _collapsed else _icon_collapse
	_picker.set_collapsed(_collapsed)
	_picker_split.collapsed = _collapsed

func _on_collapse_button_pressed():
	toggle_collapse()

func save_script():
	var block_trees_to_save := _block_canvas.get_canvas_block_trees()
	var save_bytes = var_to_str(block_trees_to_save)
	var file_path = "user://tree_test.blocktree"
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
	var file_write = FileAccess.open("user://tree_test.blocktree",FileAccess.WRITE)
	file_write.store_string(save_bytes)
	file_write.close()

func load_script(script_path:String) -> bool:
	if FileAccess.file_exists(script_path):
		#DirAccess.remove_absolute(script_path)
		var opened_file = FileAccess.get_file_as_string(script_path)
		var tree_found = str_to_var(opened_file)
		current_editing_block_script = BlockScriptData.new(tree_found)
		return true
	return false

func switch_script(block_script: BlockScriptData):
	_picker.bsd_selected(block_script)
	#_title_bar.bsd_selected(block_script)
	_block_canvas.bsd_selected(block_script)

func _input(event):
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				# Release focus
				var focused_node := get_viewport().gui_get_focus_owner()
				if focused_node:
					focused_node.release_focus()
			else:
				_drag_manager.drag_ended()
				
	if event is InputEventKey:
		if Input.is_key_pressed(KEY_CTRL) and event.pressed and event.keycode == KEY_BACKSLASH:
			_collapse_button.button_pressed = not _collapse_button.button_pressed
			toggle_collapse()
