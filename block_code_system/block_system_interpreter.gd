class_name BlockSystemInterpreter
extends Node

static var variables_data:Array = []
static var block_infos_dict:Dictionary = {}
static var current_block_tree:Array = []

static func find_entry_block_with_type(blocks_array:Array, block_type:String) -> Array:
	for block:Array in blocks_array:
		if block is Array and block.size() == 2:
			continue
		if block is Array and block[0] is String and BlockSystemInterpreter.block_infos_dict.has(block[0]) and block[0] == block_type:
			return block
		if block is Array and block[0] is String and block[2].has("pinput") and block[2].get("pinput",{}).get("method_name","").strip_edges() == block_type.strip_edges():
			return block
	return []

static func get_callable_from_block_array(block) -> Array:
	if block is Array and block[0] is NodePath and block.size() > 1: block = block[1]
	if block is Array and block[0] is String:
		if BlockSystemInterpreter.block_infos_dict.has(block[0]):
			var block_info = BlockSystemInterpreter.block_infos_dict[block[0]]
			var callable_func:Callable = block_info.get("callable", execute_block)
			print("[%s] executing callable [%s]" % [block_info.id, str(callable_func.get_method()) if not callable_func.is_null() else "null"])
			if callable_func.is_valid(): return [true, callable_func]
	return [false,execute_block]

static func repeat_block(block:Array, variables_dict:Dictionary):
	var repeat_number:int = int(block[2].get("pinput_array",[{}])[0].get("number",1)) as int
	var block_children:Array = block[1]
	#print_last_child(block)
	## Try to get the repeat number from snap point 0
	if not block_children[0].is_empty():
		repeat_number =  attempt_call_block(block_children[0], variables_dict)
	## Try to repeat the snap point inside
	if not block_children[2].is_empty():
		for i in max(repeat_number,0):
			variables_dict["_index"] = i
			attempt_call_block(block_children[2],variables_dict)
	return continue_chain(block,variables_dict)

static func call_method(block:Array, variables_dict:Dictionary):
	var call_method_name = str(block[2].get("pinput",{}).get("method_name","")).strip_edges()
	if (not block[1].is_empty()) and not (block[1][0].is_empty()):
		var new_method_name = str(attempt_call_block(block[1][0], variables_dict)).strip_edges()
		if new_method_name != "false" and new_method_name != "true":
			call_method_name = new_method_name
	var method_block = BlockSystemInterpreter.find_entry_block_with_type(current_block_tree, call_method_name)
	if not method_block.is_empty():
		attempt_call_block(method_block,variables_dict)
	return continue_chain(block,variables_dict)

static func continue_chain(block:Array, variables_dict:Dictionary):
	if block.is_empty() or block.size() < 2 or block[1].is_empty(): return false
	return attempt_call_block(block[1][block[1].size() - 1], variables_dict)

static func attempt_call_block(block:Array, variables_dict:Dictionary):
	if block.is_empty(): return false
	if block.size() == 2 and not block[1].is_empty():
		if block[1].size() > 2 and block[1][1].is_empty() and block[1][2] is Dictionary and block[1][2].has("poutput"):
			return variables_dict.get(block[1][2]["poutput"].get("statement",""),false)
	return get_callable_from_block_array(block)[1].call(block[1] if block[1] is Array and block[1].size() != 2 else block, variables_dict)

static func execute_block(block:Array, variables_dict:Dictionary):
	return continue_chain(block,variables_dict)

static func get_var(block:Array, variables_dict:Dictionary):
	return variables_dict.get((block[0] as String).substr("get_var_".length()),0)

static func set_var(block:Array, variables_dict:Dictionary):
	var new_var_desired = block[2].get("pinput",{}).get("value",0)
	if not block[1][0].is_empty():
		var var_input :Array= block[1][0][1]
		if var_input.size() > 2:
			if var_input[2].has("poutput"):
				var var_output = var_input[2]["poutput"].get("statement","")
				new_var_desired = variables_dict.get(var_output,0)
			else:
				new_var_desired = attempt_call_block(block[1][0], variables_dict)
	variables_dict[(block[0] as String).substr("set_var_".length())] = new_var_desired
	return continue_chain(block,variables_dict)

static func print_block(block:Array, variables_dict:Dictionary):
	print(str(block[2].get("pinput",{"text":""}).get("text","")).format(variables_dict))
	return continue_chain(block, variables_dict)

