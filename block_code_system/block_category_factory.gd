class_name BlockCategoryFactory
extends Object

const BLOCKS: Dictionary = {
	"control_block": preload("res://block_code_system/scenes/control_block.tscn"),
	"parameter_block": preload("res://block_code_system/scenes/parameter_block.tscn"),
	"statement_block": preload("res://block_code_system/scenes/statement_block.tscn"),
	"entry_block": preload("res://block_code_system/scenes/entry_block.tscn"),
}

## Properties for builtin categories. Order starts at 10 for the first
## category and then are separated by 10 to allow custom categories to
## be easily placed between builtin categories.
const BUILTIN_PROPS: Dictionary = {
	"Lifecycle":
	{
		"color": Color("ec3b59"),
		"order": 10,
	},
	"Transform | Position":
	{
		"color": Color("4b6584"),
		"order": 20,
	},
	"Transform | Rotation":
	{
		"color": Color("4b6584"),
		"order": 30,
	},
	"Transform | Scale":
	{
		"color": Color("4b6584"),
		"order": 40,
	},
	"Graphics | Modulate":
	{
		"color": Color("03aa74"),
		"order": 50,
	},
	"Graphics | Visibility":
	{
		"color": Color("03aa74"),
		"order": 60,
	},
	"Graphics | Viewport":
	{
		"color": Color("03aa74"),
		"order": 61,
	},
	"Sounds":
	{
		"color": Color("e30fc0"),
		"order": 70,
	},
	"Physics | Mass":
	{
		"color": Color("a5b1c2"),
		"order": 80,
	},
	"Physics | Velocity":
	{
		"color": Color("a5b1c2"),
		"order": 90,
	},
	"Input":
	{
		"color": Color("d54322"),
		"order": 100,
	},
	"Communication | Methods":
	{
		"color": Color("4b7bec"),
		"order": 110,
	},
	"Communication | Groups":
	{
		"color": Color("4b7bec"),
		"order": 120,
	},
	"Info | Score":
	{
		"color": Color("cf6a87"),
		"order": 130,
	},
	"Loops":
	{
		"color": Color("20bf6b"),
		"order": 140,
	},
	"Logic | Conditionals":
	{
		"color": Color("45aaf2"),
		"order": 150,
	},
	"Logic | Comparison":
	{
		"color": Color("45aaf2"),
		"order": 160,
	},
	"Logic | Boolean":
	{
		"color": Color("45aaf2"),
		"order": 170,
	},
	"Variables":
	{
		"color": Color("ff8f08"),
		"order": 180,
	},
	"Math":
	{
		"color": Color("a55eea"),
		"order": 190,
	},
	"Utility":
	{
		"color": Color("394857"),
		"order": 200,
	},
}


## Compare block categories for sorting. Compare by order then name.
static func _category_cmp(a: BlockCategory, b: BlockCategory) -> bool:
	if a.order != b.order:
		return a.order < b.order
	return a.name.naturalcasecmp_to(b.name) < 0


static func get_categories(blocks: Array[Block], extra_categories: Array[BlockCategory] = []) -> Array[BlockCategory]:
	var cat_map: Dictionary = {}
	var extra_cat_map: Dictionary = {}

	for cat in extra_categories:
		extra_cat_map[cat.name] = cat

	for block in blocks:
		if block.category.is_empty():
			continue
		var cat: BlockCategory = cat_map.get(block.category)
		if cat == null:
			cat = extra_cat_map.get(block.category)
			if cat == null:
				var props: Dictionary = BUILTIN_PROPS.get(block.category, {})
				var color: Color = props.get("color", Color.SLATE_GRAY)
				var order: int = props.get("order", 0)
				cat = BlockCategory.new(block.category, color, order)
			cat_map[block.category] = cat
		cat.block_list.append(block)

	# Dictionary.values() returns an untyped Array and there's no way to
	# convert an array type besides Array.assign().
	var cats: Array[BlockCategory] = []
	cats.assign(cat_map.values())
	# Accessing a static Callable from a static function fails in 4.2.1.
	# Use the fully qualified name.
	# https://github.com/godotengine/godot/issues/86032
	cats.sort_custom(BlockCategoryFactory._category_cmp)
	return cats


