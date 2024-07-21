class_name BlockCanvas
extends MarginContainer

const EXTEND_MARGIN: float = 800
const BLOCK_AUTO_PLACE_MARGIN: Vector2 = Vector2(16, 8)
const DEFAULT_WINDOW_MARGIN: Vector2 = Vector2(25, 25)
const SNAP_GRID: Vector2 = Vector2(25, 25)
const ZOOM_FACTOR: float = 1.1

@onready var _window: Control = %Window

@onready var _mouse_override: Control = %MouseOverride
@onready var _zoom_label: Label = %ZoomLabel

var block_infos_dictionary:
	get: return BlockSystemInterpreter.block_infos_dict
	set(v):
		BlockSystemInterpreter.block_infos_dict = v
var _current_bsd: BlockScriptData
var _panning := false
var _zooming := false
var _min_zoom :float = 0.2
var _max_zoom :float = 2.0

var window_position:Vector2:
	set(value):
		_window.position = value
		RenderingServer.global_shader_parameter_set("cam_pos_zoom", Vector3(_window.position.x, _window.position.y, 1.0))
	get:
		return _window.position

var zoom: float:
	set(value):
		_window.scale = Vector2(value, value)
		RenderingServer.global_shader_parameter_set("screen_res", get_viewport_rect().size * lerp(1.8,0.45,inverse_lerp(_min_zoom, _max_zoom, zoom)))
		_zoom_label.text = "%.1fx" % value
	get:
		return _window.scale.x

signal reconnect_block(block: Block)

#
func _ready():
	BlockCategoryFactory.add_general_blocks_to_dictionary(block_infos_dictionary)
#
#
#func _populate_block_scenes_by_class():
	#for _class in ProjectSettings.get_global_class_list():
		#if not _class.base.ends_with("Block"):
			#continue
		#var _script = load(_class.path)
		#if not _script.has_method("get_scene_path"):
			#continue
		#_block_scenes_by_class[_class.class] = _script.get_scene_path()


func add_block(block: Block, block_position: Vector2 = Vector2.ZERO) -> void:
	if block is EntryBlock:
		block.position = canvas_to_window(block_position).snapped(SNAP_GRID)
	else:
		block.position = canvas_to_window(block_position)

	_window.add_child(block)


func get_blocks() -> Array[Block]:
	var blocks: Array[Block] = []
	for child in _window.get_children():
		var block = child as Block
		if block:
			blocks.append(block)
	return blocks


func arrange_block(block: Block, nearby_block: Block) -> void:
	add_block(block)
	var rect = nearby_block.get_global_rect()
	rect.position += (rect.size * Vector2.RIGHT) + BLOCK_AUTO_PLACE_MARGIN
	block.global_position = rect.position


func set_child(n: Node):
	n.owner = _window
	for c in n.get_children():
		set_child(c)

#
func bsd_selected(bsd: BlockScriptData):
	clear_canvas()

	window_position = Vector2(0, 0)
	zoom = 1

	_window.visible = false
	_zoom_label.visible = false

	if bsd != null:
		_window.visible = true
		_zoom_label.visible = true
		BlockSystemInterpreter.current_block_tree = bsd.block_trees
		load_tree(_window, bsd.block_trees)

		if bsd != _current_bsd:
			reset_window_position()

	_current_bsd = bsd

	#_choose_block_code_label.visible = false
	#_create_block_code_label.visible = false
#
	#if not bsd and scene_has_bsd_nodes():
		#_choose_block_code_label.visible = true
		#return
	#elif not bsd and not scene_has_bsd_nodes():
		#_create_block_code_label.visible = true
		#return
	#for tree in bsd.block_trees:
		#load_tree(_window, tree)
#
#func scene_has_bsd_nodes() -> bool:
	#var scene_root = EditorInterface.get_edited_scene_root()
	#if not scene_root:
		#return false
	#return scene_root.find_children("*", "BlockCode").size() > 0


func clear_canvas():
	for child in _window.get_children():
		child.queue_free()

func load_tree(parent: Node, block_info: Array):
	if not block_info.is_empty():
		if block_info[0] is String and block_info[0] == "variables":
			BlockSystemInterpreter.variables_data = block_info[1]
			BlockCategoryFactory.get_variable_blocks(block_info[1],BlockSystemInterpreter.block_infos_dict,false)
			return
		if block_info[0] is Array:
			#print("Block info[0] is array ",block_info[0])
			for i in block_info:
				load_tree(parent, i)
		elif block_info[0] is String:
			#print("Block info[0] is string ",block_info[0])
			var scene:Block = BlockCategoryFactory.instantiate_block_from_dictionary(block_infos_dictionary, block_info[0]) as Block
			if scene != null and parent != null:
				if block_info.size() > 2 and block_info[2] is Dictionary:
					for prop_key in block_info[2].keys():
						scene.set(prop_key, block_info[2][prop_key])
				parent.add_child(scene)
				reconnect_block.emit(scene)

				if block_info.size() > 1 and block_info[1] is Array:
					for block_connects in block_info[1]:
						if block_connects is Array and block_connects.size() > 1:
							load_tree(scene.get_node_or_null(block_connects[0]), block_connects[1])

	#if block_info[0] == "root":
		#for root_child in block_info[1]:
			#load_tree(parent,block_info[1])
		#return
	#var scene: Block = BlockCategoryFactory.instantiate_block_from_dictionary(block_infos_dictionary,block_info[0])
	#for prop_pair in node.serialized_block.serialized_props:
		#scene.set(prop_pair[0], prop_pair[1])
