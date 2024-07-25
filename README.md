# Runtime Godot Block Coding Plugin

This is a recreation of Endless OS Foundation's awesome work with the [Godot Block Coding Plugin](https://github.com/endlessm/godot-block-coding). This version is focused on being editable and runnable in a runtime godot build, and not in Editor-time as the original is.

To make it work in runtime I changed how they get run, as the original one creates a proper GDScript with the blocks, this one relies on setting up a Callable method for each block, and pass in the block itself and its children so the callable can use the block's connections and variables to do what it needs to do.
