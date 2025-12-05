import socket
import json
import re
from mcp.server.fastmcp import FastMCP

# Optional imports for doc lookup (graceful fallback if not installed)
try:
    import requests
    from bs4 import BeautifulSoup
    DOCS_AVAILABLE = True
except ImportError:
    DOCS_AVAILABLE = False

# Initialize FastMCP server
mcp = FastMCP("Godot Integration")

GODOT_HOST = "127.0.0.1"
GODOT_PORT = 42069

def send_to_godot(method: str, params: dict = None) -> dict:
    """Helper to send JSON commands to the Godot plugin via TCP."""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(5) # 5 second timeout
            try:
                s.connect((GODOT_HOST, GODOT_PORT))
            except ConnectionRefusedError:
                return {"error": "Connection refused. Is Godot running with the MCP Bridge plugin enabled?"}
            
            payload = {"method": method, "params": params or {}}
            msg = json.dumps(payload) + "\n"
            s.sendall(msg.encode('utf-8'))
            
            # Read response (simple line-based protocol)
            buffer = ""
            while True:
                chunk = s.recv(4096)
                if not chunk:
                    break
                buffer += chunk.decode('utf-8')
                if "\n" in buffer:
                    break
            
            if not buffer:
                return {"error": "Empty response from Godot"}
                
            return json.loads(buffer.strip())
            
    except Exception as e:
        return {"error": f"Communication error: {str(e)}"}

@mcp.tool()
def godot_status() -> str:
    """Checks if the Godot Editor is running and listening."""
    response = send_to_godot("ping")
    if response.get("result") == "pong":
        return "Connected: Godot Editor is listening."
    return f"Disconnected: {response.get('error')}"

@mcp.tool()
def godot_get_scene_tree() -> str:
    """Returns the current scene tree structure (nodes and hierarchy) as JSON."""
    response = send_to_godot("get_scene_tree")
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response.get("tree"), indent=2)

@mcp.tool()
def godot_add_node(node_type: str, name: str = "", parent_path: str = ".") -> str:
    """
    Adds a new node to the current scene.
    
    Args:
        node_type: The Class name of the node (e.g., 'Sprite2D', 'Node3D', 'Label').
        name: (Optional) The name for the new node.
        parent_path: (Optional) Path to the parent node. Defaults to '.' (scene root).
    """
    params = {
        "type": node_type,
        "name": name,
        "parent_path": parent_path
    }
    response = send_to_godot("add_node", params)
    if "error" in response:
        return f"Error adding node: {response['error']}"
    return f"Success: Node created at {response.get('path')}"

@mcp.tool()
def godot_execute_code(code: str) -> str:
    """
    Executes a snippet of GDScript in the context of the EditorInterface.
    
    The code is wrapped in a function: `func eval(EditorInterface):`
    You can use `EditorInterface` to access the editor API.
    Return values are converted to string.
    
    Example:
        return EditorInterface.get_edited_scene_root().name
    """
    response = send_to_godot("execute_script", {"code": code})
    if "error" in response:
        return f"Script Error: {response['error']}\nSource:\n{response.get('source', '')}"
    return f"Result: {response.get('result')}"

@mcp.tool()
def godot_get_state() -> str:
    """Debug tool to check Editor state (open scenes, etc)."""
    response = send_to_godot("get_state")
    return json.dumps(response, indent=2)

@mcp.tool()
def godot_get_node_details(path: str) -> str:
    """
    Get detailed properties of a node.
    Args:
        path: Path to the node (e.g. "Player/Sprite2D" or "." for root).
    """
    response = send_to_godot("get_node_details", {"path": path})
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response, indent=2)

@mcp.tool()
def godot_set_property(path: str, property: str, value: str) -> str:
    """
    Set a property on a node.
    Args:
        path: Path to the node (e.g. "Player").
        property: Property name (e.g. "position", "modulate", "text").
        value: The value to set. For Vector3 use "x,y,z".
    """
    response = send_to_godot("set_property", {"path": path, "property": property, "value": value})
    if "error" in response:
        return f"Error: {response['error']}"
    return f"Success: Set {property} to {response.get('new_value')}"

@mcp.tool()
def godot_list_resources(path: str = "res://") -> str:
    """
    List files in the Godot filesystem.
    Args:
        path: Directory to list (defaults to "res://").
    """
    response = send_to_godot("list_dir", {"path": path})
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response.get("files"), indent=2)

@mcp.tool()
def godot_create_script(path: str, content: str) -> str:
    """
    Create or overwrite a GDScript file.
    Args:
        path: Full resource path (e.g. "res://player.gd").
        content: The content of the script.
    """
    response = send_to_godot("save_script", {"path": path, "content": content})
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

@mcp.tool()
def godot_delete_node(path: str) -> str:
    """
    Delete a node from the scene.
    Args:
        path: Path to the node.
    """
    response = send_to_godot("delete_node", {"path": path})
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

