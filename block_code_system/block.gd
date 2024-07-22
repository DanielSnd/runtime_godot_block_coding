@icon("res://block_code_system/icons/gear.png")
class_name Block
extends MarginContainer

signal drag_started(block: Block)
@warning_ignore("unused_signal")
signal modified
var block_execute_callable:Callable

@export var block_format: Variant = ""
## Name of the block to be referenced by others in search
@export var block_name: String = ""
## Label of block (optionally used to draw block labels)
@export var label: String = ""
## Color of block (optionally used to draw block color)
@export var color: Color = Color(1., 1., 1.)
## Type of block to check if can be attached to snap point
@export var block_type: BlockConstants.BlockType = BlockConstants.BlockType.EXECUTE
## Category to add the block to
@export var category: String
## The next block in the line of execution (can be null if end)
@export var bottom_snap_path: NodePath
## The scopz of the block (statement of matching entry block)
@export var scope: String = ""

var bottom_snap: SnapPoint

func copy_block_info_to(to_block:Block):
	to_block.block_name = block_name
	to_block.block_type = block_type
	to_block.category = category
	to_block.scope = scope
	to_block.label = label
	to_block.tooltip_text = tooltip_text
	to_block.color = color
	to_block.block_format = block_format
	to_block.block_execute_callable = block_execute_callable
	for i in get_meta_list():
		to_block.set_meta(i, get_meta(i))

func _ready():
	bottom_snap = get_node_or_null(bottom_snap_path)

static func get_block_class():
	push_error("Unimplemented.")

static func get_scene_path():
	push_error("Unimplemented.")

func _drag_started():
	drag_started.emit(self)

func disconnect_signals():
	var connections: Array = drag_started.get_connections()
	for c in connections:
		drag_started.disconnect(c.callable)

func props_to_serialize() -> Array:
	if position != Vector2.ZERO:
		return ["position"]
	return []
