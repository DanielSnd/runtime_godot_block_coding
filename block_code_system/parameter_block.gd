class_name ParameterBlock
extends Block

@export var statement: String = ""
@export var variant_type: Variant.Type
@export var defaults: Dictionary = {}

@onready var _panel := $Panel
@onready var _hbox := %hbox

var param_name_input_pairs: Array

var _param_input_strings: Dictionary = {}
var pinput: Dictionary:
	get():
		_param_input_strings.clear()
		for pair in param_name_input_pairs:
			print("input pairs ",pair)
			_param_input_strings[pair[0]] = pair[1].get_raw_input()
		print("param input strings is %s" % _param_input_strings)
		return _param_input_strings
	set(v):
		_param_input_strings = v
		if _param_input_strings:
			for pair in param_name_input_pairs:
				pair[1].set_raw_input(_param_input_strings[pair[0]])
		
var spawned_by: ParameterOutput

func copy_block_info_to(to_block:Block):
	super(to_block)
	if to_block is ParameterBlock:
		to_block.statement = statement
		to_block.variant_type = variant_type
		to_block.defaults = defaults.duplicate()


func _ready():
	super()

	block_type = BlockConstants.BlockType.VALUE
	var new_panel = _panel.get_theme_stylebox("panel").duplicate()
	new_panel.bg_color = color
	new_panel.border_color = color.darkened(0.2)
	_panel.add_theme_stylebox_override("panel", new_panel)

	format()

	if not _param_input_strings.is_empty():
		for pair in param_name_input_pairs:
			pair[1].set_raw_input(_param_input_strings[pair[0]])


func _on_drag_drop_area_mouse_down():
	_drag_started()

func props_to_serialize() -> Array:
	var props_super:Array = super()
	if not pinput.is_empty():
		props_super.push_back("pinput")
	return props_super
	
func get_serialized_props() -> Array:
	var props := super()
	props.append_array(serialize_props(["block_format", "statement", "defaults", "variant_type"]))

	var _param_input_strings: Dictionary = {}
	for pair in param_name_input_pairs:
		_param_input_strings[pair[0]] = pair[1].get_raw_input()

	props.append(["param_input_strings", _param_input_strings])

	return props


# Override this method to create custom parameter functionality
func get_parameter_string() -> String:
	var formatted_statement := statement

	for pair in param_name_input_pairs:
		formatted_statement = formatted_statement.replace("{%s}" % pair[0], pair[1].get_string())

	return formatted_statement


static func get_block_class():
	return "ParameterBlock"


static func get_scene_path():
	return "res://block_code_system/scenes/parameter_block.tscn"


func format():
	param_name_input_pairs = StatementBlock.format_string(self, _hbox, block_format, defaults)
