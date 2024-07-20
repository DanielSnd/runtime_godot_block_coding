class_name BlockCategoryDisplay
extends MarginContainer

signal category_expanded(value: bool)
var category: BlockCategory

@onready var _button := %Button
@onready var _blocks := %Blocks
@onready var _background = %Background

@onready var _icon_collapsed := preload("res://block_code_system/icons/forward.png")
@onready var _icon_expanded := preload("res://block_code_system/icons/down.png")

var expanded: bool:
	set = _set_expanded

func _set_expanded(value: bool):
	expanded = value

	for vbox_child in _button.get_parent().get_children():
		if vbox_child == _button: continue
		vbox_child.visible = expanded

	if expanded:
		_button.icon = _icon_expanded
		_background.color = category.color.darkened(0.3)
		_background.color.a = 0.72
	else:
		_button.icon = _icon_collapsed
		_background.color = category.color.darkened(0.08)
		_background.color.a = 0.72

	category_expanded.emit(expanded)

func _ready():
	if not category:
		category = BlockCategory.new()

	_button.text = category.name

	for _block in category.block_list:
		var block: Block = _block as Block

		block.color = category.color

		_blocks.add_child(block)
		block.pivot_offset = block.size * 0.5
	_button.add_theme_color_override("font_pressed_color", category.color.lightened(0.3))
	_button.add_theme_color_override("font_color", category.color.darkened(0.75))
	_button.add_theme_color_override("font_hover_color", category.color.lightened(0.65))
	_button.add_theme_color_override("icon_pressed_color", category.color.lightened(0.3))
	_button.add_theme_color_override("icon_normal_color", category.color.darkened(0.4))
	var get_pressed:StyleBoxFlat = _button.get("theme_override_styles/pressed") as StyleBoxFlat
	if get_pressed != null:
		get_pressed = get_pressed.duplicate()
		_button.set("theme_override_styles/pressed",get_pressed)
		get_pressed.border_color = category.color.lightened(0.3)
	_button.toggled.connect(_on_button_toggled)
	expanded = false

func _on_button_toggled(toggled_on):
	expanded = toggled_on
