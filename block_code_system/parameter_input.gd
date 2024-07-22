@icon("res://block_code_system/icons/gear.png")
class_name ParameterInput
extends MarginContainer

signal modified

@export var placeholder: String = "Parameter":
	set = _set_placeholder

@export var variant_type: Variant.Type = TYPE_STRING
@export var custom_type:String = ""
@export var block_type: BlockConstants.BlockType = BlockConstants.BlockType.VALUE
var option: bool = false

@onready var _panel := %Panel
@onready var snap_point := %snap
@onready var _input_switcher := %InputSwitcher

## Inputs
# Text
@onready var _text_input := %TextInput
@onready var _line_edit := %LineEdit
# Color
@onready var _color_input := %ColorInput
# Option Dropdown
@onready var _option_input :OptionButton= %OptionInput
# Vector2
@onready var _vector2_input := %Vector2Input
@onready var _x_line_edit := %XLineEdit
@onready var _y_line_edit := %YLineEdit
# Bool
@onready var _bool_input := %BoolInput
@onready var _bool_input_option := %BoolInputOption


func set_raw_input(raw_input):
	if option:
		if _panel != null:
			_panel.visible = false
		_option_input.clear()
		var option_items :Dictionary = BlockSystemInterpreter.enum_datas.get(get_meta("input_id",""),{})
		for item in option_items.keys():
			_option_input.add_item(item.capitalize(),option_items[item])
		if raw_input is int:
			_option_input.select(raw_input)
		return

	match variant_type:
		TYPE_COLOR:
			_color_input.color = raw_input
			_update_panel_bg_color(raw_input)
		TYPE_VECTOR2:
			var split = raw_input.split(",")
			_x_line_edit.text = split[0]
			_y_line_edit.text = split[1]
		TYPE_BOOL:
			_bool_input_option.select(raw_input)
		_:
			_line_edit.text = str(raw_input)


func get_raw_input():
	if option:
		return _option_input.selected

	match variant_type:
		TYPE_COLOR:
			return _color_input.color
		TYPE_VECTOR2:
			return _x_line_edit.text + "," + _y_line_edit.text
		TYPE_BOOL:
			return bool(_bool_input_option.selected)
		_:
			return _line_edit.text


func _set_placeholder(new_placeholder: String) -> void:
	placeholder = new_placeholder

	if not is_node_ready():
		return

	_line_edit.placeholder_text = placeholder


func _ready():
	%snap.snapped_block_changed.connect(_on_snap_point_snapped_block_changed)
	var stylebox = _panel.get_theme_stylebox("panel")
	stylebox.bg_color = Color.WHITE

	_set_placeholder(placeholder)

	snap_point.block_type = block_type
	snap_point.variant_type = variant_type
	snap_point.custom_type = custom_type

	_update_visible_input()


func get_snapped_block() -> Block:
	return snap_point.get_snapped_block()


func get_string() -> String:
	var snapped_block: ParameterBlock = get_snapped_block() as ParameterBlock
	if snapped_block:
		var generated_string = snapped_block.get_parameter_string()
		if BlockConstants.can_cast(snapped_block.variant_type, variant_type):
			return BlockConstants.cast(generated_string, snapped_block.variant_type, variant_type)
		else:
			push_warning("No cast from %s to %s; using '%s' verbatim" % [snapped_block, variant_type, generated_string])
			return generated_string

	var input = get_raw_input()

	if option:
		return _option_input.get_item_text(_option_input.selected).to_snake_case()

	match variant_type:
		TYPE_STRING:
			return "'%s'" % input.replace("\\", "\\\\").replace("'", "\\'")
		TYPE_VECTOR2:
			return "Vector2(%s)" % input
		TYPE_COLOR:
			return "Color%s" % str(input)
		_:
			return "%s" % input


func _on_line_edit_text_changed(_new_text):
	modified.emit()


func _update_visible_input():
	if snap_point.has_snapped_block():
		_switch_input(null)
	elif option:
		_switch_input(_option_input)
	else:
		match variant_type:
			TYPE_COLOR:
				_switch_input(_color_input)
			TYPE_VECTOR2:
				_switch_input(_vector2_input)
			TYPE_BOOL:
				_switch_input(_bool_input)
			_:
				_switch_input(_text_input)

func _switch_input(node: Node):
	for c in _input_switcher.get_children():
		c.visible = false

	if node != null:
		node.visible = true
		_panel.visible = true
		if node is OptionButton:
			_panel.visible = false
	else:
		_panel.visible = false


func _on_color_input_color_changed(color):
	_update_panel_bg_color(color)

	modified.emit()


func _update_panel_bg_color(new_color):
	var stylebox = _panel.get_theme_stylebox("panel").duplicate()
	stylebox.bg_color = new_color
	_panel.add_theme_stylebox_override("panel", stylebox)


func _on_option_input_item_selected(_index):
	modified.emit()


func _on_snap_point_snapped_block_changed(_block):
	_update_visible_input()