@mcp.tool()
def godot_reparent_node(path: str, new_parent_path: str) -> str:
    """
    Move a node to a new parent.
    Args:
        path: Path to the node to move.
        new_parent_path: Path to the new parent.
    """
    response = send_to_godot("reparent_node", {"path": path, "new_parent": new_parent_path})
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

@mcp.tool()
def godot_instantiate_scene(path: str, parent_path: str = ".") -> str:
    """
    Instantiate a .tscn file into the current scene.
    Args:
        path: Resource path (e.g. "res://enemy.tscn").
        parent_path: Where to add it (defaults to root).
    """
    response = send_to_godot("instantiate_scene", {"path": path, "parent_path": parent_path})
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

@mcp.tool()
def godot_save_scene(path: str = "") -> str:
    """
    Save the current scene.
    Args:
        path: (Optional) Path to save to (e.g. "res://main.tscn"). If empty, uses current filename.
    """
    response = send_to_godot("save_scene", {"path": path})
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

@mcp.tool()
def godot_read_script(path: str) -> str:
    """
    Read the content of a GDScript file.
    Args:
        path: Resource path (e.g. "res://player.gd").
    """
    response = send_to_godot("read_script", {"path": path})
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("content")

@mcp.tool()
def godot_signal(source: str, signal: str, target: str, method: str, action: str = "connect") -> str:
    """
    Connect or disconnect a signal.
    Args:
        source: Path to source node
        signal: Signal name (e.g. "body_entered")
        target: Path to target node
        method: Method name (e.g. "_on_body_entered")
        action: "connect" or "disconnect"
    """
    if action == "connect":
        response = send_to_godot("connect_signal", {"source": source, "signal": signal, "target": target, "method": method})
    elif action == "disconnect":
        response = send_to_godot("disconnect_signal", {"source": source, "signal": signal, "target": target, "method": method})
    else:
        return f"Error: Unknown action '{action}'. Use 'connect' or 'disconnect'."
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

@mcp.tool()
def godot_game(action: str = "play") -> str:
    """
    Control game execution.
    Args:
        action: "play" (F5) or "stop" (F8)
    """
    if action == "play":
        response = send_to_godot("play_game")
    elif action == "stop":
        response = send_to_godot("stop_game")
    else:
        return f"Error: Unknown action '{action}'. Use 'play' or 'stop'."
    return response.get("result")

@mcp.tool()
def godot_setup_input_map(action: str, event_type: str, key: str = "", joy_button: int = -1) -> str:
    """
    Add an action to the Input Map.
    Args:
        action: Name of the action (e.g. "move_forward").
        event_type: "key" or "joy".
        key: If key, the key string (e.g. "W", "Space", "Escape").
        joy_button: If joy, the button index (0=A, 1=B, etc).
    """
    params = {
        "action": action, 
        "event_type": event_type,
        "key": key,
        "joy_button": joy_button
    }
    response = send_to_godot("setup_input_map", params)
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

@mcp.tool()
def godot_get_selection() -> str:
    """
    Get the list of currently selected nodes in the editor.
    """
    response = send_to_godot("get_selection")
    return json.dumps(response.get("selection", []), indent=2)

@mcp.tool()
def godot_set_project_setting(name: str, value: str) -> str:
    """
    Set a project setting.
    Args:
        name: Setting path (e.g. "display/window/size/viewport_width").
        value: The value to set (will be auto-converted if possible).
    """
    response = send_to_godot("set_project_setting", {"name": name, "value": value})
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

@mcp.tool()
def godot_create_folder(path: str) -> str:
    """
    Create a folder in the filesystem.
    Args:
        path: Folder path (must start with res://).
    """
    response = send_to_godot("create_folder", {"path": path})
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

@mcp.tool()
def godot_create_shader(path: str, code: str) -> str:
    """
    Create a .gdshader file.
    Args:
        path: Resource path (e.g. "res://water.gdshader").
        code: The shader code.
    """
    response = send_to_godot("create_shader", {"path": path, "code": code})
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

@mcp.tool()
def godot_apply_shader(node_path: str, shader_path: str) -> str:
    """
    Apply a shader to a node (sets material_override or surface_material).
    Args:
        node_path: Path to the target node (MeshInstance3D, etc).
        shader_path: Path to the .gdshader file.
    """
    response = send_to_godot("apply_shader", {"node_path": node_path, "shader_path": shader_path})
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

@mcp.tool()
def godot_rename_node(path: str, new_name: str) -> str:
    """
    Rename a node.
    Args:
        path: Path to the node to rename.
        new_name: The new name for the node.
    """
    response = send_to_godot("rename_node", {"path": path, "new_name": new_name})
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

@mcp.tool()
def godot_duplicate_node(path: str, new_name: str = "") -> str:
    """
    Duplicate a node (and all its children).
    Args:
        path: Path to the node to duplicate.
        new_name: (Optional) Name for the duplicate.
    """
    response = send_to_godot("duplicate_node", {"path": path, "new_name": new_name})
    if "error" in response:
        return f"Error: {response['error']}"
    return f"Duplicated: {response.get('path')}"