static func property_to_blocklist(property: Dictionary) -> Array[Block]:
	var block_list: Array[Block] = []

	var block_type = property.type

	if block_type:
		var block_type_string: String = BlockConstants.VARIANT_TYPE_TO_STRING[block_type]

		var b = BLOCKS["statement_block"].instantiate()
		b.block_format = "Set %s to {value: %s}" % [property.name.capitalize(), block_type_string]
		b.statement = "%s = {value}" % property.name
		b.category = property.category
		block_list.append(b)

		b = BLOCKS["statement_block"].instantiate()
		b.block_format = "Change %s by {value: %s}" % [property.name.capitalize(), block_type_string]
		b.statement = "%s += {value}" % property.name
		b.category = property.category
		block_list.append(b)

		b = BLOCKS["parameter_block"].instantiate()
		b.block_type = block_type
		b.block_format = "%s" % property.name.capitalize()
		b.statement = "%s" % property.name
		b.category = property.category
		block_list.append(b)

	return block_list


static func blocks_from_property_list(property_list: Array, selected_props: Dictionary) -> Array[Block]:
	var block_list: Array[Block]

	for selected_property in selected_props:
		var found_prop
		for prop in property_list:
			if selected_property == prop.name:
				found_prop = prop
				found_prop.category = selected_props[selected_property]
				break
		if found_prop:
			block_list.append_array(property_to_blocklist(found_prop))
		else:
			push_warning("No property matching %s found in %s" % [selected_property, property_list])

	return block_list


static func get_inherited_blocks(_class_name: String) -> Array[Block]:
	var blocks: Array[Block] = []

	var current: String = _class_name

	while current != "":
		#blocks.append_array(get_built_in_blocks(current))
		current = ClassDB.get_parent_class(current)

	return blocks

static func instantiate_block_type(p_block_type:String) -> Block:
	if BLOCKS.has(p_block_type):
		var b:Block = BLOCKS[p_block_type].instantiate()
		b.set_meta("block_type", p_block_type)
		return b
	return instantiate_block_type("statement_block")

static func add_block_type_to_dictionary(p_block_dictionary:Dictionary, block_id:String, block_base_type:String, block_info:Dictionary) -> Dictionary:
	block_info["id"] = block_id
	block_info["base_type"] = block_base_type
	p_block_dictionary[block_id] = block_info
	var block_format = block_info.get("block_format","")
	if block_format.contains(": ") and block_format.contains("["):
		var regex = RegEx.new()
		regex.compile("\\[([^\\]]+)\\]")  # Capture things of format {test} or [test]
		for result in regex.search_all(block_format):
			var param := result.get_string()
			param = param.substr(1, param.length() - 2)
			var split := param.split(": ")
			var param_type = BlockConstants.STRING_TO_VARIANT_TYPE.get(split[1],-1)
			if param_type != -1:
				if not block_info.has("outputs"): block_info["outputs"] = {}
				block_info["outputs"][split[0]] = param_type
	return p_block_dictionary

static func add_general_blocks_to_dictionary(blocks_dictionary:Dictionary = {}):
	add_block_type_to_dictionary(blocks_dictionary, "from_output","parameter_block",{})

	add_block_type_to_dictionary(blocks_dictionary, "ready_block", "entry_block", {"block_format": "On Ready", "callable" : BlockSystemInterpreter.execute_block, "tooltip_text" : 'The following will be executed when the node is "ready"', "category" : "Lifecycle"})

	add_block_type_to_dictionary(blocks_dictionary, "process_block", "entry_block", {"block_format": "On Process", "tooltip_text" : 'The following will be executed during the processing step of the main loop', "category" : "Lifecycle"})

	add_block_type_to_dictionary(blocks_dictionary, "queue_free", "statement_block", {"block_format": "Queue Free", "tooltip_text" : 'Queues this node to be deleted at the end of the current frame', "category" : "Lifecycle"})

#region Loops
				#b.block_format = "On [body: NODE_PATH] %s" % [verb]
	add_block_type_to_dictionary(blocks_dictionary, "for_i_number", "control_block", {"block_format": "repeat {number: INT}  [_index: INT]", "callable" : BlockSystemInterpreter.repeat_block , "category" : "Loops"})
#endregion

