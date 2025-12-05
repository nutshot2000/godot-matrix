@tool
extends EditorPlugin

var server_node

func _enter_tree():
	# Load and instance the server node
	var server_script = preload("server.gd")
	server_node = server_script.new()
	# Add it as a child so it gets _process updates
	add_child(server_node)
	print("MCP Bridge: Plugin initialized and server started")

func _exit_tree():
	# Cleanup
	if server_node:
		remove_child(server_node)
		server_node.queue_free()
		server_node = null
	print("MCP Bridge: Plugin disabled")