@mcp.tool()
def godot_new_scene(root_type: str = "Node3D", name: str = "Root") -> str:
    """
    Create a new empty scene and open it.
    Args:
        root_type: Type of the root node (e.g. "Node2D", "Node3D", "Control").
        name: Name for the root node.
    """
    response = send_to_godot("new_scene", {"root_type": root_type, "name": name})
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

@mcp.tool()
def godot_open_scene(path: str) -> str:
    """
    Open an existing scene file.
    Args:
        path: Resource path to the scene (e.g. "res://levels/level1.tscn").
    """
    response = send_to_godot("open_scene", {"path": path})
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

@mcp.tool()
def godot_list_signals(path: str) -> str:
    """
    List all signals available on a node.
    Args:
        path: Path to the node (e.g. "Player" or "." for root).
    """
    response = send_to_godot("list_signals", {"path": path})
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response.get("signals", []), indent=2)

@mcp.tool()
def godot_list_methods(path: str) -> str:
    """
    List all methods available on a node.
    Args:
        path: Path to the node (e.g. "Player" or "." for root).
    """
    response = send_to_godot("list_methods", {"path": path})
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response.get("methods", []), indent=2)

# ============ Animation Tools ============

@mcp.tool()
def godot_list_animations(player_path: str) -> str:
    """
    List all animations on an AnimationPlayer node.
    Args:
        player_path: Path to the AnimationPlayer node.
    """
    response = send_to_godot("list_animations", {"path": player_path})
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response.get("animations", []), indent=2)

@mcp.tool()
def godot_animation(player_path: str, action: str = "play", animation: str = "", start_time: float = 0.0, backwards: bool = False) -> str:
    """
    Control AnimationPlayer playback.
    Args:
        player_path: Path to the AnimationPlayer node
        action: "play", "stop", or "seek"
        animation: Animation name (required for play)
        start_time: Start/seek time in seconds
        backwards: Play backwards (for seek)
    """
    if action == "play":
        if not animation:
            return "Error: 'animation' parameter required for play action"
        response = send_to_godot("play_animation", {
            "path": player_path,
            "animation": animation,
            "start_time": start_time,
        })
    elif action == "stop":
        response = send_to_godot("stop_animation", {"path": player_path})
    elif action == "seek":
        response = send_to_godot("seek_animation", {
            "path": player_path,
            "time": start_time,
            "update": True,
            "backwards": backwards,
        })
    else:
        return f"Error: Unknown action '{action}'. Use 'play', 'stop', or 'seek'."
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

@mcp.tool()
def godot_create_simple_animation(
    player_path: str,
    animation_name: str,
    node_path: str,
    property: str,
    start_value: str,
    end_value: str,
    duration: float = 1.0,
) -> str:
    """
    Create a simple value animation on a property.
    Args:
        player_path: Path to the AnimationPlayer node.
        animation_name: Name of the animation to create.
        node_path: Path to the node to animate (from scene root).
        property: Property name to animate (e.g. "position", "modulate").
        start_value: Starting value as string (e.g. "0,0,0").
        end_value: Ending value as string (e.g. "0,2,0").
        duration: Duration in seconds.
    """
    response = send_to_godot("create_simple_animation", {
        "player_path": player_path,
        "animation_name": animation_name,
        "node_path": node_path,
        "property": property,
        "start_value": start_value,
        "end_value": end_value,
        "duration": duration,
    })
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response, indent=2)

# ============ Group Management ============

@mcp.tool()
def godot_group(path: str, action: str = "get", group: str = "") -> str:
    """
    Manage node groups.
    Args:
        path: Path to the node
        action: "add", "remove", or "get" (list all groups)
        group: Group name (required for add/remove)
    """
    if action == "get":
        response = send_to_godot("get_groups", {"path": path})
        if "error" in response:
            return f"Error: {response['error']}"
        return json.dumps(response.get("groups", []), indent=2)
    elif action == "add":
        if not group:
            return "Error: 'group' parameter required for add action"
        response = send_to_godot("add_to_group", {"path": path, "group": group})
    elif action == "remove":
        if not group:
            return "Error: 'group' parameter required for remove action"
        response = send_to_godot("remove_from_group", {"path": path, "group": group})
    else:
        return f"Error: Unknown action '{action}'. Use 'add', 'remove', or 'get'."
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

# ============ Audio Tools ============

@mcp.tool()
def godot_create_audio_player(
    parent_path: str = ".",
    name: str = "AudioPlayer",
    is_3d: bool = False,
    audio_path: str = "",
    autoplay: bool = False,
    play_now: bool = False,
) -> str:
    """
    Create an AudioStreamPlayer or AudioStreamPlayer3D, optionally assigning a stream.
    """
    response = send_to_godot("create_audio_player", {
        "parent_path": parent_path,
        "name": name,
        "is_3d": is_3d,
        "audio_path": audio_path,
        "autoplay": autoplay,
        "play_now": play_now,
    })
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response, indent=2)