#region Logic
	add_block_type_to_dictionary(blocks_dictionary, "if_then", "control_block", {"block_format": "if    {condition: BOOL}   then", \
	"callable" : BlockSystemInterpreter.if_then \
	, "category" : "Logic | Conditionals"})

	add_block_type_to_dictionary(blocks_dictionary, "else_if", "control_block", {"block_format": "else if    {condition: BOOL}   then", \
	"callable" : BlockSystemInterpreter.else_if \
	, "category" : "Logic | Conditionals"})

	add_block_type_to_dictionary(blocks_dictionary, "then_else", "control_block", {"block_format": "else then", \
	"callable" : BlockSystemInterpreter.then_else \
	, "category" : "Logic | Conditionals"})

	add_block_type_to_dictionary(blocks_dictionary, "compare_numbers", "parameter_block", {"block_format": "{int1: INT} {op: OPTION} {int2: INT}", "defaults" : {"op": [1,["==", ">", "<", ">=", "<=", "!="]]}, \
	"callable" : BlockSystemInterpreter.compare_numbers, \
	"variant_type" : Variant.Type.TYPE_BOOL, "category" : "Logic | Comparison"})

	for op in ["and", "or"]:
		add_block_type_to_dictionary(blocks_dictionary, ("boolean_%s" % op), "parameter_block", {"block_format": ("{bool1: BOOL} %s {bool2: BOOL}" % op), "variant_type" : Variant.Type.TYPE_BOOL, \
		"callable" : (BlockSystemInterpreter.boolean_and if op == "and" else BlockSystemInterpreter.boolean_or), \
		"category" : "Logic | Boolean"})

	add_block_type_to_dictionary(blocks_dictionary, "boolean_not", "parameter_block", {"block_format": "Not {bool: BOOL}", "variant_type" : Variant.Type.TYPE_BOOL, \
	"callable" : BlockSystemInterpreter.boolean_not, \
	"category" : "Logic | Boolean"})

	add_block_type_to_dictionary(blocks_dictionary, "print", "statement_block", {"block_format": "print {text: STRING}", \
	"callable" : BlockSystemInterpreter.print_block, \
	"category" : "Utility"})

	add_block_type_to_dictionary(blocks_dictionary, "define_method", "entry_block", {"block_format": "Define method {method_name: NIL}", \
	"callable" : BlockSystemInterpreter.continue_chain, \
	"category" : "Communication | Methods", "tooltip_text" : "Define a method/function with following statements"})

	add_block_type_to_dictionary(blocks_dictionary, "call_method", "statement_block", {"block_format": "Call method {method_name: STRING}", \
	"callable" : BlockSystemInterpreter.call_method, \
	"category" : "Communication | Methods", "tooltip_text" : "Calls the method/function"})

	BlockSystemInterpreter.block_infos_dict = blocks_dictionary

static func get_general_blocks() -> Array[Block]:
	#var b: Block
	var block_list: Array[Block] = []
	var blocks_dictionary:Dictionary = {}

	add_general_blocks_to_dictionary(blocks_dictionary)

	for blck_id:String in blocks_dictionary.keys():
		block_list.append(instantiate_block_from_dictionary(blocks_dictionary, blck_id))

	return block_list

static func instantiate_block_from_dictionary(block_dictionary:Dictionary, block_id:String) -> Block:
	if block_dictionary.has(block_id):
		var blck:Dictionary = block_dictionary[block_id]
		var block_instantiated :Block = instantiate_block_type(blck["base_type"])
		block_instantiated.set_meta("id",blck["id"])
		var built_in_props:Dictionary = BUILTIN_PROPS.get(blck.get("category",""),{})
		for built_in_key in built_in_props.keys():
			if built_in_key in block_instantiated:
				block_instantiated.set(built_in_key, built_in_props[built_in_key])
		for blck_key in blck.keys():
			if blck_key in block_instantiated:
				block_instantiated.set(blck_key, blck[blck_key])
		return block_instantiated
	return null



static func get_variable_blocks(variables: Array, blocks_dictionary:Dictionary, create_blocks:bool = true):
	var block_list: Array[Block]

	for variable in variables:
		print(variable)
		if variable.size() < 2: continue
		var variable_type_string: String = BlockConstants.VARIANT_TYPE_TO_STRING[variable[1]]
		var get_string:String = "get_var_%s" % variable[0]
		var set_string:String = "set_var_%s" % variable[0]

		if not blocks_dictionary.has(get_string):
			add_block_type_to_dictionary(blocks_dictionary, get_string, "parameter_block", {"block_format": variable[0], \
			"statement" : variable[0],
			"variant_type" : variable[1],\
			"callable" : BlockSystemInterpreter.get_var, \
			"category" : "Variables"})

		if not blocks_dictionary.has(set_string):
			add_block_type_to_dictionary(blocks_dictionary, set_string, "statement_block", {\
			"block_format" : ("Set %s to {value: %s}" % [variable[0], variable_type_string]),
			"statement" : ("%s = {value}" % [variable[0]]),
			"variant_type" : variable[1],\
			"callable" : BlockSystemInterpreter.set_var, \
			"category" : "Variables"})

		if create_blocks:
			block_list.push_back(instantiate_block_from_dictionary(blocks_dictionary, get_string))
			block_list.push_back(instantiate_block_from_dictionary(blocks_dictionary, set_string))

	return block_list
