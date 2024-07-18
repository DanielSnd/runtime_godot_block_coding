class_name BlockCategoryDisplay
extends MarginContainer

var category: BlockCategory

@onready var _label := %Label
@onready var _blocks := %Blocks

func on_label_pressed():
	var should_be_visible = not _blocks.get_parent().visible
	_blocks.get_parent().visible = should_be_visible
	_label.modulate.a = 1.0 if should_be_visible else 0.4
	(_label.get_parent() as MarginContainer).add_theme_constant_override("margin_bottom",4 if should_be_visible else 0.0)
	#if not _blocks.get_parent().visible:
		#_label.get_parent().size.y = 15
		#_label.get_parent().get_parent().size.y = 15
		#size.y = 15

func _ready():
	if _label.get_parent().has_signal("pressed"):
		_label.get_parent().pressed.connect(on_label_pressed)
	_label.text = category.name

	for _block in category.block_list:
		var block: Block = _block as Block

		block.color = category.color

		_blocks.add_child(block)
		
	on_label_pressed()