@mcp.tool()
def godot_audio(path: str, action: str = "play") -> str:
    """
    Control audio playback.
    Args:
        path: Path to AudioStreamPlayer node
        action: "play" or "stop"
    """
    if action == "play":
        response = send_to_godot("play_audio", {"path": path})
    elif action == "stop":
        response = send_to_godot("stop_audio", {"path": path})
    else:
        return f"Error: Unknown action '{action}'. Use 'play' or 'stop'."
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

@mcp.tool()
def godot_set_bus_volume(bus: str, volume_db: float) -> str:
    """
    Set a bus volume in decibels.
    Args:
        bus: Bus name (e.g. "Master").
        volume_db: Volume in dB (e.g. -6.0).
    """
    response = send_to_godot("set_bus_volume", {"bus": bus, "volume_db": volume_db})
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response, indent=2)

# ============ Script Attachment ============

@mcp.tool()
def godot_attach_script(node_path: str, script_path: str) -> str:
    """
    Attach an existing script to a node.
    Args:
        node_path: Path to the node (e.g. "Player").
        script_path: Resource path to the script (e.g. "res://player.gd").
    """
    response = send_to_godot("attach_script", {"node_path": node_path, "script_path": script_path})
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

# ============ Find Nodes ============

@mcp.tool()
def godot_find_nodes_by_type(type: str) -> str:
    """
    Find all nodes of a specific type in the scene.
    Args:
        type: The class name (e.g. "Area3D", "MeshInstance3D", "Label").
    """
    response = send_to_godot("find_nodes_by_type", {"type": type})
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response.get("nodes", []), indent=2)

@mcp.tool()
def godot_find_nodes_by_group(group: str) -> str:
    """
    Find all nodes in a specific group.
    Args:
        group: The group name (e.g. "enemies", "coins").
    """
    response = send_to_godot("find_nodes_by_group", {"group": group})
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response.get("nodes", []), indent=2)

# ============ Debug/Errors ============

@mcp.tool()
def godot_get_errors() -> str:
    """
    Get recent errors from the Godot editor (limited - check Output panel for full logs).
    """
    response = send_to_godot("get_errors", {})
    return json.dumps(response, indent=2)

# ============ Signal Utilities ============

@mcp.tool()
def godot_list_signal_connections(source: str, signal: str = "") -> str:
    """
    List connections for a given node and optional signal.
    Args:
        source: Path to source node.
        signal: Optional signal name to filter.
    """
    params = {"source": source}
    if signal:
        params["signal"] = signal
    response = send_to_godot("list_signal_connections", params)
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response.get("connections", []), indent=2)

# ============ Editor Navigation ============

@mcp.tool()
def godot_focus_node(path: str) -> str:
    """
    Focus the editor camera/selection on a specific node.
    Args:
        path: Path to the node to focus on.
    """
    response = send_to_godot("focus_node", {"path": path})
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

# ============ Screenshots ============

@mcp.tool()
def godot_get_editor_screenshot() -> str:
    """
    Capture a screenshot of the Godot editor window.
    Returns base64-encoded PNG image.
    """
    response = send_to_godot("get_editor_screenshot", {})
    if "error" in response:
        return f"Error: {response['error']}"
    return f"Screenshot captured (base64 PNG, {len(response.get('image_base64', ''))} chars)"

@mcp.tool()
def godot_get_game_screenshot() -> str:
    """
    Capture a screenshot of the running game window.
    Requires game to be running (use godot_play_game first).
    """
    response = send_to_godot("get_game_screenshot", {})
    if "error" in response:
        return f"Error: {response['error']}"
    return f"Screenshot captured (base64 PNG)"

# ============ File Search ============

@mcp.tool()
def godot_search_files(query: str, extension: str = "") -> str:
    """
    Search for files in the project using fuzzy matching.
    Args:
        query: Search query (matches filename).
        extension: Optional file extension filter (e.g. ".gd", ".tscn").
    """
    response = send_to_godot("search_files", {"query": query, "extension": extension})
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response.get("files", []), indent=2)

# ============ UID Conversion ============

@mcp.tool()
def godot_uid(value: str) -> str:
    """
    Convert between UID and resource path.
    Args:
        value: Either a UID (uid://...) or resource path (res://...)
               Auto-detects direction based on prefix.
    """
    if value.startswith("uid://"):
        response = send_to_godot("uid_to_path", {"uid": value})
        if "error" in response:
            return f"Error: {response['error']}"
        return response.get("path")
    elif value.startswith("res://"):
        response = send_to_godot("path_to_uid", {"path": value})
        if "error" in response:
            return f"Error: {response['error']}"
        return response.get("uid")
    else:
        return "Error: Value must start with 'uid://' or 'res://'"

# ============ Scene File Content ============