static func compare_numbers(block:Array, _variables_dict:Dictionary) -> bool:
	var block_params:Dictionary = block[2].get("pinput",{})
	var int1 = int(block_params.get("int1",0)) as int
	var int2 = int(block_params.get("int2",0)) as int
	var operation = block_params.get("op",[0])[0]
	if not block[1][0].is_empty():
		var int1_input :Array= block[1][0][1]
		if int1_input.size() > 2:
			if int1_input[2].has("poutput"):
				var int1_output = int1_input[2]["poutput"].get("statement","")
				int1 = _variables_dict.get(int1_output,0)
			else:
				int1 = int(attempt_call_block(block[1][0], _variables_dict) as int)

	if not block[1][2].is_empty():
		var int2_input :Array= block[1][2][1]
		if int2_input.size() > 2:
			if int2_input[2].has("poutput"):
				var int2_output = int2_input[2]["poutput"].get("statement","")
				int2 = _variables_dict.get(int2_output,0)
			else:
				int2 = int(attempt_call_block(block[1][2], _variables_dict) as int)

	## TODO: Get int1 or int2 from children slots.
	match operation:
		0: return int1 == int2
		1: return int1 > int2
		2: return int1 < int2
		3: return int1 >= int2
		4: return int1 <= int2
		5: return int1 != int2
	return false

static func boolean_not(block:Array, variables_dict:Dictionary) -> bool:
	return not (block[2].get("pinput",{}).get("bool",false) if block[1][0].is_empty() else attempt_call_block(block[1][0], variables_dict))

static func boolean_and(block:Array, variables_dict:Dictionary) -> bool:
	var block_params:Dictionary = block[2].get("pinput",{})
	return (block_params.get("bool1",0) if block[1][0].is_empty() else attempt_call_block(block[1][0], variables_dict)) and (block_params.get("bool2",0) if block[1][1].is_empty() else attempt_call_block(block[1][1], variables_dict))

static func boolean_or(block:Array, variables_dict:Dictionary) -> bool:
	var block_params:Dictionary = block[2].get("pinput",{})
	return (block_params.get("bool1",0) if block[1][0].is_empty() else attempt_call_block(block[1][0], variables_dict)) or (block_params.get("bool2",0) if block[1][1].is_empty() else attempt_call_block(block[1][1], variables_dict))

static func get_last_valid_child(block:Array) -> Array:
	if not block.is_empty():
		for i in range(block[1].size()-1, -1 , max(block[1].size() - 3,-1)):
			if block[1][i].size() > 1:
				return [i, block[1][1]]
	return [-1, []]

static func print_last_child(block:Array):
	if block.is_empty():
		return
	var desired_last_block:Array = []
	for i in range(block[1].size()-1, -1 , -1):
		if block[1][i].size() > 1:
			desired_last_block = block[1][i]
			break
	if desired_last_block.size() > 1:
		return desired_last_block[1]
		#print("[%s] Last child is %s" % [str(block[0]), str(desired_last_block[1][0])])
	pass
#add_block_type_to_dictionary(blocks_dictionary, "compare_numbers", "parameter_block", {"block_format": "{int1: INT} {op: OPTION} {int2: INT}", "defaults" : {"op": [1,["==", ">", "<", ">=", "<=", "!="]]}, "variant_type" : Variant.Type.TYPE_BOOL, "category" : "Logic | Comparison"})
#
	#for op in ["and", "or"]:
		#add_block_type_to_dictionary(blocks_dictionary, ("boolean_%s" % op), "parameter_block", {"block_format": ("{bool1: BOOL} %s {bool2: BOOL}" % op), "variant_type" : Variant.Type.TYPE_BOOL, "category" : "Logic | Boolean"})
#
	#add_block_type_to_dictionary(blocks_dictionary, "boolean_not", "parameter_block", {"block_format": "Not {bool: BOOL}", "variant_type" : Variant.Type.TYPE_BOOL, "category" : "Logic | Boolean"})
	#
static func if_then(block:Array, variables_dict:Dictionary) -> bool:
	#print_last_child(block)
	var block_children:Array = block[1]
	var block_params:Dictionary = block[2].get("pinput_array",[{}])[0]
	var p_condition:bool = block_params.get("condition", true)
	variables_dict.erase("last_if")

	if not block_children[0].is_empty():
		p_condition = attempt_call_block(block_children[0], variables_dict)

	variables_dict.erase("last_if")
	if p_condition and not block_children[1].is_empty():
		attempt_call_block(block_children[1], variables_dict)

	variables_dict["last_if"] = p_condition
	return continue_chain(block, variables_dict)

static func else_if(block:Array, variables_dict:Dictionary) -> bool:
	if variables_dict.get("last_if",false) == true:
		return continue_chain(block, variables_dict)
	var p_condition:bool = block[2].get("pinput_array",[{}])[0].get("condition", true)
	variables_dict.erase("last_if")

	if not block[1][0].is_empty():
		p_condition = attempt_call_block(block[1][0], variables_dict)
		variables_dict.erase("last_if")

	if p_condition:
		attempt_call_block(block[1][1], variables_dict)
		variables_dict["last_if"] = true
	return continue_chain(block, variables_dict)

static func then_else(block:Array, variables_dict:Dictionary) -> bool:
	var block_children:Array = block[1]
	if variables_dict.get("last_if",false) == false:
		attempt_call_block(block_children[0], variables_dict)
	variables_dict.erase("last_if")
	return continue_chain(block, variables_dict)