#
	#parent.add_child(scene)
#
	#var scene_block: Block = scene as Block
	#reconnect_block.emit(scene_block)
#
	#for c in node.path_child_pairs:
		#load_tree(scene.get_node(c[0]), c[1])

func get_canvas_block_trees() -> Array:
	var block_trees :Array = []
	for c in _window.get_children():
		block_trees.append(build_tree(c))

	return block_trees

func build_tree(block: Block) -> Array:
	if block.has_meta("dont_save") or (not block.has_meta("id")):
		return []
	var n = [block.get_meta("id"),[],{}]

	for i in block.props_to_serialize():
		n[2][i] = block.get(i)

	for snap in find_snaps(block):
		if snap.get_child_count() == 0:
			n[1].push_back([])
		else:
			for c in snap.get_children():
				if c is Block:  # Make sure to not include preview
					if c.has_meta("dont_save"):
						n[1].push_back([])
					else:
						var build_child_tree = build_tree(c)
						if build_child_tree.is_empty():
							n[1].push_back([])
						else:
							n[1].push_back([block.get_path_to(snap), build_child_tree])
	return n

func find_snaps(node: Node) -> Array:
	var snaps := []

	if node.is_in_group("snap_point"):
		snaps.append(node)
	else:
		for c in node.get_children():
			snaps.append_array(find_snaps(c))

	return snaps


func set_scope(scope: String):
	for block in _window.get_children():
		var valid := false

		if block is EntryBlock:
			if scope == block.get_entry_statement():
				valid = true
		else:
			var tree_scope := DragManager.get_tree_scope(block)
			if tree_scope == "" or scope == tree_scope:
				valid = true

		if not valid:
			block.modulate = Color(0.5, 0.5, 0.5, 1)


func release_scope():
	for block in _window.get_children():
		block.modulate = Color.WHITE



func _input(event):
	if event is InputEventKey:
		if event.keycode == KEY_SHIFT:
			set_mouse_override(event.pressed)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed and is_mouse_over():
				_panning = true
			else:
				_panning = false
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed and is_mouse_over():
				_zooming = true
			else:
				_zooming = false

		if event.button_index == MOUSE_BUTTON_MIDDLE:
			set_mouse_override(event.pressed)

		var relative_mouse_pos := get_global_mouse_position() - get_global_rect().position

		if is_mouse_over():
			var old_mouse_window_pos := canvas_to_window(relative_mouse_pos)
			if event.button_index == MOUSE_BUTTON_WHEEL_UP and zoom < _max_zoom:
				zoom *= ZOOM_FACTOR
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and zoom > _min_zoom:
				zoom /= ZOOM_FACTOR
			window_position -= (old_mouse_window_pos - canvas_to_window(relative_mouse_pos)) * zoom

	if event is InputEventMouseMotion:
		if (Input.is_key_pressed(KEY_SHIFT) and _panning) or (Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) and _panning):
			window_position += event.relative

		if Input.is_key_pressed(KEY_SHIFT) and _zooming:
			var relative_mouse_pos := get_global_mouse_position() - get_global_rect().position
			var old_mouse_window_pos := canvas_to_window(relative_mouse_pos)
			#print(_zooming, last_zooming_relative)
			if _zooming and event.relative.y > 0.1 and zoom < 2:
				zoom *= ZOOM_FACTOR
			if _zooming and event.relative.y < -0.1 and zoom > 0.2:
				zoom /= ZOOM_FACTOR
			window_position -= (old_mouse_window_pos - canvas_to_window(relative_mouse_pos)) * zoom

func reset_window_position():
	var blocks = get_blocks()
	var top_left: Vector2 = Vector2.INF

	for block in blocks:
		if block.position.x < top_left.x:
			top_left.x = block.position.x
		if block.position.y < top_left.y:
			top_left.y = block.position.y

	if top_left == Vector2.INF:
		top_left = Vector2.ZERO

	window_position = (-top_left + DEFAULT_WINDOW_MARGIN) * zoom


func canvas_to_window(v: Vector2) -> Vector2:
	return _window.get_transform().affine_inverse() * v


func window_to_canvas(v: Vector2) -> Vector2:
	return _window.get_transform() * v

func is_mouse_over() -> bool:
	return get_global_rect().has_point(get_global_mouse_position())

func set_mouse_override(override: bool):
	if override:
		_mouse_override.mouse_filter = Control.MOUSE_FILTER_PASS
		_mouse_override.mouse_default_cursor_shape = Control.CURSOR_MOVE
	else:
		_mouse_override.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_mouse_override.mouse_default_cursor_shape = Control.CURSOR_ARROW