@mcp.tool()
def godot_get_scene_file_content() -> str:
    """
    Get the raw text content of the current scene file (.tscn).
    Useful for seeing exact property values and resources.
    """
    response = send_to_godot("get_scene_file_content", {})
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("content")

@mcp.tool()
def godot_delete_scene(path: str) -> str:
    """
    Delete a scene file from the project.
    Args:
        path: Path to the scene file (e.g. "res://levels/level1.tscn").
    """
    response = send_to_godot("delete_scene", {"path": path})
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

@mcp.tool()
def godot_duplicate_scene(source_path: str, dest_path: str) -> str:
    """
    Duplicate a scene file.
    Args:
        source_path: Existing .tscn scene path.
        dest_path: New .tscn scene path.
    """
    response = send_to_godot("duplicate_scene", {
        "source_path": source_path,
        "dest_path": dest_path,
    })
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response, indent=2)

@mcp.tool()
def godot_rename_scene(old_path: str, new_path: str) -> str:
    """
    Rename a scene file.
    """
    response = send_to_godot("rename_scene", {
        "old_path": old_path,
        "new_path": new_path,
    })
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response, indent=2)

@mcp.tool()
def godot_replace_resource_in_scene(scene_path: str, old_resource: str, new_resource: str) -> str:
    """
    Replace all uses of a resource path inside a scene file.
    Args:
        scene_path: .tscn path.
        old_resource: Existing resource path to replace.
        new_resource: New resource path.
    """
    response = send_to_godot("replace_resource_in_scene", {
        "scene_path": scene_path,
        "old_resource": old_resource,
        "new_resource": new_resource,
    })
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response, indent=2)

# ============ Add Resource ============

@mcp.tool()
def godot_add_resource(node_path: str, property: str, resource_type: str) -> str:
    """
    Add a new resource to a node's property.
    Args:
        node_path: Path to the node.
        property: Property name (e.g. "shape", "mesh", "texture").
        resource_type: Resource class (e.g. "BoxShape3D", "BoxMesh", "ImageTexture").
    """
    response = send_to_godot("add_resource", {
        "node_path": node_path,
        "property": property,
        "resource_type": resource_type
    })
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

# ============ Macro / Helper Tools ============

@mcp.tool()
def godot_spawn_fps_controller(parent_path: str = ".", name: str = "Player") -> str:
    """
    Spawn a CharacterBody3D-based FPS controller with a Camera3D.
    If res://player.gd exists, it will be attached as the script.
    """
    response = send_to_godot("spawn_fps_controller", {
        "parent_path": parent_path,
        "name": name,
    })
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response, indent=2)

@mcp.tool()
def godot_create_health_bar_ui(parent_path: str = ".", name: str = "HealthBar") -> str:
    """
    Create a simple health bar UI (Control + ProgressBar) anchored top-left.
    """
    response = send_to_godot("create_health_bar_ui", {
        "parent_path": parent_path,
        "name": name,
    })
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response, indent=2)

@mcp.tool()
def godot_spawn_spinning_pickup(parent_path: str = ".", scene_path: str = "res://coin.tscn") -> str:
    """
    Spawn a spinning pickup instance, by default using res://coin.tscn.
    """
    response = send_to_godot("spawn_spinning_pickup", {
        "parent_path": parent_path,
        "scene_path": scene_path,
    })
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response, indent=2)

# ============ UI Anchors ============

@mcp.tool()
def godot_set_anchor_preset(path: str, preset: str) -> str:
    """
    Set a Control node's anchor using a preset.
    Args:
        path: Path to the Control node.
        preset: One of: top_left, top_right, bottom_left, bottom_right,
                center_left, center_right, center_top, center_bottom, center,
                left_wide, right_wide, top_wide, bottom_wide,
                vcenter_wide, hcenter_wide, full_rect
    """
    response = send_to_godot("set_anchor_preset", {"path": path, "preset": preset})
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

@mcp.tool()
def godot_set_anchor_values(path: str, left: float = 0.0, top: float = 0.0, 
                            right: float = 1.0, bottom: float = 1.0) -> str:
    """
    Set precise anchor values for a Control node.
    Args:
        path: Path to the Control node.
        left: Left anchor (0.0 to 1.0).
        top: Top anchor (0.0 to 1.0).
        right: Right anchor (0.0 to 1.0).
        bottom: Bottom anchor (0.0 to 1.0).
    """
    response = send_to_godot("set_anchor_values", {
        "path": path, "left": left, "top": top, "right": right, "bottom": bottom
    })
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

# ============ Open Scripts ============

@mcp.tool()
def godot_get_open_scripts() -> str:
    """
    Get a list of all scripts currently open in the Godot script editor.
    """
    response = send_to_godot("get_open_scripts", {})
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response.get("scripts", []), indent=2)

# ============ Edit File ============

