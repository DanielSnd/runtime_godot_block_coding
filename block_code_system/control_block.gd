@icon("res://block_code_system/icons/gear.png")
class_name ControlBlock
extends Block

@export var statements: Array = []
@export var defaults: Dictionary = {}

var snaps: Array
var param_name_input_pairs_array: Array = []:
	set(v):
		param_name_input_pairs_array = v

var _param_input_strings_array: Array = []
var pinput_array: Array:
	get():
		_param_input_strings_array.clear()
		for param_name_input_pairs in param_name_input_pairs_array:
			var _param_input_strings: Dictionary = {}
			for pair in param_name_input_pairs:
				_param_input_strings[pair[0]] = pair[1].get_raw_input()
			_param_input_strings_array.append(_param_input_strings)
		return _param_input_strings_array
	set(v):
		_param_input_strings_array = v
		if not _param_input_strings_array.is_empty():
			for i in param_name_input_pairs_array.size():
				for pair in param_name_input_pairs_array[i]:
					pair[1].set_raw_input(_param_input_strings_array[i][pair[0]])

@onready var _background := %Background

func props_to_serialize() -> Array:
	var props_super:Array = super()
	if not pinput_array.is_empty():
		props_super.push_back("pinput_array")
	return props_super

func copy_block_info_to(to_block:Block):
	super(to_block)
	if to_block is ControlBlock:
		to_block.defaults = defaults

func _ready():
	super()

	_background.color = color
	_background.custom_minimum_size.x = BlockConstants.CONTROL_MARGIN

	format()

	if not _param_input_strings_array.is_empty():
		for i in param_name_input_pairs_array.size():
			for pair in param_name_input_pairs_array[i]:
				pair[1].set_raw_input(_param_input_strings_array[i][pair[0]])


func _on_drag_drop_area_mouse_down():
	_drag_started()

static func get_block_class():
	return "ControlBlock"


static func get_scene_path():
	return "res://addons/block_code/ui/blocks/control_block/control_block.tscn"


func format():
	snaps = []
	param_name_input_pairs_array = []
	if (not block_format is Array):
		block_format = [block_format]
	if (not block_format is Array) or block_format.is_empty():
		return

	for i in block_format.size():
		var row := MarginContainer.new()
		row.name = "r%d" % i
		row.custom_minimum_size.x = 80
		row.custom_minimum_size.y = 30
		row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

		var bg := Control.new()
		bg.name = "Background"
		bg.set_script(preload("res://block_code_system/block_bg_ui.gd"))
		bg.color = color
		if i != 0:
			bg.shift_top = BlockConstants.CONTROL_MARGIN
		bg.shift_bottom = BlockConstants.CONTROL_MARGIN
		row.add_child(bg)

		if i == 0:
			var drag_drop: DragDropArea = preload("res://block_code_system/scenes/drag_drop_area.tscn").instantiate()
			row.add_child(drag_drop)
			drag_drop.mouse_down.connect(_drag_started)

		var row_hbox_container := MarginContainer.new()
		row_hbox_container.name = "rhbc"
		row_hbox_container.add_theme_constant_override("margin_left", 10)
		row_hbox_container.add_theme_constant_override("margin_right", 6)
		row_hbox_container.add_theme_constant_override("margin_top", 12)
		row_hbox_container.add_theme_constant_override("margin_bottom", 6)
		row_hbox_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(row_hbox_container)

		var row_hbox := HBoxContainer.new()
		row_hbox.name = "rhbx"
		row_hbox.add_theme_constant_override("separation", 0)
		row_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_hbox_container.add_child(row_hbox)

		%rows.add_child(row)

		param_name_input_pairs_array.append(StatementBlock.format_string(self, row_hbox, block_format[i], defaults))

		var snap_container := MarginContainer.new()
		snap_container.name = "snap%d" % i
		snap_container.custom_minimum_size.y = 30
		snap_container.add_theme_constant_override("margin_left", roundi(BlockConstants.CONTROL_MARGIN))

		var snap_point: SnapPoint = preload("res://block_code_system/scenes/snap_point.tscn").instantiate()
		snap_container.add_child(snap_point)

		snaps.append(snap_point)

		%rows.add_child(snap_container)

	var _bg := Control.new()
	_bg.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_bg.custom_minimum_size.x = 100
	_bg.custom_minimum_size.y = 30
	_bg.set_script(preload("res://block_code_system/block_bg_ui.gd"))
	_bg.color = color
	_bg.shift_top = BlockConstants.CONTROL_MARGIN
	%rows.add_child(_bg)
