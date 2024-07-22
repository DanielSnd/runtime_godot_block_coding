class_name VariableCategoryDisplay
extends BlockCategoryDisplay

signal variable_created(created_variable_array)

@onready var variable_blocks := %VariableBlocks
@onready var create_variable_button = %CreateVariableButton

func _set_expanded(value: bool):
	super(value)
	if value and _blocks.get_child_count() == 0:
		_blocks.get_parent().visible = false

func _ready():
	super()
	create_variable_button.create_variable.connect(_on_create_variable)

func _on_create_variable(var_name, var_type):
	variable_created.emit([var_name, BlockConstants.STRING_TO_VARIANT_TYPE[var_type]])
