# Runtime Godot Block Coding Plugin

This is a recreation of Endless OS Foundation's awesome work with the [Godot Block Coding Plugin](https://github.com/endlessm/godot-block-coding). This version is focused on being editable and runnable in a runtime godot build, and not in Editor-time as the original is.

To make it work in runtime I changed how they get run, as the original one creates a proper GDScript with the blocks, this one relies on setting up a Callable method for each block, and pass in the block itself and its children so the callable can use the block's connections and variables to do what it needs to do.

## Runtime Code Running
The way I went about making the code actually work is probably not the best, but it's working well for me:

The script responsible for actually running the "block code" lives here:
https://github.com/DanielSnd/runtime_godot_block_coding/blob/main/block_code_system/block_system_interpreter.gd

Each block has a static method callable that gets called when that block is going to run, and it passes the **block's array** to it, and a dictionary with variables.
A Block's array is an array that holds ["block_name_string", [] array of block's children, {} dictionary of block_specific parameters]
in the array of block's children each child is an array [NodePath() used to attach the block for the editor, not used in the runtime portion, Block Array described before, ["name", [] children, {} params]]

A serialized block code ends up like this:
![image](https://github.com/user-attachments/assets/8b6db8e7-d350-4d42-a67b-9ff31c5225df)