@mcp.tool()
def godot_edit_file(path: str, find: str, replace: str) -> str:
    """
    Edit a file by finding and replacing text.
    Args:
        path: Path to the file (e.g. "res://player.gd").
        find: Text to find.
        replace: Text to replace with.
    """
    response = send_to_godot("edit_file", {"path": path, "find": find, "replace": replace})
    if "error" in response:
        return f"Error: {response['error']}"
    return response.get("result")

# ============ Clear Output ============

@mcp.tool()
def godot_clear_output() -> str:
    """
    Clear/reset the Godot output panel.
    """
    response = send_to_godot("clear_output", {})
    return response.get("result")

# ============ Project Info ============

@mcp.tool()
def godot_get_project_info() -> str:
    """
    Get comprehensive information about the Godot project.
    Includes: name, version, main scene, renderer, window size, physics settings, etc.
    """
    response = send_to_godot("get_project_info", {})
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response, indent=2)

@mcp.tool()
def godot_generate_terrain_mesh(size: int = 32, height_scale: float = 5.0, seed: int = 0, parent_path: str = ".", name: str = "Terrain") -> str:
    """
    Generate a 3D terrain mesh with collision using FastNoiseLite.
    Creates a StaticBody3D with a MeshInstance3D and CollisionShape3D.
    Args:
        size: Width/Depth of the terrain in units (default 32)
        height_scale: Maximum height of the terrain (default 5.0)
        seed: Random seed for noise generation (0 = random)
        parent_path: Parent node path
        name: Name of the created node
    """
    response = send_to_godot("generate_terrain_mesh", {
        "size": size,
        "height_scale": height_scale,
        "seed": seed,
        "parent_path": parent_path,
        "name": name
    })
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response, indent=2)

@mcp.tool()
def godot_create_terrain_material(
    path: str = "res://terrain_material.gdshader",
    type: str = "full",
    texture_scale: float = 0.1,
    blend_sharpness: float = 2.0,
    height_levels: str = "0.0,0.3,0.6,1.0"
) -> str:
    """
    Create a sophisticated terrain shader/material.
    Args:
        path: Output path for .gdshader file (e.g. "res://terrain.gdshader")
        type: Material type - one of:
            - "height_blend": Blend textures by height (grass->dirt->rock->snow)
            - "slope_blend": Blend flat vs steep textures (grass on flat, rock on cliffs)
            - "triplanar": No UV stretching on steep surfaces
            - "full": Complete terrain shader (height + slope + triplanar combined)
        texture_scale: UV scale for textures (smaller = more tiled)
        blend_sharpness: How sharp the transitions are between textures
        height_levels: Comma-separated height thresholds (grass,dirt,rock,snow) as 0.0-1.0
    
    After creation, assign textures in the ShaderMaterial:
        - texture_grass, texture_dirt, texture_rock, texture_snow
        - normal_grass, normal_rock, normal_cliff (for normals)
    """
    response = send_to_godot("create_terrain_material", {
        "path": path,
        "type": type,
        "texture_scale": texture_scale,
        "blend_sharpness": blend_sharpness,
        "height_levels": height_levels
    })
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response, indent=2)

@mcp.tool()
def godot_create_particle_effect(
    preset: str = "fire",
    parent_path: str = ".",
    name: str = "Particles",
    is_3d: bool = True,
    one_shot: bool = False,
    emitting: bool = True
) -> str:
    """
    Create a particle effect with a preset configuration.
    Args:
        preset: Effect type - one of:
            - "fire": Flames rising upward with orange/yellow gradient
            - "smoke": Gray billowing smoke
            - "sparks": Flying bright sparks with gravity
            - "explosion": One-shot burst (auto sets one_shot=true)
            - "magic": Mystical purple/blue swirling particles
            - "rain": Falling rain drops
            - "snow": Gently falling snowflakes
            - "dust": Ground dust/debris
            - "leaves": Falling autumn leaves
            - "blood": Blood splatter (one-shot)
        parent_path: Parent node path
        name: Name for the particle node
        is_3d: True for GPUParticles3D, False for GPUParticles2D
        one_shot: Play once then stop (auto-set for explosion/blood)
        emitting: Start emitting immediately
    """
    response = send_to_godot("create_particle_effect", {
        "preset": preset,
        "parent_path": parent_path,
        "name": name,
        "is_3d": is_3d,
        "one_shot": one_shot,
        "emitting": emitting
    })
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response, indent=2)

@mcp.tool()
def godot_lighting_preset(
    preset: str = "sunny",
    parent_path: str = "."
) -> str:
    """
    Create a complete lighting setup with DirectionalLight3D and WorldEnvironment.
    Args:
        preset: Lighting preset - one of:
            - "sunny": Bright daylight with blue sky and shadows
            - "overcast": Cloudy day with muted colors and fog
            - "sunset": Warm orange/red sunset lighting
            - "night": Dark blue moonlit scene with glow
            - "indoor": Soft ambient lighting for interiors
        parent_path: Parent node path
    """
    response = send_to_godot("lighting_preset", {
        "preset": preset,
        "parent_path": parent_path
    })
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response, indent=2)

