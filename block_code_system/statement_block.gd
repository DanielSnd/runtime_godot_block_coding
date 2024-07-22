@icon("res://block_code_system/icons/gear.png")
class_name StatementBlock
extends Block

@export var statement: String = ""
@export var defaults: Dictionary = {}

@onready var _background := %Background
#@onready var _hbox := %hbox

var param_name_input_pairs: Array

var _param_input_strings: Dictionary = {}
var pinput: Dictionary:
	get():
		_param_input_strings.clear()
		for pair in param_name_input_pairs:
			_param_input_strings[pair[0]] = pair[1].get_raw_input()
		return _param_input_strings
	set(v):
		_param_input_strings = v
		if _param_input_strings:
			for pair in param_name_input_pairs:
				pair[1].set_raw_input(_param_input_strings[pair[0]])

func props_to_serialize() -> Array:
	var props_super:Array = super()
	if not pinput.is_empty():
		props_super.push_back("pinput")
	return props_super

func copy_block_info_to(to_block:Block):
	super(to_block)
	if to_block is StatementBlock:
		to_block.statement = statement
		to_block.defaults = defaults.duplicate()

func _ready():
	super()
	%DragDropArea.mouse_down.connect(_on_drag_drop_area_mouse_down)

	if block_type != BlockConstants.BlockType.EXECUTE:
		_background.show_top = false
	_background.color = color

	format()

	if not _param_input_strings.is_empty():
		for pair in param_name_input_pairs:
			pair[1].set_raw_input(_param_input_strings[pair[0]])


func _on_drag_drop_area_mouse_down():
	_drag_started()

static func get_block_class():
	return "StatementBlock"


static func get_scene_path():
	return "res://block_code_system/scenes/statement_block.tscn"

func format():
	param_name_input_pairs = format_string(self, %hbox, block_format, defaults)

static func format_string(parent_block: Block, attach_to: Node, string: String, _defaults: Dictionary) -> Array:
	var _param_name_input_pairs = []
	var regex = RegEx.new()
	regex.compile("\\[([^\\]]+)\\]|\\{([^}]+)\\}")  # Capture things of format {test} or [test]
	var results := regex.search_all(string)

	var start: int = 0
	for result in results:
		var label_text := string.substr(start, result.get_start() - start)
		if label_text != "":
			var _label = Label.new()
			_label.add_theme_color_override("font_color", Color.WHITE)
			_label.text = label_text
			attach_to.add_child(_label)

		var param := result.get_string()
		var copy_block: bool = param[0] == "["
		param = param.substr(1, param.length() - 2)

		var split := param.split(": ")
		var param_name := split[0]
		var param_type_str := split[1]

		var param_type = null
		var option := false
		var custom := false
		if param_type_str == "OPTION":  # Easy way to specify dropdown option
			option = true
		elif param_type_str.begins_with("CUSTOM_"):  # Easy way to specify dropdown option
			custom = true
			param_type = TYPE_MAX
			param_type_str = param_type_str.replace("CUSTOM_","")
		elif param_type_str.begins_with("CUSTOMOPTION_"):
			custom = true
			option = true
			param_type = TYPE_MAX
			param_type_str = param_type_str.replace("CUSTOMOPTION_","")
		#elif not BlockConstants.STRING_TO_VARIANT_TYPE.has(param_type_str):
			#custom = true
			#param_type = TYPE_MAX
		else:
			param_type = BlockConstants.STRING_TO_VARIANT_TYPE[param_type_str]

		var param_default = null
		if _defaults.has(param_name):
			param_default = _defaults[param_name]

		#var param_node: Node

		if copy_block:
			var parameter_output: ParameterOutput = load("res://block_code_system/scenes/parameter_output.tscn").instantiate()
			parameter_output.name = "pout_%d" % start  # Unique path
			parameter_output.block_params = {
				"block_format": param_name,
				"statement": param_name,
				"variant_type": param_type,
				"color": parent_block.color,
				"parent_id" : parent_block.get_meta("id",""),
				"scope": parent_block.get_entry_statement() if parent_block is EntryBlock else ""
			}
			if custom:
				parameter_output.block_params["custom_type"] = param_type_str
				if "custom_type" in attach_to:
					attach_to.custom_type = param_type_str
			parameter_output.block = parent_block
			attach_to.add_child(parameter_output)
			#print("Attach to ",attach_to," parent block ",parent_block," parent block id ",parent_block.get_meta("id",""))
			#parent_block.set_meta("id", "parameter_out")
			#parent_block.set_meta("dont_save",true)
		else:
			var parameter_input: ParameterInput = load("res://block_code_system/scenes/parameter_input.tscn").instantiate()
			parameter_input.name = "pinp_%d" % start  # Unique path
			parameter_input.placeholder = param_name

			if param_type != null:
				parameter_input.variant_type = param_type
			if option:
				parameter_input.option = true
				parameter_input.set_meta("input_id",param_name if BlockSystemInterpreter.enum_datas.has(param_name) else param_type_str)
			parameter_input.modified.connect(func(): parent_block.modified.emit())
			if custom:
				parameter_input.custom_type = param_type_str
				if "custom_type" in attach_to:
					attach_to.custom_type = param_type_str
			attach_to.add_child(parameter_input)
			parameter_input._option_input.set("theme_override_colors/font_color", (parent_block.color as Color).darkened(0.58))
			if param_default:
				if option:
					parameter_input.set_raw_input(param_default)
				else:
					parameter_input.set_raw_input(param_default)
			elif option:
				parameter_input.set_raw_input(0)

			_param_name_input_pairs.append([param_name, parameter_input])

		start = result.get_end()

	var _label_text := string.substr(start)
	if _label_text != "":
		var other_label = Label.new()
		other_label.add_theme_color_override("font_color", Color.WHITE)
		other_label.text = _label_text
		attach_to.add_child(other_label)

	return _param_name_input_pairs
