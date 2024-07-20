class_name BlockPicker
extends MarginContainer

signal block_picked(block: Block)
signal variable_created(variable: Array)

@onready var _block_list := %BlockList
@onready var _block_scroll := %BlockScroll
@onready var _category_list := %CategoryList
#@onready var _widget_container := %WidgetContainer

var _variable_category_display: VariableCategoryDisplay = null

var scroll_tween: Tween


func bsd_selected(bsd):
	if not bsd:
		reset_picker()
		return

	var blocks_to_add: Array[Block] = []
	var categories_to_add: Array[BlockCategory] = []

	# By default, assume the class is built-in.
	#var parent_class: String = bsd.script_inherits
	#for class_dict in ProjectSettings.get_global_class_list():
		#if class_dict.class == bsd.script_inherits:
			#var script = load(class_dict.path)
			#if script.has_method("get_custom_categories"):
				#categories_to_add = script.get_custom_categories()
			#if script.has_method("get_custom_blocks"):
				#blocks_to_add = script.get_custom_blocks()
				#parent_class = str(script.get_instance_base_type())
			#break

	#blocks_to_add.append_array(BlockCategoryFactory.get_inherited_blocks(parent_class))

	init_picker(blocks_to_add, categories_to_add)

	reload_variables(BlockSystemInterpreter.variables_data)


func reset_picker():
	for c in _category_list.get_children():
		c.queue_free()

	for c in _block_list.get_children():
		c.queue_free()


func init_picker(extra_blocks: Array[Block] = [], extra_categories: Array[BlockCategory] = []):
	reset_picker()

	var blocks := BlockCategoryFactory.get_general_blocks() + extra_blocks
	var block_categories := BlockCategoryFactory.get_categories(blocks, extra_categories)
	var button_group:ButtonGroup = ButtonGroup.new()
	button_group.allow_unpress = true
	var filter_for_variables:Array[BlockCategory] = block_categories.filter(func(b): return b.name == "Variables")
	if filter_for_variables.is_empty():
		block_categories.push_back(BlockCategory.new("Variables",BlockCategoryFactory.BUILTIN_PROPS["Variables"].color,BlockCategoryFactory.BUILTIN_PROPS["Variables"].order,[]))

	for _category in block_categories:
		var category: BlockCategory = _category as BlockCategory

		#var block_category_button: BlockCategoryButton = preload("res://block_code_system/scenes/block_category_button.tscn").instantiate()
		#block_category_button.category = category
		#block_category_button.selected.connect(_category_selected)
#
		#_category_list.add_child(block_category_button)

		var block_category_display :BlockCategoryDisplay
		if category.name != "Variables":
			block_category_display = preload("res://block_code_system/scenes/block_category_display.tscn").instantiate()
		else:
			block_category_display = preload("res://block_code_system/scenes/variables_category_display.tscn").instantiate()
			_variable_category_display = block_category_display
			_variable_category_display.variable_created.connect(on_variable_created)
		block_category_display.category = category
		_block_list.add_child(block_category_display)
		(block_category_display._button as Button).button_group = button_group

		for _block in category.block_list:
			var block: Block = _block as Block
			block.drag_started.connect(_block_picked)

		_block_scroll.scroll_vertical = 0

func on_variable_created(variable:Array):
	BlockSystemInterpreter.variables_data.push_back(variable)
	variable_created.emit(variable)
	print("Variables now are: ",BlockSystemInterpreter.variables_data)
	reload_variables(BlockSystemInterpreter.variables_data)

func _block_picked(block: Block):
	block_picked.emit(block)


func scroll_to(y: float):
	if scroll_tween:
		scroll_tween.kill()
	scroll_tween = create_tween()
	scroll_tween.tween_property(_block_scroll, "scroll_vertical", y, 0.2)


func _category_selected(category: BlockCategory):
	for block_category_display in _block_list.get_children():
		if block_category_display.category.name == category.name:
			scroll_to(block_category_display.position.y)
			break

func reload_variables(variables: Array):
	if _variable_category_display:
		for c in _variable_category_display.variable_blocks.get_children():
			c.queue_free()

		var i := 1
		for block in BlockCategoryFactory.get_variable_blocks(variables, BlockSystemInterpreter.block_infos_dict):
			_variable_category_display.variable_blocks.add_child(block)
			block.drag_started.connect(_block_picked)
			if i % 2 == 0:
				var spacer := Control.new()
				spacer.custom_minimum_size.y = 12
				_variable_category_display.variable_blocks.add_child(spacer)
			i += 1

func set_collapsed(collapsed: bool):
	visible = not collapsed