@mcp.tool()
def godot_create_primitive(
    shape: str = "box",
    parent_path: str = ".",
    name: str = "Primitive",
    size: float = 1.0,
    color: str = "0.8,0.8,0.8",
    collision: bool = True
) -> str:
    """
    Create a 3D primitive mesh with collision (game-ready by default).
    Args:
        shape: Primitive type - one of:
            - "box": Cube/box mesh
            - "sphere": Sphere mesh
            - "cylinder": Cylinder mesh
            - "capsule": Capsule mesh
            - "plane": Flat plane mesh
            - "prism": Triangular prism
            - "torus": Donut/ring shape
        parent_path: Parent node path
        name: Name for the node
        size: Size of the primitive (units)
        color: RGB color as "r,g,b" (0-1 range), e.g. "1.0,0.5,0.0" for orange
        collision: If true (default), wraps in StaticBody3D with collision shape
    """
    response = send_to_godot("create_primitive", {
        "shape": shape,
        "parent_path": parent_path,
        "name": name,
        "size": size,
        "color": color,
        "collision": collision
    })
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response, indent=2)

@mcp.tool()
def godot_create_ui_template(
    template: str = "main_menu",
    parent_path: str = ".",
    name: str = ""
) -> str:
    """
    Create a complete UI layout template.
    Args:
        template: UI template - one of:
            - "main_menu": Title + Play/Options/Quit buttons
            - "pause_menu": Semi-transparent overlay with Resume/Options/Quit
            - "hud": Health bar, score, ammo, crosshair
            - "dialogue_box": RPG-style dialogue with speaker name
            - "inventory_grid": 5x4 grid of item slots
        parent_path: Parent node path
        name: Optional custom name (defaults to template name)
    """
    response = send_to_godot("create_ui_template", {
        "template": template,
        "parent_path": parent_path,
        "name": name
    })
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response, indent=2)

@mcp.tool()
def godot_create_trigger_area(
    parent_path: str = ".",
    name: str = "TriggerArea",
    shape: str = "box",
    size: float = 2.0
) -> str:
    """
    Create an Area3D with CollisionShape3D ready to detect bodies.
    Perfect for pickups, damage zones, checkpoints, or any trigger.
    
    Args:
        parent_path: Parent node path
        name: Name for the trigger area
        shape: Collision shape type - "box", "sphere", "capsule", "cylinder"
        size: Size of the trigger area
    
    Note: Connect body_entered/body_exited signals to detect player or objects.
    The Area3D comes with collision shape already configured!
    """
    response = send_to_godot("create_trigger_area", {
        "parent_path": parent_path,
        "name": name,
        "shape": shape,
        "size": size
    })
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response, indent=2)

@mcp.tool()
def godot_create_rigidbody(
    parent_path: str = ".",
    name: str = "RigidBody",
    shape: str = "box",
    size: float = 1.0,
    mass: float = 1.0,
    color: str = "0.6,0.6,0.6"
) -> str:
    """
    Create a complete RigidBody3D with collision shape and mesh.
    Perfect for physics objects like crates, barrels, balls, etc.
    
    Args:
        parent_path: Parent node path
        name: Name for the rigid body
        shape: Shape type - "box", "sphere", "capsule", "cylinder"
        size: Size of the object
        mass: Mass in kg (affects physics behavior)
        color: RGB color as "r,g,b" (0-1 range)
    
    The RigidBody3D comes with collision shape AND visual mesh!
    """
    response = send_to_godot("create_rigidbody", {
        "parent_path": parent_path,
        "name": name,
        "shape": shape,
        "size": size,
        "mass": mass,
        "color": color
    })
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response, indent=2)

@mcp.tool()
def godot_save_game_data(
    filename: str = "save.json",
    data: str = "{}"
) -> str:
    """
    Save game data to user:// directory as JSON.
    Args:
        filename: Name of save file (auto-adds .json if missing)
        data: JSON string of data to save (e.g. '{"level": 5, "score": 1000}')
    """
    try:
        parsed_data = json.loads(data)
    except json.JSONDecodeError as e:
        return f"Error: Invalid JSON data - {e}"
    
    response = send_to_godot("save_game_data", {
        "filename": filename,
        "data": parsed_data
    })
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response, indent=2)

@mcp.tool()
def godot_load_game_data(filename: str = "save.json") -> str:
    """
    Load game data from user:// directory.
    Args:
        filename: Name of save file to load
    Returns:
        JSON string containing the loaded data
    """
    response = send_to_godot("load_game_data", {"filename": filename})
    if "error" in response:
        return f"Error: {response['error']}"
    return json.dumps(response, indent=2)

# ============ Godot Documentation Lookup ============

GODOT_DOCS_BASE = "https://docs.godotengine.org/en/stable/classes/class_{}.html"
GODOT_DOCS_SEARCH = "https://docs.godotengine.org/en/stable/search.html?q={}"

@mcp.tool()
def godot_docs(class_name: str) -> str:
    """
    Look up official Godot documentation for a class.
    Args:
        class_name: Name of the Godot class (e.g., "MeshInstance3D", "Area3D", "CharacterBody3D")
    Returns:
        Summary of the class including description, key properties, methods, and signals.
    """
    if not DOCS_AVAILABLE:
        return "Error: requests and beautifulsoup4 not installed. Run: pip install requests beautifulsoup4"
    
    # Normalize class name (e.g., "MeshInstance3D" -> "meshinstance3d")
    class_lower = class_name.lower().replace(" ", "")
    url = GODOT_DOCS_BASE.format(class_lower)
    
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 404:
            return f"Class '{class_name}' not found in Godot documentation. Check spelling."
        response.raise_for_status()
    except requests.RequestException as e:
        return f"Error fetching docs: {e}"
    
    soup = BeautifulSoup(response.text, 'html.parser')
    
    result = []
    result.append(f"# {class_name} - Official Godot Documentation")
    result.append(f"Source: {url}\n")
    
    # Get inheritance chain
    inherits = soup.find('p', string=re.compile(r'Inherits:'))
    if inherits:
        result.append(f"**{inherits.get_text().strip()}**\n")
    
    # Get description
    desc_section = soup.find('section', id='description')
    if desc_section:
        desc_p = desc_section.find('p')
        if desc_p:
            result.append("## Description")
            result.append(desc_p.get_text().strip()[:1000] + "...\n" if len(desc_p.get_text()) > 1000 else desc_p.get_text().strip() + "\n")
    
    # Get properties
    props_section = soup.find('section', id='properties')
    if props_section:
        result.append("## Key Properties")
        prop_table = props_section.find('table')
        if prop_table:
            rows = prop_table.find_all('tr')[:10]  # First 10 properties
            for row in rows:
                cells = row.find_all('td')
                if len(cells) >= 2:
                    prop_type = cells[0].get_text().strip()
                    prop_name = cells[1].get_text().strip()
                    result.append(f"- `{prop_name}` ({prop_type})")
        result.append("")
    
    # Get methods
    methods_section = soup.find('section', id='methods')
    if methods_section:
        result.append("## Key Methods")
        method_table = methods_section.find('table')
        if method_table:
            rows = method_table.find_all('tr')[:15]  # First 15 methods
            for row in rows:
                cells = row.find_all('td')
                if len(cells) >= 2:
                    return_type = cells[0].get_text().strip()
                    method_sig = cells[1].get_text().strip()
                    result.append(f"- `{method_sig}` → {return_type}")
        result.append("")
    
    # Get signals
    signals_section = soup.find('section', id='signals')
    if signals_section:
        result.append("## Signals")
        signal_items = signals_section.find_all('dt', class_='sig')[:8]  # First 8 signals
        for sig in signal_items:
            result.append(f"- `{sig.get_text().strip()}`")
        result.append("")
    
    if len(result) <= 3:
        return f"Documentation found but could not parse content. Visit: {url}"
    
    return "\n".join(result)

@mcp.tool()
def godot_docs_search(query: str) -> str:
    """
    Search the Godot documentation for a topic.
    Args:
        query: Search query (e.g., "collision layers", "animation", "shader uniform")
    Returns:
        List of relevant documentation pages with descriptions.
    """
    if not DOCS_AVAILABLE:
        return "Error: requests and beautifulsoup4 not installed. Run: pip install requests beautifulsoup4"
    
    search_url = f"https://docs.godotengine.org/en/stable/search.html?q={query.replace(' ', '+')}"
    
    try:
        # The Godot docs use JavaScript for search, so we need to use the JSON API
        api_url = f"https://docs.godotengine.org/en/stable/_/api/v2/search/?q={query.replace(' ', '+')}&project=godot&version=stable&language=en"
        response = requests.get(api_url, timeout=10)
        response.raise_for_status()
        data = response.json()
    except requests.RequestException as e:
        return f"Error searching docs: {e}. Try: {search_url}"
    except json.JSONDecodeError:
        return f"Could not parse search results. Try manually: {search_url}"
    
    results = data.get('results', [])
    if not results:
        return f"No results found for '{query}'. Try different keywords or visit: {search_url}"
    
    output = [f"# Search Results for '{query}'", f"Found {len(results)} results:\n"]
    
    for i, item in enumerate(results[:10], 1):  # Top 10 results
        title = item.get('title', 'Untitled')
        path = item.get('path', '')
        # Extract highlights/description
        highlights = item.get('highlights', {})
        content = highlights.get('content', [''])[0] if highlights.get('content') else ''
        
        output.append(f"**{i}. {title}**")
        if path:
            output.append(f"   URL: https://docs.godotengine.org/en/stable/{path}")
        if content:
            # Clean up highlight markers
            clean_content = re.sub(r'<[^>]+>', '', content)[:200]
            output.append(f"   {clean_content}...")
        output.append("")
    
    return "\n".join(output)

if __name__ == "__main__":
    mcp.run()

