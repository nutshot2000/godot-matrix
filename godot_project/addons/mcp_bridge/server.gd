@tool
extends Node

const PORT = 42069
var server := TCPServer.new()
var peers: Array[StreamPeerTCP] = []

func _ready():
	var err = server.listen(PORT)
	if err == OK:
		print("MCP Bridge: Listening on port %d" % PORT)
	else:
		printerr("MCP Bridge: Failed to listen on port %d. Error: %d" % [PORT, err])

func _process(_delta):
	# Accept new connections
	if server.is_connection_available():
		var peer = server.take_connection()
		peers.append(peer)
		print("MCP Bridge: Client connected")

	# Process existing connections
	var active_peers: Array[StreamPeerTCP] = []
	for peer in peers:
		peer.poll()
		var status = peer.get_status()
		if status == StreamPeerTCP.STATUS_CONNECTED:
			active_peers.append(peer)
			if peer.get_available_bytes() > 0:
				_handle_data(peer)
		elif status == StreamPeerTCP.STATUS_NONE or status == StreamPeerTCP.STATUS_ERROR:
			print("MCP Bridge: Client disconnected")
	
	peers = active_peers

func _handle_data(peer: StreamPeerTCP):
	# Simple protocol: One JSON object per line or just raw JSON if small.
	# For robustness, we'll assume the client sends one JSON object at a time.
	# In a real scenario, we might need length prefixing.
	# For now, let's read all available text.
	var text = peer.get_utf8_string(peer.get_available_bytes())
	if text.is_empty():
		return

	# Handle multiple commands if they come in a batch (newline separated)
	var lines = text.split("\n", false)
	for line in lines:
		var json = JSON.new()
		var error = json.parse(line)
		if error == OK:
			var command = json.data
			var response = _execute_command(command)
			peer.put_data(JSON.stringify(response).to_utf8_buffer())
			peer.put_data("\n".to_utf8_buffer()) # Delimiter
		else:
			printerr("MCP Bridge: JSON Parse Error: ", json.get_error_message())

func _execute_command(cmd: Dictionary) -> Dictionary:
	if not "method" in cmd:
		return {"error": "No method specified"}

	match cmd["method"]:
		"ping":
			return {"result": "pong"}
		"get_scene_tree":
			return _get_scene_tree()
		"add_node":
			return _add_node(cmd.get("params", {}))
		"execute_script":
			return _execute_script(cmd.get("params", {}))
		"get_state":
			return _get_state()
		"get_node_details":
			return _get_node_details(cmd.get("params", {}))
		"set_property":
			return _set_property(cmd.get("params", {}))
		"list_dir":
			return _list_dir(cmd.get("params", {}))
		"save_script":
			return _save_script(cmd.get("params", {}))
		"delete_node":
			return _delete_node(cmd.get("params", {}))
		"reparent_node":
			return _reparent_node(cmd.get("params", {}))
		"instantiate_scene":
			return _instantiate_scene(cmd.get("params", {}))
		"save_scene":
			return _save_scene(cmd.get("params", {}))
		"connect_signal":
			return _connect_signal(cmd.get("params", {}))
		"play_game":
			return _play_game(cmd.get("params", {}))
		"stop_game":
			return _stop_game(cmd.get("params", {}))
		"read_script":
			return _read_script(cmd.get("params", {}))
		"setup_input_map":
			return _setup_input_map(cmd.get("params", {}))
		"get_selection":
			return _get_selection(cmd.get("params", {}))
		"set_project_setting":
			return _set_project_setting(cmd.get("params", {}))
		"create_folder":
			return _create_folder(cmd.get("params", {}))
		"create_shader":
			return _create_shader(cmd.get("params", {}))
		"apply_shader":
			return _apply_shader(cmd.get("params", {}))
		"rename_node":
			return _rename_node(cmd.get("params", {}))
		"duplicate_node":
			return _duplicate_node(cmd.get("params", {}))
		"new_scene":
			return _new_scene(cmd.get("params", {}))
		"open_scene":
			return _open_scene(cmd.get("params", {}))
		"list_signals":
			return _list_signals(cmd.get("params", {}))
		"list_methods":
			return _list_methods(cmd.get("params", {}))
		"add_to_group":
			return _add_to_group(cmd.get("params", {}))
		"remove_from_group":
			return _remove_from_group(cmd.get("params", {}))
		"get_groups":
			return _get_groups(cmd.get("params", {}))
		"attach_script":
			return _attach_script(cmd.get("params", {}))
		"find_nodes_by_type":
			return _find_nodes_by_type(cmd.get("params", {}))
		"find_nodes_by_group":
			return _find_nodes_by_group(cmd.get("params", {}))
		"get_errors":
			return _get_errors(cmd.get("params", {}))
		"focus_node":
			return _focus_node(cmd.get("params", {}))
		"get_editor_screenshot":
			return _get_editor_screenshot(cmd.get("params", {}))
		"get_game_screenshot":
			return _get_game_screenshot(cmd.get("params", {}))
		"search_files":
			return _search_files(cmd.get("params", {}))
		"uid_to_path":
			return _uid_to_path(cmd.get("params", {}))
		"path_to_uid":
			return _path_to_uid(cmd.get("params", {}))
		"get_scene_file_content":
			return _get_scene_file_content(cmd.get("params", {}))
		"delete_scene":
			return _delete_scene(cmd.get("params", {}))
		"add_resource":
			return _add_resource(cmd.get("params", {}))
		"set_anchor_preset":
			return _set_anchor_preset(cmd.get("params", {}))
		"set_anchor_values":
			return _set_anchor_values(cmd.get("params", {}))
		"get_open_scripts":
			return _get_open_scripts(cmd.get("params", {}))
		"edit_file":
			return _edit_file(cmd.get("params", {}))
		"clear_output":
			return _clear_output(cmd.get("params", {}))
		"get_project_info":
			return _get_project_info(cmd.get("params", {}))
		"list_animations":
			return _list_animations(cmd.get("params", {}))
		"play_animation":
			return _play_animation(cmd.get("params", {}))
		"stop_animation":
			return _stop_animation(cmd.get("params", {}))
		"seek_animation":
			return _seek_animation(cmd.get("params", {}))
		"create_simple_animation":
			return _create_simple_animation(cmd.get("params", {}))
		"create_audio_player":
			return _create_audio_player(cmd.get("params", {}))
		"play_audio":
			return _play_audio(cmd.get("params", {}))
		"stop_audio":
			return _stop_audio(cmd.get("params", {}))
		"set_bus_volume":
			return _set_bus_volume(cmd.get("params", {}))
		"disconnect_signal":
			return _disconnect_signal(cmd.get("params", {}))
		"list_signal_connections":
			return _list_signal_connections(cmd.get("params", {}))
		"duplicate_scene":
			return _duplicate_scene(cmd.get("params", {}))
		"rename_scene":
			return _rename_scene(cmd.get("params", {}))
		"replace_resource_in_scene":
			return _replace_resource_in_scene(cmd.get("params", {}))
		"spawn_fps_controller":
			return _spawn_fps_controller(cmd.get("params", {}))
		"create_health_bar_ui":
			return _create_health_bar_ui(cmd.get("params", {}))
		"spawn_spinning_pickup":
			return _spawn_spinning_pickup(cmd.get("params", {}))
		"create_trigger_area":
			return _create_trigger_area(cmd.get("params", {}))
		"create_rigidbody":
			return _create_rigidbody(cmd.get("params", {}))
		"generate_terrain_mesh":
			return _generate_terrain_mesh(cmd.get("params", {}))
		"create_terrain_material":
			return _create_terrain_material(cmd.get("params", {}))
		"create_particle_effect":
			return _create_particle_effect(cmd.get("params", {}))
		"lighting_preset":
			return _lighting_preset(cmd.get("params", {}))
		"create_primitive":
			return _create_primitive(cmd.get("params", {}))
		"create_ui_template":
			return _create_ui_template(cmd.get("params", {}))
		"save_game_data":
			return _save_game_data(cmd.get("params", {}))
		"load_game_data":
			return _load_game_data(cmd.get("params", {}))
		_:
			return {"error": "Unknown method: " + cmd["method"]}

#
# ============ NEW: Terrain Tools ============
#

func _generate_terrain_mesh(params: Dictionary) -> Dictionary:
	var size = int(params.get("size", 32))
	var height_scale = float(params.get("height_scale", 5.0))
	var noise_seed = int(params.get("seed", randi()))
	var parent_path = params.get("parent_path", ".")
	var name = params.get("name", "Terrain")
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	var parent = root.get_node_or_null(parent_path) if parent_path != "." else root
	if not parent: return {"error": "Parent not found"}
	
	# 1. Generate Noise
	var noise = FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = 0.05
	
	# 2. Build Mesh with SurfaceTool
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Simple UV mapping and normals
	for z in range(size):
		for x in range(size):
			# Two triangles per quad
			# Vertices
			var h1 = noise.get_noise_2d(x, z) * height_scale
			var h2 = noise.get_noise_2d(x + 1, z) * height_scale
			var h3 = noise.get_noise_2d(x, z + 1) * height_scale
			var h4 = noise.get_noise_2d(x + 1, z + 1) * height_scale
			
			var v1 = Vector3(x, h1, z)
			var v2 = Vector3(x + 1, h2, z)
			var v3 = Vector3(x, h3, z + 1)
			var v4 = Vector3(x + 1, h4, z + 1)
			
			# Triangle 1 (v1, v2, v3)
			st.set_uv(Vector2(x, z))
			st.add_vertex(v1)
			st.set_uv(Vector2(x + 1, z))
			st.add_vertex(v2)
			st.set_uv(Vector2(x, z + 1))
			st.add_vertex(v3)
			
			# Triangle 2 (v2, v4, v3)
			st.set_uv(Vector2(x + 1, z))
			st.add_vertex(v2)
			st.set_uv(Vector2(x + 1, z + 1))
			st.add_vertex(v4)
			st.set_uv(Vector2(x, z + 1))
			st.add_vertex(v3)
	
	st.generate_normals()
	var mesh = st.commit()
	
	# 3. Create Node Structure
	var body = StaticBody3D.new()
	body.name = name
	body.set_meta("_edit_group_", true)
	parent.add_child(body)
	body.owner = root
	
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "Mesh"
	mesh_inst.mesh = mesh
	body.add_child(mesh_inst)
	mesh_inst.owner = root
	
	# 4. Create Collision
	var shape = CollisionShape3D.new()
	shape.name = "Collision"
	shape.shape = mesh.create_trimesh_shape()
	body.add_child(shape)
	shape.owner = root
	
	# 5. Center it (optional, but nice)
	body.position = Vector3(-size / 2.0, 0, -size / 2.0)
	
	return {"result": "Terrain generated", "path": str(body.get_path())}

func _create_terrain_material(params: Dictionary) -> Dictionary:
	var shader_path = params.get("path", "res://terrain_material.gdshader")
	var material_type = params.get("type", "height_blend")  # height_blend, slope_blend, triplanar, full
	var texture_scale = float(params.get("texture_scale", 0.1))
	var blend_sharpness = float(params.get("blend_sharpness", 2.0))
	var height_levels = params.get("height_levels", "0.0,0.3,0.6,1.0")  # grass, dirt, rock, snow
	
	if not shader_path.ends_with(".gdshader"):
		return {"error": "Path must end with .gdshader"}
	
	var shader_code = ""
	
	match material_type:
		"height_blend":
			shader_code = _generate_height_blend_shader(texture_scale, blend_sharpness, height_levels)
		"slope_blend":
			shader_code = _generate_slope_blend_shader(texture_scale, blend_sharpness)
		"triplanar":
			shader_code = _generate_triplanar_shader(texture_scale)
		"full":
			shader_code = _generate_full_terrain_shader(texture_scale, blend_sharpness, height_levels)
		_:
			return {"error": "Unknown material type. Use: height_blend, slope_blend, triplanar, full"}
	
	var file = FileAccess.open(shader_path, FileAccess.WRITE)
	if not file:
		return {"error": "Could not write shader file"}
	file.store_string(shader_code)
	file.close()
	
	EditorInterface.get_resource_filesystem().scan()
	return {"result": "Terrain material created", "path": shader_path, "type": material_type}

func _generate_height_blend_shader(tex_scale: float, sharpness: float, heights: String) -> String:
	var h = heights.split(",")
	var h0 = float(h[0]) if h.size() > 0 else 0.0
	var h1 = float(h[1]) if h.size() > 1 else 0.3
	var h2 = float(h[2]) if h.size() > 2 else 0.6
	var h3 = float(h[3]) if h.size() > 3 else 1.0
	
	return """shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Texture layers (assign in material)
uniform sampler2D texture_grass : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_dirt : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_rock : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_snow : source_color, filter_linear_mipmap, repeat_enable;

// Normal maps (optional)
uniform sampler2D normal_grass : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_rock : hint_normal, filter_linear_mipmap, repeat_enable;

// Parameters
uniform float texture_scale : hint_range(0.01, 1.0) = """ + str(tex_scale) + """;
uniform float blend_sharpness : hint_range(0.1, 10.0) = """ + str(sharpness) + """;
uniform float height_grass : hint_range(0.0, 1.0) = """ + str(h0) + """;
uniform float height_dirt : hint_range(0.0, 1.0) = """ + str(h1) + """;
uniform float height_rock : hint_range(0.0, 1.0) = """ + str(h2) + """;
uniform float height_snow : hint_range(0.0, 1.0) = """ + str(h3) + """;
uniform float max_terrain_height = 10.0;

// PBR
uniform float roughness_base : hint_range(0.0, 1.0) = 0.8;
uniform float metallic_base : hint_range(0.0, 1.0) = 0.0;

varying float vertex_height;

void vertex() {
    vertex_height = VERTEX.y / max_terrain_height;
}

void fragment() {
    vec2 uv_scaled = UV * (1.0 / texture_scale);
    
    // Sample textures
    vec3 grass = texture(texture_grass, uv_scaled).rgb;
    vec3 dirt = texture(texture_dirt, uv_scaled).rgb;
    vec3 rock = texture(texture_rock, uv_scaled).rgb;
    vec3 snow = texture(texture_snow, uv_scaled).rgb;
    
    // Height-based blend weights
    float h = clamp(vertex_height, 0.0, 1.0);
    
    float w_grass = 1.0 - smoothstep(height_grass, height_dirt, h);
    float w_dirt = smoothstep(height_grass, height_dirt, h) * (1.0 - smoothstep(height_dirt, height_rock, h));
    float w_rock = smoothstep(height_dirt, height_rock, h) * (1.0 - smoothstep(height_rock, height_snow, h));
    float w_snow = smoothstep(height_rock, height_snow, h);
    
    // Sharpen blends
    w_grass = pow(w_grass, blend_sharpness);
    w_dirt = pow(w_dirt, blend_sharpness);
    w_rock = pow(w_rock, blend_sharpness);
    w_snow = pow(w_snow, blend_sharpness);
    
    // Normalize
    float total = w_grass + w_dirt + w_rock + w_snow + 0.001;
    w_grass /= total;
    w_dirt /= total;
    w_rock /= total;
    w_snow /= total;
    
    // Final color
    ALBEDO = grass * w_grass + dirt * w_dirt + rock * w_rock + snow * w_snow;
    
    // Normal blending (simplified)
    vec3 n_grass = texture(normal_grass, uv_scaled).rgb * 2.0 - 1.0;
    vec3 n_rock = texture(normal_rock, uv_scaled).rgb * 2.0 - 1.0;
    NORMAL_MAP = normalize(mix(n_grass, n_rock, w_rock + w_snow) * 0.5 + 0.5);
    
    ROUGHNESS = roughness_base;
    METALLIC = metallic_base;
}
"""

func _generate_slope_blend_shader(tex_scale: float, sharpness: float) -> String:
	return """shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D texture_flat : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_steep : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_flat : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_steep : hint_normal, filter_linear_mipmap, repeat_enable;

uniform float texture_scale : hint_range(0.01, 1.0) = """ + str(tex_scale) + """;
uniform float slope_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float blend_sharpness : hint_range(0.1, 10.0) = """ + str(sharpness) + """;
uniform float roughness_flat : hint_range(0.0, 1.0) = 0.7;
uniform float roughness_steep : hint_range(0.0, 1.0) = 0.9;

void fragment() {
    vec2 uv_scaled = UV * (1.0 / texture_scale);
    
    // Calculate slope from world normal
    vec3 world_normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
    float slope = 1.0 - abs(world_normal.y);  // 0 = flat, 1 = vertical
    
    // Blend factor
    float blend = smoothstep(slope_threshold - 0.1, slope_threshold + 0.1, slope);
    blend = pow(blend, blend_sharpness);
    
    // Sample textures
    vec3 flat_color = texture(texture_flat, uv_scaled).rgb;
    vec3 steep_color = texture(texture_steep, uv_scaled).rgb;
    
    ALBEDO = mix(flat_color, steep_color, blend);
    
    // Normals
    vec3 n_flat = texture(normal_flat, uv_scaled).rgb;
    vec3 n_steep = texture(normal_steep, uv_scaled).rgb;
    NORMAL_MAP = mix(n_flat, n_steep, blend);
    
    ROUGHNESS = mix(roughness_flat, roughness_steep, blend);
    METALLIC = 0.0;
}
"""

func _generate_triplanar_shader(tex_scale: float) -> String:
	return """shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_normal : hint_normal, filter_linear_mipmap, repeat_enable;

uniform float texture_scale : hint_range(0.01, 1.0) = """ + str(tex_scale) + """;
uniform float blend_sharpness : hint_range(0.1, 10.0) = 2.0;
uniform vec4 albedo_tint : source_color = vec4(1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.8;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
    // Triplanar blend weights from world normal
    vec3 blend = abs(world_normal);
    blend = pow(blend, vec3(blend_sharpness));
    blend /= (blend.x + blend.y + blend.z);
    
    // UV coordinates for each axis
    vec2 uv_x = world_pos.zy * texture_scale;
    vec2 uv_y = world_pos.xz * texture_scale;
    vec2 uv_z = world_pos.xy * texture_scale;
    
    // Sample textures from 3 projections
    vec3 col_x = texture(texture_albedo, uv_x).rgb;
    vec3 col_y = texture(texture_albedo, uv_y).rgb;
    vec3 col_z = texture(texture_albedo, uv_z).rgb;
    
    // Blend
    ALBEDO = (col_x * blend.x + col_y * blend.y + col_z * blend.z) * albedo_tint.rgb;
    
    // Triplanar normals
    vec3 n_x = texture(texture_normal, uv_x).rgb * 2.0 - 1.0;
    vec3 n_y = texture(texture_normal, uv_y).rgb * 2.0 - 1.0;
    vec3 n_z = texture(texture_normal, uv_z).rgb * 2.0 - 1.0;
    
    // Swizzle normals for correct orientation
    n_x = vec3(n_x.zy, n_x.x);
    n_y = vec3(n_y.x, n_y.z, n_y.y);
    n_z = vec3(n_z.xy, n_z.z);
    
    vec3 blended_normal = normalize(n_x * blend.x + n_y * blend.y + n_z * blend.z);
    NORMAL_MAP = blended_normal * 0.5 + 0.5;
    
    ROUGHNESS = roughness;
    METALLIC = 0.0;
}
"""

func _generate_full_terrain_shader(tex_scale: float, sharpness: float, heights: String) -> String:
	var h = heights.split(",")
	var h0 = float(h[0]) if h.size() > 0 else 0.0
	var h1 = float(h[1]) if h.size() > 1 else 0.3
	var h2 = float(h[2]) if h.size() > 2 else 0.6
	var h3 = float(h[3]) if h.size() > 3 else 1.0
	
	return """shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// ===== FULL TERRAIN SHADER =====
// Combines: Height blending, Slope blending, Triplanar projection

// Texture layers
uniform sampler2D texture_grass : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_dirt : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_rock : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_snow : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_cliff : source_color, filter_linear_mipmap, repeat_enable;

// Normal maps
uniform sampler2D normal_grass : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_rock : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_cliff : hint_normal, filter_linear_mipmap, repeat_enable;

// Height thresholds
uniform float height_grass : hint_range(0.0, 1.0) = """ + str(h0) + """;
uniform float height_dirt : hint_range(0.0, 1.0) = """ + str(h1) + """;
uniform float height_rock : hint_range(0.0, 1.0) = """ + str(h2) + """;
uniform float height_snow : hint_range(0.0, 1.0) = """ + str(h3) + """;
uniform float max_terrain_height = 20.0;

// Blending
uniform float texture_scale : hint_range(0.01, 1.0) = """ + str(tex_scale) + """;
uniform float blend_sharpness : hint_range(0.1, 10.0) = """ + str(sharpness) + """;
uniform float slope_threshold : hint_range(0.0, 1.0) = 0.6;
uniform float triplanar_sharpness : hint_range(1.0, 8.0) = 4.0;

// PBR
uniform float roughness_base : hint_range(0.0, 1.0) = 0.75;
uniform float ao_strength : hint_range(0.0, 1.0) = 0.3;

varying vec3 world_pos;
varying vec3 world_normal;
varying float vertex_height;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
    vertex_height = VERTEX.y / max_terrain_height;
}

vec3 triplanar_sample(sampler2D tex, vec3 pos, vec3 blend) {
    vec3 x = texture(tex, pos.zy * texture_scale).rgb;
    vec3 y = texture(tex, pos.xz * texture_scale).rgb;
    vec3 z = texture(tex, pos.xy * texture_scale).rgb;
    return x * blend.x + y * blend.y + z * blend.z;
}

void fragment() {
    vec2 uv_scaled = UV * (1.0 / texture_scale);
    
    // ===== TRIPLANAR SETUP =====
    vec3 tri_blend = abs(world_normal);
    tri_blend = pow(tri_blend, vec3(triplanar_sharpness));
    tri_blend /= (tri_blend.x + tri_blend.y + tri_blend.z);
    
    // ===== SLOPE CALCULATION =====
    float slope = 1.0 - abs(world_normal.y);
    float cliff_blend = smoothstep(slope_threshold - 0.1, slope_threshold + 0.1, slope);
    cliff_blend = pow(cliff_blend, blend_sharpness);
    
    // ===== HEIGHT BLENDING =====
    float h = clamp(vertex_height, 0.0, 1.0);
    
    float w_grass = 1.0 - smoothstep(height_grass, height_dirt, h);
    float w_dirt = smoothstep(height_grass, height_dirt, h) * (1.0 - smoothstep(height_dirt, height_rock, h));
    float w_rock = smoothstep(height_dirt, height_rock, h) * (1.0 - smoothstep(height_rock, height_snow, h));
    float w_snow = smoothstep(height_rock, height_snow, h);
    
    // Sharpen
    w_grass = pow(w_grass, blend_sharpness);
    w_dirt = pow(w_dirt, blend_sharpness);
    w_rock = pow(w_rock, blend_sharpness);
    w_snow = pow(w_snow, blend_sharpness);
    
    // Normalize
    float total = w_grass + w_dirt + w_rock + w_snow + 0.001;
    w_grass /= total; w_dirt /= total; w_rock /= total; w_snow /= total;
    
    // ===== SAMPLE TEXTURES =====
    // Flat areas use standard UV, cliffs use triplanar
    vec3 grass = mix(texture(texture_grass, uv_scaled).rgb, triplanar_sample(texture_grass, world_pos, tri_blend), cliff_blend * 0.5);
    vec3 dirt = mix(texture(texture_dirt, uv_scaled).rgb, triplanar_sample(texture_dirt, world_pos, tri_blend), cliff_blend * 0.5);
    vec3 rock = mix(texture(texture_rock, uv_scaled).rgb, triplanar_sample(texture_rock, world_pos, tri_blend), cliff_blend * 0.5);
    vec3 snow = texture(texture_snow, uv_scaled).rgb;
    vec3 cliff = triplanar_sample(texture_cliff, world_pos, tri_blend);
    
    // Height-based base color
    vec3 height_color = grass * w_grass + dirt * w_dirt + rock * w_rock + snow * w_snow;
    
    // Blend with cliff texture based on slope
    ALBEDO = mix(height_color, cliff, cliff_blend);
    
    // ===== NORMALS =====
    vec3 n_base = texture(normal_rock, uv_scaled).rgb * 2.0 - 1.0;
    vec3 n_cliff = triplanar_sample(normal_cliff, world_pos, tri_blend) * 2.0 - 1.0;
    NORMAL_MAP = normalize(mix(n_base, n_cliff, cliff_blend)) * 0.5 + 0.5;
    
    // ===== PBR OUTPUT =====
    ROUGHNESS = roughness_base + cliff_blend * 0.15;
    METALLIC = 0.0;
    AO = 1.0 - (cliff_blend * ao_strength);
}
"""

#
# ============ NEW: Particle Tools ============
#

func _create_particle_effect(params: Dictionary) -> Dictionary:
	var parent_path = params.get("parent_path", ".")
	var name = params.get("name", "Particles")
	var preset = params.get("preset", "fire")  # fire, smoke, sparks, explosion, magic, rain, snow, dust
	var is_3d = bool(params.get("is_3d", true))
	var one_shot = bool(params.get("one_shot", false))
	var emitting = bool(params.get("emitting", true))
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	var parent = root.get_node_or_null(parent_path) if parent_path != "." else root
	if not parent: return {"error": "Parent not found"}
	
	# Create particle node
	var type_name = "GPUParticles3D" if is_3d else "GPUParticles2D"
	if not ClassDB.class_exists(type_name):
		return {"error": type_name + " not available"}
	
	var particles = ClassDB.instantiate(type_name)
	particles.name = name
	parent.add_child(particles)
	particles.owner = root
	
	# Create process material
	var mat = ParticleProcessMaterial.new()
	
	# Apply preset
	match preset:
		"fire":
			_setup_fire_particles(mat, is_3d)
		"smoke":
			_setup_smoke_particles(mat, is_3d)
		"sparks":
			_setup_sparks_particles(mat, is_3d)
		"explosion":
			_setup_explosion_particles(mat, is_3d)
			one_shot = true
		"magic":
			_setup_magic_particles(mat, is_3d)
		"rain":
			_setup_rain_particles(mat, is_3d)
		"snow":
			_setup_snow_particles(mat, is_3d)
		"dust":
			_setup_dust_particles(mat, is_3d)
		"leaves":
			_setup_leaves_particles(mat, is_3d)
		"blood":
			_setup_blood_particles(mat, is_3d)
			one_shot = true
		_:
			return {"error": "Unknown preset: " + preset + ". Use: fire, smoke, sparks, explosion, magic, rain, snow, dust, leaves, blood"}
	
	particles.process_material = mat
	particles.one_shot = one_shot
	particles.emitting = emitting
	
	# Create a simple mesh for 3D particles (QuadMesh facing camera)
	if is_3d:
		var quad = QuadMesh.new()
		quad.size = Vector2(0.5, 0.5)
		particles.draw_pass_1 = quad
	
	return {"result": "Particle effect created", "path": str(particles.get_path()), "preset": preset}

func _setup_fire_particles(mat: ParticleProcessMaterial, is_3d: bool):
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.3 if is_3d else 10.0
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 15.0
	mat.initial_velocity_min = 2.0 if is_3d else 50.0
	mat.initial_velocity_max = 4.0 if is_3d else 100.0
	mat.gravity = Vector3(0, 2, 0) if is_3d else Vector3(0, -50, 0)
	mat.scale_min = 0.5
	mat.scale_max = 1.5
	mat.color = Color(1.0, 0.5, 0.1, 1.0)
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 0.8, 0.2, 1.0))
	gradient.add_point(0.3, Color(1.0, 0.4, 0.1, 0.8))
	gradient.add_point(0.7, Color(0.8, 0.2, 0.0, 0.4))
	gradient.set_color(1, Color(0.3, 0.1, 0.0, 0.0))
	var color_ramp = GradientTexture1D.new()
	color_ramp.gradient = gradient
	mat.color_ramp = color_ramp

func _setup_smoke_particles(mat: ParticleProcessMaterial, is_3d: bool):
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.5 if is_3d else 15.0
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 0.5 if is_3d else 20.0
	mat.initial_velocity_max = 1.5 if is_3d else 40.0
	mat.gravity = Vector3(0, 0.5, 0) if is_3d else Vector3(0, -20, 0)
	mat.scale_min = 1.0
	mat.scale_max = 3.0
	mat.color = Color(0.3, 0.3, 0.3, 0.5)
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.4, 0.4, 0.4, 0.0))
	gradient.add_point(0.2, Color(0.35, 0.35, 0.35, 0.6))
	gradient.add_point(0.7, Color(0.25, 0.25, 0.25, 0.3))
	gradient.set_color(1, Color(0.2, 0.2, 0.2, 0.0))
	var color_ramp = GradientTexture1D.new()
	color_ramp.gradient = gradient
	mat.color_ramp = color_ramp

func _setup_sparks_particles(mat: ParticleProcessMaterial, is_3d: bool):
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 60.0
	mat.initial_velocity_min = 3.0 if is_3d else 100.0
	mat.initial_velocity_max = 8.0 if is_3d else 200.0
	mat.gravity = Vector3(0, -9.8, 0) if is_3d else Vector3(0, 400, 0)
	mat.scale_min = 0.1
	mat.scale_max = 0.3
	mat.color = Color(1.0, 0.8, 0.3, 1.0)
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 0.8, 1.0))
	gradient.add_point(0.5, Color(1.0, 0.6, 0.2, 1.0))
	gradient.set_color(1, Color(1.0, 0.3, 0.0, 0.0))
	var color_ramp = GradientTexture1D.new()
	color_ramp.gradient = gradient
	mat.color_ramp = color_ramp

func _setup_explosion_particles(mat: ParticleProcessMaterial, is_3d: bool):
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.1 if is_3d else 5.0
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 5.0 if is_3d else 150.0
	mat.initial_velocity_max = 15.0 if is_3d else 400.0
	mat.gravity = Vector3(0, -5, 0) if is_3d else Vector3(0, 300, 0)
	mat.scale_min = 0.5
	mat.scale_max = 2.0
	mat.damping_min = 2.0
	mat.damping_max = 5.0
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 0.8, 1.0))
	gradient.add_point(0.1, Color(1.0, 0.7, 0.2, 1.0))
	gradient.add_point(0.4, Color(1.0, 0.3, 0.0, 0.8))
	gradient.add_point(0.7, Color(0.5, 0.2, 0.1, 0.5))
	gradient.set_color(1, Color(0.2, 0.1, 0.1, 0.0))
	var color_ramp = GradientTexture1D.new()
	color_ramp.gradient = gradient
	mat.color_ramp = color_ramp

func _setup_magic_particles(mat: ParticleProcessMaterial, is_3d: bool):
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 1.0 if is_3d else 30.0
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 0.5 if is_3d else 20.0
	mat.initial_velocity_max = 2.0 if is_3d else 60.0
	mat.gravity = Vector3(0, 0.5, 0) if is_3d else Vector3(0, -30, 0)
	mat.scale_min = 0.2
	mat.scale_max = 0.6
	mat.angular_velocity_min = -180.0
	mat.angular_velocity_max = 180.0
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.5, 0.2, 1.0, 0.0))
	gradient.add_point(0.2, Color(0.7, 0.3, 1.0, 1.0))
	gradient.add_point(0.8, Color(0.3, 0.8, 1.0, 0.8))
	gradient.set_color(1, Color(0.2, 1.0, 0.8, 0.0))
	var color_ramp = GradientTexture1D.new()
	color_ramp.gradient = gradient
	mat.color_ramp = color_ramp

func _setup_rain_particles(mat: ParticleProcessMaterial, is_3d: bool):
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(10, 0.1, 10) if is_3d else Vector3(500, 5, 0)
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 5.0
	mat.initial_velocity_min = 15.0 if is_3d else 400.0
	mat.initial_velocity_max = 20.0 if is_3d else 500.0
	mat.gravity = Vector3(0, -20, 0) if is_3d else Vector3(0, 800, 0)
	mat.scale_min = 0.05
	mat.scale_max = 0.1
	mat.color = Color(0.7, 0.8, 1.0, 0.6)

func _setup_snow_particles(mat: ParticleProcessMaterial, is_3d: bool):
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(10, 0.1, 10) if is_3d else Vector3(500, 5, 0)
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 0.5 if is_3d else 30.0
	mat.initial_velocity_max = 2.0 if is_3d else 60.0
	mat.gravity = Vector3(0, -1, 0) if is_3d else Vector3(0, 50, 0)
	mat.scale_min = 0.1
	mat.scale_max = 0.3
	mat.angular_velocity_min = -30.0
	mat.angular_velocity_max = 30.0
	mat.color = Color(1.0, 1.0, 1.0, 0.9)
	
	# Slight turbulence via velocity randomness
	mat.velocity_limit_curve = null

func _setup_dust_particles(mat: ParticleProcessMaterial, is_3d: bool):
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(2, 0.1, 2) if is_3d else Vector3(100, 5, 0)
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 0.2 if is_3d else 10.0
	mat.initial_velocity_max = 0.8 if is_3d else 30.0
	mat.gravity = Vector3(0, 0.1, 0) if is_3d else Vector3(0, -10, 0)
	mat.scale_min = 0.3
	mat.scale_max = 0.8
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.6, 0.55, 0.45, 0.0))
	gradient.add_point(0.2, Color(0.6, 0.55, 0.45, 0.4))
	gradient.add_point(0.8, Color(0.5, 0.45, 0.4, 0.2))
	gradient.set_color(1, Color(0.4, 0.35, 0.3, 0.0))
	var color_ramp = GradientTexture1D.new()
	color_ramp.gradient = gradient
	mat.color_ramp = color_ramp

func _setup_leaves_particles(mat: ParticleProcessMaterial, is_3d: bool):
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(5, 0.5, 5) if is_3d else Vector3(300, 20, 0)
	mat.direction = Vector3(-1, -1, 0).normalized()
	mat.spread = 30.0
	mat.initial_velocity_min = 1.0 if is_3d else 40.0
	mat.initial_velocity_max = 3.0 if is_3d else 80.0
	mat.gravity = Vector3(0, -2, 0) if is_3d else Vector3(0, 100, 0)
	mat.scale_min = 0.3
	mat.scale_max = 0.7
	mat.angular_velocity_min = -90.0
	mat.angular_velocity_max = 90.0
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.4, 0.6, 0.2, 1.0))
	gradient.add_point(0.3, Color(0.6, 0.5, 0.1, 1.0))
	gradient.add_point(0.6, Color(0.7, 0.4, 0.1, 0.9))
	gradient.set_color(1, Color(0.5, 0.3, 0.1, 0.0))
	var color_ramp = GradientTexture1D.new()
	color_ramp.gradient = gradient
	mat.color_ramp = color_ramp

func _setup_blood_particles(mat: ParticleProcessMaterial, is_3d: bool):
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 60.0
	mat.initial_velocity_min = 3.0 if is_3d else 100.0
	mat.initial_velocity_max = 8.0 if is_3d else 250.0
	mat.gravity = Vector3(0, -15, 0) if is_3d else Vector3(0, 600, 0)
	mat.scale_min = 0.1
	mat.scale_max = 0.4
	mat.damping_min = 1.0
	mat.damping_max = 3.0
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.8, 0.0, 0.0, 1.0))
	gradient.add_point(0.5, Color(0.6, 0.0, 0.0, 0.8))
	gradient.set_color(1, Color(0.3, 0.0, 0.0, 0.0))
	var color_ramp = GradientTexture1D.new()
	color_ramp.gradient = gradient
	mat.color_ramp = color_ramp

#
# ============ NEW: Lighting Presets ============
#

func _lighting_preset(params: Dictionary) -> Dictionary:
	var preset = params.get("preset", "sunny")
	var parent_path = params.get("parent_path", ".")
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	var parent = root.get_node_or_null(parent_path) if parent_path != "." else root
	if not parent: return {"error": "Parent not found"}
	
	# Create DirectionalLight3D
	var light = DirectionalLight3D.new()
	light.name = "Sun"
	parent.add_child(light)
	light.owner = root
	
	# Create WorldEnvironment
	var world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	parent.add_child(world_env)
	world_env.owner = root
	
	var env = Environment.new()
	world_env.environment = env
	
	match preset:
		"sunny":
			light.rotation_degrees = Vector3(-45, -30, 0)
			light.light_color = Color(1.0, 0.95, 0.85)
			light.light_energy = 1.2
			light.shadow_enabled = true
			env.background_mode = Environment.BG_SKY
			var sky = Sky.new()
			var sky_mat = ProceduralSkyMaterial.new()
			sky_mat.sky_top_color = Color(0.35, 0.55, 0.9)
			sky_mat.sky_horizon_color = Color(0.65, 0.75, 0.9)
			sky_mat.ground_bottom_color = Color(0.2, 0.17, 0.13)
			sky_mat.ground_horizon_color = Color(0.65, 0.65, 0.6)
			sky_mat.sun_angle_max = 30.0
			sky.sky_material = sky_mat
			env.sky = sky
			env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
			env.ambient_light_energy = 0.5
			env.tonemap_mode = Environment.TONE_MAPPER_ACES
		"overcast":
			light.rotation_degrees = Vector3(-60, -20, 0)
			light.light_color = Color(0.85, 0.85, 0.9)
			light.light_energy = 0.6
			light.shadow_enabled = true
			env.background_mode = Environment.BG_SKY
			var sky = Sky.new()
			var sky_mat = ProceduralSkyMaterial.new()
			sky_mat.sky_top_color = Color(0.5, 0.55, 0.6)
			sky_mat.sky_horizon_color = Color(0.7, 0.72, 0.75)
			sky_mat.ground_bottom_color = Color(0.3, 0.3, 0.3)
			sky_mat.ground_horizon_color = Color(0.6, 0.6, 0.6)
			sky.sky_material = sky_mat
			env.sky = sky
			env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
			env.ambient_light_energy = 0.7
			env.fog_enabled = true
			env.fog_light_color = Color(0.7, 0.7, 0.75)
			env.fog_density = 0.01
		"sunset":
			light.rotation_degrees = Vector3(-10, -60, 0)
			light.light_color = Color(1.0, 0.6, 0.3)
			light.light_energy = 1.0
			light.shadow_enabled = true
			env.background_mode = Environment.BG_SKY
			var sky = Sky.new()
			var sky_mat = ProceduralSkyMaterial.new()
			sky_mat.sky_top_color = Color(0.2, 0.15, 0.35)
			sky_mat.sky_horizon_color = Color(1.0, 0.5, 0.2)
			sky_mat.ground_bottom_color = Color(0.1, 0.08, 0.06)
			sky_mat.ground_horizon_color = Color(0.8, 0.4, 0.2)
			sky_mat.sun_angle_max = 5.0
			sky.sky_material = sky_mat
			env.sky = sky
			env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
			env.ambient_light_color = Color(1.0, 0.7, 0.5)
			env.ambient_light_energy = 0.3
			env.tonemap_mode = Environment.TONE_MAPPER_ACES
		"night":
			light.rotation_degrees = Vector3(-30, 45, 0)
			light.light_color = Color(0.6, 0.7, 0.9)
			light.light_energy = 0.15
			light.shadow_enabled = true
			env.background_mode = Environment.BG_SKY
			var sky = Sky.new()
			var sky_mat = ProceduralSkyMaterial.new()
			sky_mat.sky_top_color = Color(0.02, 0.02, 0.08)
			sky_mat.sky_horizon_color = Color(0.05, 0.05, 0.12)
			sky_mat.ground_bottom_color = Color(0.01, 0.01, 0.02)
			sky_mat.ground_horizon_color = Color(0.03, 0.03, 0.06)
			sky.sky_material = sky_mat
			env.sky = sky
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.ambient_light_color = Color(0.1, 0.12, 0.2)
			env.ambient_light_energy = 0.3
			env.glow_enabled = true
			env.glow_intensity = 0.5
		"indoor":
			light.rotation_degrees = Vector3(-90, 0, 0)
			light.light_color = Color(1.0, 0.95, 0.9)
			light.light_energy = 0.3
			light.shadow_enabled = false
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color(0.15, 0.15, 0.15)
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.ambient_light_color = Color(1.0, 0.95, 0.9)
			env.ambient_light_energy = 0.6
			env.ssao_enabled = true
		_:
			return {"error": "Unknown preset: " + preset + ". Use: sunny, overcast, sunset, night, indoor"}
	
	return {"result": "Lighting preset applied", "preset": preset, "light_path": str(light.get_path()), "env_path": str(world_env.get_path())}

#
# ============ NEW: Primitive Mesh Tools ============
#

func _create_primitive(params: Dictionary) -> Dictionary:
	var shape = params.get("shape", "box")
	var parent_path = params.get("parent_path", ".")
	var name = params.get("name", "Primitive")
	var size = float(params.get("size", 1.0))
	var color_str = params.get("color", "0.8,0.8,0.8")
	var with_collision = bool(params.get("collision", true))  # Default TRUE for game-ready objects
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	var parent = root.get_node_or_null(parent_path) if parent_path != "." else root
	if not parent: return {"error": "Parent not found"}
	
	# Parse color
	var color_parts = color_str.split(",")
	var color = Color(0.8, 0.8, 0.8)
	if color_parts.size() >= 3:
		color = Color(float(color_parts[0]), float(color_parts[1]), float(color_parts[2]))
	
	# Create mesh
	var mesh: Mesh
	match shape:
		"box":
			var box = BoxMesh.new()
			box.size = Vector3(size, size, size)
			mesh = box
		"sphere":
			var sphere = SphereMesh.new()
			sphere.radius = size / 2.0
			sphere.height = size
			mesh = sphere
		"cylinder":
			var cyl = CylinderMesh.new()
			cyl.top_radius = size / 2.0
			cyl.bottom_radius = size / 2.0
			cyl.height = size
			mesh = cyl
		"capsule":
			var cap = CapsuleMesh.new()
			cap.radius = size / 3.0
			cap.height = size
			mesh = cap
		"plane":
			var plane = PlaneMesh.new()
			plane.size = Vector2(size, size)
			mesh = plane
		"prism":
			var prism = PrismMesh.new()
			prism.size = Vector3(size, size, size)
			mesh = prism
		"torus":
			var torus = TorusMesh.new()
			torus.inner_radius = size / 4.0
			torus.outer_radius = size / 2.0
			mesh = torus
		_:
			return {"error": "Unknown shape: " + shape + ". Use: box, sphere, cylinder, capsule, plane, prism, torus"}
	
	# Create material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	
	# Create node structure
	var result_node: Node3D
	if with_collision:
		var body = StaticBody3D.new()
		body.name = name
		body.set_meta("_edit_group_", true)
		parent.add_child(body)
		body.owner = root
		
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.name = "Mesh"
		mesh_inst.mesh = mesh
		mesh_inst.material_override = mat
		body.add_child(mesh_inst)
		mesh_inst.owner = root
		
		var col_shape = CollisionShape3D.new()
		col_shape.name = "Collision"
		match shape:
			"box":
				var box_shape = BoxShape3D.new()
				box_shape.size = Vector3(size, size, size)
				col_shape.shape = box_shape
			"sphere":
				var sphere_shape = SphereShape3D.new()
				sphere_shape.radius = size / 2.0
				col_shape.shape = sphere_shape
			"cylinder":
				var cyl_shape = CylinderShape3D.new()
				cyl_shape.radius = size / 2.0
				cyl_shape.height = size
				col_shape.shape = cyl_shape
			"capsule":
				var cap_shape = CapsuleShape3D.new()
				cap_shape.radius = size / 3.0
				cap_shape.height = size
				col_shape.shape = cap_shape
			_:
				col_shape.shape = mesh.create_trimesh_shape()
		body.add_child(col_shape)
		col_shape.owner = root
		result_node = body
	else:
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.name = name
		mesh_inst.mesh = mesh
		mesh_inst.material_override = mat
		parent.add_child(mesh_inst)
		mesh_inst.owner = root
		result_node = mesh_inst
	
	return {"result": "Primitive created", "shape": shape, "path": str(result_node.get_path())}

#
# ============ NEW: UI Template Tools ============
#

func _create_ui_template(params: Dictionary) -> Dictionary:
	var template = params.get("template", "main_menu")
	var parent_path = params.get("parent_path", ".")
	var name = params.get("name", "")
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	var parent = root.get_node_or_null(parent_path) if parent_path != "." else root
	if not parent: return {"error": "Parent not found"}
	
	var ui_root: Control
	
	match template:
		"main_menu":
			ui_root = _create_main_menu_ui(name if name != "" else "MainMenu")
		"pause_menu":
			ui_root = _create_pause_menu_ui(name if name != "" else "PauseMenu")
		"hud":
			ui_root = _create_hud_ui(name if name != "" else "HUD")
		"dialogue_box":
			ui_root = _create_dialogue_box_ui(name if name != "" else "DialogueBox")
		"inventory_grid":
			ui_root = _create_inventory_grid_ui(name if name != "" else "Inventory")
		_:
			return {"error": "Unknown template: " + template + ". Use: main_menu, pause_menu, hud, dialogue_box, inventory_grid"}
	
	parent.add_child(ui_root)
	ui_root.owner = root
	_set_owner_recursive(ui_root, root)
	
	return {"result": "UI template created", "template": template, "path": str(ui_root.get_path())}

func _set_owner_recursive(node: Node, owner: Node):
	for child in node.get_children():
		child.owner = owner
		_set_owner_recursive(child, owner)

func _create_main_menu_ui(name: String) -> Control:
	var canvas = CanvasLayer.new()
	canvas.name = name
	
	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(panel)
	
	var center = CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)
	
	var title = Label.new()
	title.name = "Title"
	title.text = "Game Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	vbox.add_child(title)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(spacer)
	
	for btn_name in ["Play", "Options", "Quit"]:
		var btn = Button.new()
		btn.name = btn_name + "Button"
		btn.text = btn_name
		btn.custom_minimum_size = Vector2(200, 50)
		vbox.add_child(btn)
	
	return canvas

func _create_pause_menu_ui(name: String) -> Control:
	var canvas = CanvasLayer.new()
	canvas.name = name
	canvas.layer = 10
	
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0, 0, 0, 0.5)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)
	
	var center = CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)
	
	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(300, 250)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.name = "Title"
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)
	
	for btn_name in ["Resume", "Options", "Main Menu", "Quit"]:
		var btn = Button.new()
		btn.name = btn_name.replace(" ", "") + "Button"
		btn.text = btn_name
		btn.custom_minimum_size = Vector2(200, 40)
		vbox.add_child(btn)
	
	return canvas

func _create_hud_ui(name: String) -> Control:
	var canvas = CanvasLayer.new()
	canvas.name = name
	
	var container = Control.new()
	container.name = "Container"
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(container)
	
	# Health bar (top-left)
	var health_container = HBoxContainer.new()
	health_container.name = "HealthContainer"
	health_container.position = Vector2(20, 20)
	container.add_child(health_container)
	
	var health_icon = Label.new()
	health_icon.name = "HealthIcon"
	health_icon.text = "♥"
	health_icon.add_theme_font_size_override("font_size", 24)
	health_container.add_child(health_icon)
	
	var health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.custom_minimum_size = Vector2(200, 25)
	health_bar.value = 100
	health_container.add_child(health_bar)
	
	# Score (top-right)
	var score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "Score: 0"
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	score_label.position = Vector2(-150, 20)
	container.add_child(score_label)
	
	# Ammo (bottom-right)
	var ammo_label = Label.new()
	ammo_label.name = "AmmoLabel"
	ammo_label.text = "Ammo: 30/90"
	ammo_label.add_theme_font_size_override("font_size", 20)
	ammo_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ammo_label.position = Vector2(-150, -50)
	container.add_child(ammo_label)
	
	# Crosshair (center)
	var crosshair = Label.new()
	crosshair.name = "Crosshair"
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 24)
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-6, -12)
	container.add_child(crosshair)
	
	return canvas

func _create_dialogue_box_ui(name: String) -> Control:
	var canvas = CanvasLayer.new()
	canvas.name = name
	canvas.layer = 5
	
	var container = Control.new()
	container.name = "Container"
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(container)
	
	var panel = PanelContainer.new()
	panel.name = "DialoguePanel"
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.anchor_top = 0.7
	panel.offset_left = 50
	panel.offset_right = -50
	panel.offset_bottom = -30
	container.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	margin.add_child(vbox)
	
	var speaker = Label.new()
	speaker.name = "SpeakerName"
	speaker.text = "Character Name"
	speaker.add_theme_font_size_override("font_size", 20)
	speaker.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	vbox.add_child(speaker)
	
	var text = RichTextLabel.new()
	text.name = "DialogueText"
	text.text = "This is where the dialogue text will appear. Press [Space] to continue..."
	text.fit_content = true
	text.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(text)
	
	var indicator = Label.new()
	indicator.name = "ContinueIndicator"
	indicator.text = "▼"
	indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(indicator)
	
	return canvas

func _create_inventory_grid_ui(name: String) -> Control:
	var canvas = CanvasLayer.new()
	canvas.name = name
	canvas.layer = 8
	
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)
	
	var center = CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)
	
	var panel = PanelContainer.new()
	panel.name = "InventoryPanel"
	panel.custom_minimum_size = Vector2(400, 350)
	center.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	margin.add_child(vbox)
	
	var title = Label.new()
	title.name = "Title"
	title.text = "INVENTORY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	var grid = GridContainer.new()
	grid.name = "ItemGrid"
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grid)
	
	# Create 20 inventory slots
	for i in range(20):
		var slot = PanelContainer.new()
		slot.name = "Slot" + str(i)
		slot.custom_minimum_size = Vector2(60, 60)
		grid.add_child(slot)
		
		var slot_label = Label.new()
		slot_label.name = "Label"
		slot_label.text = ""
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(slot_label)
	
	var close_btn = Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "Close [I]"
	vbox.add_child(close_btn)
	
	return canvas

#
# ============ NEW: Save/Load Game Data ============
#

func _save_game_data(params: Dictionary) -> Dictionary:
	var filename = params.get("filename", "save.json")
	var data = params.get("data", {})
	
	if not filename.ends_with(".json"):
		filename += ".json"
	
	var path = "user://" + filename
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return {"error": "Could not open file for writing: " + path}
	
	var json_str = JSON.stringify(data, "\t")
	file.store_string(json_str)
	file.close()
	
	return {"result": "Game data saved", "path": path, "size": json_str.length()}

func _load_game_data(params: Dictionary) -> Dictionary:
	var filename = params.get("filename", "save.json")
	
	if not filename.ends_with(".json"):
		filename += ".json"
	
	var path = "user://" + filename
	if not FileAccess.file_exists(path):
		return {"error": "Save file not found: " + path}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {"error": "Could not open file for reading: " + path}
	
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_str)
	if error != OK:
		return {"error": "Failed to parse JSON: " + json.get_error_message()}
	
	return {"result": "Game data loaded", "path": path, "data": json.data}

#
# ============ NEW: Animation Tools ============

func _get_animation_player_from_path(path: String) -> AnimationPlayer:
	var root = _get_actual_editor_root()
	if not root:
		return null
	var node = root.get_node_or_null(path) if path != "." else root
	if node is AnimationPlayer:
		return node
	return null

func _list_animations(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	if path == "":
		return {"error": "Path required"}
	var player := _get_animation_player_from_path(path)
	if not player:
		return {"error": "Node is not an AnimationPlayer or not found"}
	var names: Array = []
	for name in player.get_animation_list():
		names.append(str(name))
	return {"animations": names}

func _play_animation(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	var animation = params.get("animation", "")
	var start_time = float(params.get("start_time", 0.0))
	if path == "" or animation == "":
		return {"error": "path and animation required"}
	var player := _get_animation_player_from_path(path)
	if not player:
		return {"error": "Node is not an AnimationPlayer or not found"}
	if not player.has_animation(animation):
		return {"error": "Animation not found: " + animation}
	player.play(animation)
	if start_time > 0.0:
		player.seek(start_time, true)
	return {"result": "Playing " + animation}

func _stop_animation(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	if path == "":
		return {"error": "Path required"}
	var player := _get_animation_player_from_path(path)
	if not player:
		return {"error": "Node is not an AnimationPlayer or not found"}
	player.stop()
	return {"result": "Animation stopped"}

func _seek_animation(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	var time = float(params.get("time", 0.0))
	var update = bool(params.get("update", true))
	var backwards = bool(params.get("backwards", false))
	if path == "":
		return {"error": "Path required"}
	var player := _get_animation_player_from_path(path)
	if not player:
		return {"error": "Node is not an AnimationPlayer or not found"}
	player.seek(time, update, backwards)
	return {"result": "Seeked", "time": time}

func _parse_value_like(current, text: String):
	if text == "":
		return current
	var t := typeof(current)
	if t == TYPE_INT or t == TYPE_FLOAT:
		return float(text)
	elif t == TYPE_VECTOR3:
		var parts = text.split(",")
		if parts.size() == 3:
			return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
	elif t == TYPE_COLOR:
		if text.begins_with("#"):
			return Color.html(text)
		var parts = text.split(",")
		if parts.size() >= 3:
			var a = float(parts[3]) if parts.size() > 3 else 1.0
			return Color(float(parts[0]), float(parts[1]), float(parts[2]), a)
	return text

func _create_simple_animation(params: Dictionary) -> Dictionary:
	var player_path = params.get("player_path", "")
	var animation_name = params.get("animation_name", "")
	var node_path = params.get("node_path", "")
	var property = params.get("property", "")
	var start_value = params.get("start_value", "")
	var end_value = params.get("end_value", "")
	var duration = float(params.get("duration", 1.0))
	if player_path == "" or animation_name == "" or node_path == "" or property == "":
		return {"error": "player_path, animation_name, node_path and property required"}
	var root = _get_actual_editor_root()
	if not root:
		return {"error": "No active scene"}
	var player_node = root.get_node_or_null(player_path)
	if not player_node or not (player_node is AnimationPlayer):
		return {"error": "player_path is not an AnimationPlayer"}
	var target = root.get_node_or_null(node_path)
	if not target:
		return {"error": "Target node not found"}
	# Allow properties that might not be in has_method (e.g. built-in props)
	# if not target.has_method("get") or not target.has_method("set"):
	#	return {"error": "Target node does not support properties"}
	
	var current = target.get(property)
	# If get returns null, maybe it's invalid property?
	if current == null and start_value == "":
		return {"error": "Property not found or is null: " + property}

	var from_val = _parse_value_like(current, start_value) if start_value != "" else current
	var to_val = _parse_value_like(current, end_value)
	var anim := Animation.new()
	anim.length = duration
	var rel_path: NodePath = player_node.get_path_to(target)
	var track = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, NodePath(str(rel_path) + ":" + property))
	anim.track_insert_key(track, 0.0, from_val)
	anim.track_insert_key(track, duration, to_val)
	
	# Godot 4 Library handling
	var lib = player_node.get_animation_library("")
	if not lib:
		lib = AnimationLibrary.new()
		player_node.add_animation_library("", lib)
	
	lib.add_animation(animation_name, anim)
	return {"result": "Animation created", "animation": animation_name}

# ============ NEW: Audio Tools ============

func _create_audio_player(params: Dictionary) -> Dictionary:
	var parent_path = params.get("parent_path", ".")
	var name = params.get("name", "AudioPlayer")
	var is_3d = bool(params.get("is_3d", false))
	var audio_path = params.get("audio_path", "")
	var autoplay = bool(params.get("autoplay", false))
	var play_now = bool(params.get("play_now", false))
	var root = _get_actual_editor_root()
	if not root:
		return {"error": "No active scene"}
	var parent = root.get_node_or_null(parent_path) if parent_path != "." else root
	if not parent:
		return {"error": "Parent not found"}
	var type_name = "AudioStreamPlayer3D" if is_3d else "AudioStreamPlayer"
	if not ClassDB.class_exists(type_name):
		return {"error": "Audio player type not available: " + type_name}
	var player = ClassDB.instantiate(type_name)
	player.name = name
	parent.add_child(player)
	player.owner = root
	if audio_path != "":
		if not FileAccess.file_exists(audio_path):
			return {"error": "Audio file not found: " + audio_path}
		var stream = load(audio_path)
		if stream:
			player.stream = stream
		else:
			return {"error": "Failed to load audio stream"}
	if autoplay and "autoplay" in player:
		player.autoplay = true
	if play_now and player.has_method("play"):
		if player.stream:
			player.play()
		else:
			return {"result": "Audio player created (no stream - assign audio_path to play)", "path": str(player.get_path()), "warning": "No audio stream assigned"}
	
	var result = {"result": "Audio player created", "path": str(player.get_path())}
	if audio_path == "":
		result["note"] = "No audio stream assigned. Set audio_path or assign stream property to play audio."
	return result

func _play_audio(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	if path == "":
		return {"error": "Path required"}
	var root = _get_actual_editor_root()
	if not root:
		return {"error": "No active scene"}
	var node = root.get_node_or_null(path)
	if not node or (not (node is AudioStreamPlayer) and not (node is AudioStreamPlayer3D)):
		return {"error": "Node is not an AudioStreamPlayer"}
	if not node.stream:
		return {"error": "AudioStreamPlayer has no stream assigned. Set the 'stream' property first."}
	node.play()
	return {"result": "Audio playing"}

func _stop_audio(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	if path == "":
		return {"error": "Path required"}
	var root = _get_actual_editor_root()
	if not root:
		return {"error": "No active scene"}
	var node = root.get_node_or_null(path)
	if not node or (not (node is AudioStreamPlayer) and not (node is AudioStreamPlayer3D)):
		return {"error": "Node is not an AudioStreamPlayer"}
	node.stop()
	return {"result": "Audio stopped"}

func _set_bus_volume(params: Dictionary) -> Dictionary:
	var bus_name = params.get("bus", "")
	var volume_db = float(params.get("volume_db", 0.0))
	if bus_name == "":
		return {"error": "Bus name required"}
	var idx = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return {"error": "Bus not found: " + bus_name}
	AudioServer.set_bus_volume_db(idx, volume_db)
	return {"result": "Bus volume set", "bus": bus_name, "volume_db": volume_db}

func _rename_node(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	var new_name = params.get("new_name", "")
	if path == "" or new_name == "": return {"error": "Path and new_name required"}
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	
	var node = root.get_node_or_null(path)
	if not node: return {"error": "Node not found"}
	
	node.name = new_name
	return {"result": "Renamed to " + new_name}

func _duplicate_node(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	var new_name = params.get("new_name", "")
	if path == "": return {"error": "Path required"}
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	
	var node = root.get_node_or_null(path)
	if not node: return {"error": "Node not found"}
	
	var duplicate = node.duplicate()
	if new_name != "":
		duplicate.name = new_name
	
	node.get_parent().add_child(duplicate)
	duplicate.owner = root
	
	# Recursively set owner for all children
	_set_owner_recursive(duplicate, root)
	
	return {"result": "Duplicated", "path": str(duplicate.get_path())}

func _new_scene(params: Dictionary) -> Dictionary:
	var root_type = params.get("root_type", "Node3D")
	var name = params.get("name", "Root")
	
	if not ClassDB.class_exists(root_type):
		return {"error": "Invalid node type: " + root_type}
	
	var new_root = ClassDB.instantiate(root_type)
	new_root.name = name
	
	# Create and open the scene
	var packed = PackedScene.new()
	packed.pack(new_root)
	
	# Save temporarily
	var temp_path = "res://new_scene.tscn"
	ResourceSaver.save(packed, temp_path)
	
	# Open it
	EditorInterface.open_scene_from_path(temp_path)
	
	return {"result": "New scene created", "path": temp_path}

func _open_scene(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	if path == "": return {"error": "Path required"}
	if not FileAccess.file_exists(path): return {"error": "Scene not found: " + path}
	
	EditorInterface.open_scene_from_path(path)
	return {"result": "Opened " + path}

func _list_signals(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	if path == "": return {"error": "Path required"}
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	
	var node = root.get_node_or_null(path) if path != "." else root
	if not node: return {"error": "Node not found"}
	
	var signals = []
	for sig in node.get_signal_list():
		var args = []
		for arg in sig.args:
			args.append(arg.name + ": " + type_string(arg.type))
		signals.append({
			"name": sig.name,
			"args": args
		})
	
	return {"signals": signals}

func _list_methods(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	if path == "": return {"error": "Path required"}
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	
	var node = root.get_node_or_null(path) if path != "." else root
	if not node: return {"error": "Node not found"}
	
	var methods = []
	for method in node.get_method_list():
		# Filter out internal methods
		if not method.name.begins_with("_") or method.name == "_ready" or method.name == "_process":
			methods.append(method.name)
	
	return {"methods": methods}

# ============ NEW: Group Management ============

func _add_to_group(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	var group = params.get("group", "")
	if path == "" or group == "": return {"error": "Path and group required"}
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	
	var node = root.get_node_or_null(path) if path != "." else root
	if not node: return {"error": "Node not found"}
	
	node.add_to_group(group, true) # persistent = true
	return {"result": "Added to group: " + group}

func _remove_from_group(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	var group = params.get("group", "")
	if path == "" or group == "": return {"error": "Path and group required"}
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	
	var node = root.get_node_or_null(path) if path != "." else root
	if not node: return {"error": "Node not found"}
	
	node.remove_from_group(group)
	return {"result": "Removed from group: " + group}

func _get_groups(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	if path == "": return {"error": "Path required"}
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	
	var node = root.get_node_or_null(path) if path != "." else root
	if not node: return {"error": "Node not found"}
	
	var groups = []
	for g in node.get_groups():
		groups.append(str(g))
	return {"groups": groups}

# ============ NEW: Script Attachment ============

func _attach_script(params: Dictionary) -> Dictionary:
	var node_path = params.get("node_path", "")
	var script_path = params.get("script_path", "")
	if node_path == "" or script_path == "": return {"error": "node_path and script_path required"}
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	
	var node = root.get_node_or_null(node_path) if node_path != "." else root
	if not node: return {"error": "Node not found"}
	
	if not FileAccess.file_exists(script_path): return {"error": "Script not found: " + script_path}
	
	var script = load(script_path)
	if not script: return {"error": "Failed to load script"}
	
	node.set_script(script)
	return {"result": "Script attached"}

# ============ NEW: Find Nodes ============

func _find_nodes_by_type(params: Dictionary) -> Dictionary:
	var type_name = params.get("type", "")
	if type_name == "": return {"error": "Type required"}
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	
	var found = []
	_find_by_type_recursive(root, type_name, found)
	return {"nodes": found}

func _find_by_type_recursive(node: Node, type_name: String, results: Array):
	if node.get_class() == type_name or node.is_class(type_name):
		results.append({"name": node.name, "path": str(node.get_path())})
	for child in node.get_children():
		_find_by_type_recursive(child, type_name, results)

func _find_nodes_by_group(params: Dictionary) -> Dictionary:
	var group = params.get("group", "")
	if group == "": return {"error": "Group required"}
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	
	var found = []
	_find_by_group_recursive(root, group, found)
	return {"nodes": found}

func _find_by_group_recursive(node: Node, group: String, results: Array):
	if node.is_in_group(group):
		results.append({"name": node.name, "path": str(node.get_path())})
	for child in node.get_children():
		_find_by_group_recursive(child, group, results)

# ============ NEW: Debug/Errors ============

var _error_log: Array[String] = []

func _get_errors(_params) -> Dictionary:
	# Note: Godot doesn't expose the Output panel directly.
	# We can capture errors by hooking into push_error, but that's complex.
	# For now, return a message explaining the limitation.
	# A workaround: use EditorInterface.get_script_editor() but it's limited.
	return {"info": "Error log not directly accessible. Check Godot Output panel.", "recent_errors": _error_log}

# ============ NEW: Editor Navigation ============

func _focus_node(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	if path == "": return {"error": "Path required"}
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	
	var node = root.get_node_or_null(path) if path != "." else root
	if not node: return {"error": "Node not found"}
	
	# Select the node in the editor
	var selection = EditorInterface.get_selection()
	selection.clear()
	selection.add_node(node)
	
	# If it's a 3D node, try to frame it in the viewport
	if node is Node3D:
		# This will focus the 3D editor on the selected node
		EditorInterface.edit_node(node)
	
	return {"result": "Focused on " + node.name}

# ============ NEW: Screenshots ============

func _get_editor_screenshot(_params) -> Dictionary:
	# Get the main editor viewport and capture it
	var viewport = EditorInterface.get_editor_main_screen()
	if not viewport:
		return {"error": "Could not access editor viewport"}
	
	# Try to get the base control and its viewport
	var base = EditorInterface.get_base_control()
	if not base:
		return {"error": "Could not access base control"}
	
	var vp = base.get_viewport()
	if not vp:
		return {"error": "Could not access viewport"}
	
	var img = vp.get_texture().get_image()
	if not img:
		return {"error": "Could not capture image"}
	
	# Save to temp file
	var path = "res://.editor_screenshot.png"
	img.save_png(path)
	
	# Convert to base64
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {"error": "Could not read screenshot"}
	
	var bytes = file.get_buffer(file.get_length())
	var base64 = Marshalls.raw_to_base64(bytes)
	
	# Cleanup
	DirAccess.remove_absolute(path)
	
	return {"image_base64": base64, "format": "png"}

func _get_game_screenshot(_params) -> Dictionary:
	# This only works when game is running
	if not EditorInterface.is_playing_scene():
		return {"error": "No game is currently running. Use play_game first."}
	
	# We can't directly access the running game's viewport from editor
	# But we can try to capture via the debugger or window
	return {"error": "Game screenshot requires the game window. This is a limitation - use get_editor_screenshot instead or check Godot's Remote tab."}

# ============ NEW: File Search ============

func _search_files(params: Dictionary) -> Dictionary:
	var query = params.get("query", "").to_lower()
	var extension = params.get("extension", "")
	if query == "": return {"error": "Query required"}
	
	var results = []
	_search_files_recursive("res://", query, extension, results)
	return {"files": results}

func _search_files_recursive(path: String, query: String, ext: String, results: Array):
	var dir = DirAccess.open(path)
	if not dir: return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not file_name.begins_with("."):
			var full_path = path + "/" + file_name if path != "res://" else path + file_name
			if dir.current_is_dir():
				_search_files_recursive(full_path, query, ext, results)
			else:
				var matches_query = file_name.to_lower().contains(query)
				var matches_ext = ext == "" or file_name.ends_with(ext)
				if matches_query and matches_ext:
					results.append(full_path)
		file_name = dir.get_next()

# ============ NEW: UID Conversion ============

func _uid_to_path(params: Dictionary) -> Dictionary:
	var uid_string = params.get("uid", "")
	if uid_string == "": return {"error": "UID required"}
	
	# Parse uid:// format
	if uid_string.begins_with("uid://"):
		var uid = ResourceUID.text_to_id(uid_string)
		if uid != ResourceUID.INVALID_ID:
			var path = ResourceUID.get_id_path(uid)
			return {"path": path}
	
	return {"error": "Invalid UID or not found"}

func _path_to_uid(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	if path == "": return {"error": "Path required"}
	
	var uid = ResourceLoader.get_resource_uid(path)
	if uid != ResourceUID.INVALID_ID:
		var uid_string = ResourceUID.id_to_text(uid)
		return {"uid": uid_string}
	
	return {"error": "No UID for this path"}

# ============ NEW: Scene File Content ============

func _get_scene_file_content(_params) -> Dictionary:
	var root = EditorInterface.get_edited_scene_root()
	if not root: return {"error": "No active scene"}
	
	var path = root.scene_file_path
	if path == "": return {"error": "Scene not saved yet"}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: return {"error": "Could not read scene file"}
	
	return {"content": file.get_as_text(), "path": path}

func _delete_scene(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	if path == "": return {"error": "Path required"}
	if not path.ends_with(".tscn"): return {"error": "Path must be a .tscn file"}
	if not FileAccess.file_exists(path): return {"error": "File not found"}
	
	var err = DirAccess.remove_absolute(path)
	if err != OK: return {"error": "Failed to delete: " + str(err)}
	
	# Also remove .import if exists
	if FileAccess.file_exists(path + ".import"):
		DirAccess.remove_absolute(path + ".import")
	
	EditorInterface.get_resource_filesystem().scan()
	return {"result": "Deleted " + path}

func _duplicate_scene(params: Dictionary) -> Dictionary:
	var source_path = params.get("source_path", "")
	var dest_path = params.get("dest_path", "")
	if source_path == "" or dest_path == "":
		return {"error": "source_path and dest_path required"}
	if not source_path.ends_with(".tscn") or not dest_path.ends_with(".tscn"):
		return {"error": "Both paths must be .tscn files"}
	if not FileAccess.file_exists(source_path):
		return {"error": "Source scene not found: " + source_path}
	if FileAccess.file_exists(dest_path):
		return {"error": "Destination already exists: " + dest_path}
	var src_file = FileAccess.open(source_path, FileAccess.READ)
	if not src_file:
		return {"error": "Could not read source scene"}
	var content = src_file.get_as_text()
	src_file.close()
	var dst_file = FileAccess.open(dest_path, FileAccess.WRITE)
	if not dst_file:
		return {"error": "Could not write destination scene"}
	dst_file.store_string(content)
	dst_file.close()
	EditorInterface.get_resource_filesystem().scan()
	return {"result": "Scene duplicated", "path": dest_path}

func _rename_scene(params: Dictionary) -> Dictionary:
	var old_path = params.get("old_path", "")
	var new_path = params.get("new_path", "")
	if old_path == "" or new_path == "":
		return {"error": "old_path and new_path required"}
	if not old_path.ends_with(".tscn") or not new_path.ends_with(".tscn"):
		return {"error": "Both paths must be .tscn files"}
	if not FileAccess.file_exists(old_path):
		return {"error": "Source scene not found: " + old_path}
	if FileAccess.file_exists(new_path):
		return {"error": "Destination already exists: " + new_path}
	var err = DirAccess.rename_absolute(old_path, new_path)
	if err != OK:
		return {"error": "Failed to rename scene: " + str(err)}
	if FileAccess.file_exists(old_path + ".import"):
		DirAccess.rename_absolute(old_path + ".import", new_path + ".import")
	EditorInterface.get_resource_filesystem().scan()
	return {"result": "Scene renamed", "path": new_path}

func _replace_resource_in_scene(params: Dictionary) -> Dictionary:
	var scene_path = params.get("scene_path", "")
	var old_resource = params.get("old_resource", "")
	var new_resource = params.get("new_resource", "")
	if scene_path == "" or old_resource == "" or new_resource == "":
		return {"error": "scene_path, old_resource and new_resource required"}
	if not FileAccess.file_exists(scene_path):
		return {"error": "Scene file not found: " + scene_path}
	var file = FileAccess.open(scene_path, FileAccess.READ)
	if not file:
		return {"error": "Could not read scene file"}
	var content = file.get_as_text()
	file.close()
	var count = content.count(old_resource)
	if count == 0:
		return {"error": "Old resource not found in scene", "old_resource": old_resource}
	content = content.replace(old_resource, new_resource)
	file = FileAccess.open(scene_path, FileAccess.WRITE)
	if not file:
		return {"error": "Could not write scene file"}
	file.store_string(content)
	file.close()
	EditorInterface.get_resource_filesystem().scan()
	return {"result": "Replaced resources", "count": count}

# ============ NEW: Add Resource ============

func _add_resource(params: Dictionary) -> Dictionary:
	var node_path = params.get("node_path", "")
	var property = params.get("property", "")
	var resource_type = params.get("resource_type", "")
	
	if node_path == "" or property == "" or resource_type == "":
		return {"error": "node_path, property, and resource_type required"}
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	
	var node = root.get_node_or_null(node_path) if node_path != "." else root
	if not node: return {"error": "Node not found"}
	
	if not ClassDB.class_exists(resource_type):
		return {"error": "Invalid resource type: " + resource_type}
	
	var resource = ClassDB.instantiate(resource_type)
	if not resource:
		return {"error": "Could not create resource"}
	
	node.set(property, resource)
	return {"result": "Resource added", "type": resource_type}

# ============ NEW: Macro / Helper Tools ============

func _spawn_fps_controller(params: Dictionary) -> Dictionary:
	var parent_path = params.get("parent_path", ".")
	var name = params.get("name", "Player")
	var root = _get_actual_editor_root()
	if not root:
		return {"error": "No active scene"}
	var parent = root.get_node_or_null(parent_path) if parent_path != "." else root
	if not parent:
		return {"error": "Parent not found"}
	if not ClassDB.class_exists("CharacterBody3D"):
		return {"error": "CharacterBody3D not available in this project"}
	var player = ClassDB.instantiate("CharacterBody3D")
	player.name = name
	player.set_meta("_edit_group_", true)
	parent.add_child(player)
	player.owner = root
	
	# Add CollisionShape3D with CapsuleShape3D (1.8m tall player)
	var col_shape = CollisionShape3D.new()
	col_shape.name = "CollisionShape3D"
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	col_shape.shape = capsule
	col_shape.position = Vector3(0, 0.9, 0)  # Center capsule so feet are at origin
	player.add_child(col_shape)
	col_shape.owner = root
	
	# Add Camera3D at eye level
	if ClassDB.class_exists("Camera3D"):
		var cam = ClassDB.instantiate("Camera3D")
		cam.name = "Camera3D"
		cam.position = Vector3(0, 1.6, 0)  # Eye level
		cam.current = true  # Make this the active camera
		player.add_child(cam)
		cam.owner = root
	
	# No script attached - user creates their own movement script
	# This keeps the tool generic for FPS, third-person, or any game type
	
	return {"result": "FPS controller created with collision and camera. Attach a movement script to control it.", "path": str(player.get_path())}

func _create_health_bar_ui(params: Dictionary) -> Dictionary:
	var parent_path = params.get("parent_path", ".")
	var bar_name = params.get("name", "HealthBar")
	var width = float(params.get("width", 200))
	var height = float(params.get("height", 25))
	var root = _get_actual_editor_root()
	if not root:
		return {"error": "No active scene"}
	var parent = root.get_node_or_null(parent_path) if parent_path != "." else root
	if not parent:
		return {"error": "Parent not found"}
	if not ClassDB.class_exists("CanvasLayer") or not ClassDB.class_exists("ProgressBar"):
		return {"error": "UI classes not available"}
	
	# Wrap in CanvasLayer so it renders on top of 3D scene
	var canvas = CanvasLayer.new()
	canvas.name = bar_name
	canvas.layer = 10  # High layer to be on top
	canvas.set_meta("_edit_group_", true)
	parent.add_child(canvas)
	canvas.owner = root
	
	# Simple progress bar - user can style/customize as needed
	var bar = ProgressBar.new()
	bar.name = "Bar"
	bar.position = Vector2(20, 20)
	bar.custom_minimum_size = Vector2(width, height)
	bar.size = Vector2(width, height)
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	canvas.add_child(bar)
	bar.owner = root
	
	# Generic - no icons or specific styling, user customizes for their game
	return {"result": "Health bar UI created with CanvasLayer. Customize styling as needed.", "path": str(canvas.get_path())}

func _spawn_spinning_pickup(params: Dictionary) -> Dictionary:
	var parent_path = params.get("parent_path", ".")
	var scene_path = params.get("scene_path", "")
	var pickup_name = params.get("name", "Pickup")
	var root = _get_actual_editor_root()
	if not root:
		return {"error": "No active scene"}
	var parent = root.get_node_or_null(parent_path) if parent_path != "." else root
	if not parent:
		return {"error": "Parent not found"}
	
	# If scene_path provided and exists, use it
	if scene_path != "" and FileAccess.file_exists(scene_path):
		var packed = load(scene_path)
		if packed:
			var node = packed.instantiate()
			parent.add_child(node)
			node.owner = root
			return {"result": "Pickup spawned from scene", "path": str(node.get_path())}
	
	# Otherwise, create a complete pickup from scratch
	var area = Area3D.new()
	area.name = pickup_name
	area.set_meta("_edit_group_", true)
	parent.add_child(area)
	area.owner = root
	
	# Add collision shape (required for Area3D to detect anything!)
	var col = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.5
	col.shape = sphere_shape
	area.add_child(col)
	col.owner = root
	
	# Add visual mesh
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "Mesh"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.3
	cylinder.bottom_radius = 0.3
	cylinder.height = 0.1
	mesh_inst.mesh = cylinder
	mesh_inst.rotation_degrees = Vector3(90, 0, 0)  # Lay flat like a coin
	area.add_child(mesh_inst)
	mesh_inst.owner = root
	
	# Add gold material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.84, 0.0)  # Gold
	mat.metallic = 0.8
	mat.roughness = 0.3
	mesh_inst.material_override = mat
	
	# Add spinning animation via AnimationPlayer
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	area.add_child(anim_player)
	anim_player.owner = root
	
	# Create spin animation
	var anim = Animation.new()
	anim.length = 2.0
	anim.loop_mode = Animation.LOOP_LINEAR
	var track = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, NodePath(".:rotation_degrees"))
	anim.track_insert_key(track, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(track, 2.0, Vector3(0, 360, 0))
	
	var lib = AnimationLibrary.new()
	lib.add_animation("spin", anim)
	anim_player.add_animation_library("", lib)
	anim_player.play("spin")
	
	# No script attached - user adds their own collection logic
	# Connect body_entered signal to handle pickups in their own way
	
	return {"result": "Pickup created with collision, mesh, and spin animation. Connect body_entered signal to add collection logic.", "path": str(area.get_path())}

func _create_trigger_area(params: Dictionary) -> Dictionary:
	"""Create an Area3D with CollisionShape3D ready to detect bodies."""
	var parent_path = params.get("parent_path", ".")
	var area_name = params.get("name", "TriggerArea")
	var shape_type = params.get("shape", "box")  # box, sphere, capsule, cylinder
	var size = float(params.get("size", 2.0))
	var monitoring = bool(params.get("monitoring", true))
	var show_debug = bool(params.get("debug_mesh", false))  # Off by default for production
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	var parent = root.get_node_or_null(parent_path) if parent_path != "." else root
	if not parent: return {"error": "Parent not found"}
	
	# Create Area3D
	var area = Area3D.new()
	area.name = area_name
	area.monitoring = monitoring
	area.monitorable = true
	area.set_meta("_edit_group_", true)
	parent.add_child(area)
	area.owner = root
	
	# Create CollisionShape3D with shape
	var col = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	
	var shape: Shape3D
	match shape_type:
		"box":
			var box = BoxShape3D.new()
			box.size = Vector3(size, size, size)
			shape = box
		"sphere":
			var sphere = SphereShape3D.new()
			sphere.radius = size / 2.0
			shape = sphere
		"capsule":
			var capsule = CapsuleShape3D.new()
			capsule.radius = size / 3.0
			capsule.height = size
			shape = capsule
		"cylinder":
			var cyl = CylinderShape3D.new()
			cyl.radius = size / 2.0
			cyl.height = size
			shape = cyl
		_:
			var box = BoxShape3D.new()
			box.size = Vector3(size, size, size)
			shape = box
	
	col.shape = shape
	area.add_child(col)
	col.owner = root
	
	# Optional debug visualization (disabled by default)
	if show_debug:
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.name = "DebugMesh"
		var debug_mesh = BoxMesh.new()
		debug_mesh.size = Vector3(size, size, size)
		mesh_inst.mesh = debug_mesh
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.8, 0.2, 0.3)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh_inst.material_override = mat
		area.add_child(mesh_inst)
		mesh_inst.owner = root
	
	return {"result": "Trigger area created. Connect body_entered/body_exited signals.", "path": str(area.get_path())}

func _create_rigidbody(params: Dictionary) -> Dictionary:
	"""Create a RigidBody3D with CollisionShape3D and mesh."""
	var parent_path = params.get("parent_path", ".")
	var name = params.get("name", "RigidBody")
	var shape_type = params.get("shape", "box")  # box, sphere, capsule, cylinder
	var size = float(params.get("size", 1.0))
	var mass = float(params.get("mass", 1.0))
	var color_str = params.get("color", "0.6,0.6,0.6")
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	var parent = root.get_node_or_null(parent_path) if parent_path != "." else root
	if not parent: return {"error": "Parent not found"}
	
	# Parse color
	var color = Color(0.6, 0.6, 0.6)
	var color_parts = color_str.split(",")
	if color_parts.size() >= 3:
		color = Color(float(color_parts[0]), float(color_parts[1]), float(color_parts[2]))
	
	# Create RigidBody3D
	var body = RigidBody3D.new()
	body.name = name
	body.mass = mass
	body.set_meta("_edit_group_", true)
	parent.add_child(body)
	body.owner = root
	
	# Create CollisionShape3D
	var col = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	
	var col_shape: Shape3D
	var mesh: Mesh
	
	match shape_type:
		"box":
			var box_shape = BoxShape3D.new()
			box_shape.size = Vector3(size, size, size)
			col_shape = box_shape
			var box_mesh = BoxMesh.new()
			box_mesh.size = Vector3(size, size, size)
			mesh = box_mesh
		"sphere":
			var sphere_shape = SphereShape3D.new()
			sphere_shape.radius = size / 2.0
			col_shape = sphere_shape
			var sphere_mesh = SphereMesh.new()
			sphere_mesh.radius = size / 2.0
			sphere_mesh.height = size
			mesh = sphere_mesh
		"capsule":
			var cap_shape = CapsuleShape3D.new()
			cap_shape.radius = size / 3.0
			cap_shape.height = size
			col_shape = cap_shape
			var cap_mesh = CapsuleMesh.new()
			cap_mesh.radius = size / 3.0
			cap_mesh.height = size
			mesh = cap_mesh
		"cylinder":
			var cyl_shape = CylinderShape3D.new()
			cyl_shape.radius = size / 2.0
			cyl_shape.height = size
			col_shape = cyl_shape
			var cyl_mesh = CylinderMesh.new()
			cyl_mesh.top_radius = size / 2.0
			cyl_mesh.bottom_radius = size / 2.0
			cyl_mesh.height = size
			mesh = cyl_mesh
		_:
			var box_shape = BoxShape3D.new()
			box_shape.size = Vector3(size, size, size)
			col_shape = box_shape
			var box_mesh = BoxMesh.new()
			box_mesh.size = Vector3(size, size, size)
			mesh = box_mesh
	
	col.shape = col_shape
	body.add_child(col)
	col.owner = root
	
	# Create MeshInstance3D
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "Mesh"
	mesh_inst.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)
	mesh_inst.owner = root
	
	return {"result": "RigidBody3D created with collision and mesh", "path": str(body.get_path())}

# ============ NEW: UI Anchors ============

func _set_anchor_preset(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	var preset = params.get("preset", "")
	
	if path == "" or preset == "": return {"error": "path and preset required"}
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	
	var node = root.get_node_or_null(path)
	if not node: return {"error": "Node not found"}
	if not node is Control: return {"error": "Node is not a Control"}
	
	var presets = {
		"top_left": Control.PRESET_TOP_LEFT,
		"top_right": Control.PRESET_TOP_RIGHT,
		"bottom_left": Control.PRESET_BOTTOM_LEFT,
		"bottom_right": Control.PRESET_BOTTOM_RIGHT,
		"center_left": Control.PRESET_CENTER_LEFT,
		"center_right": Control.PRESET_CENTER_RIGHT,
		"center_top": Control.PRESET_CENTER_TOP,
		"center_bottom": Control.PRESET_CENTER_BOTTOM,
		"center": Control.PRESET_CENTER,
		"left_wide": Control.PRESET_LEFT_WIDE,
		"right_wide": Control.PRESET_RIGHT_WIDE,
		"top_wide": Control.PRESET_TOP_WIDE,
		"bottom_wide": Control.PRESET_BOTTOM_WIDE,
		"vcenter_wide": Control.PRESET_VCENTER_WIDE,
		"hcenter_wide": Control.PRESET_HCENTER_WIDE,
		"full_rect": Control.PRESET_FULL_RECT
	}
	
	if not preset in presets:
		return {"error": "Invalid preset. Use: " + ", ".join(presets.keys())}
	
	node.set_anchors_preset(presets[preset])
	return {"result": "Anchor preset set to " + preset}

func _set_anchor_values(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	var left = params.get("left", 0.0)
	var top = params.get("top", 0.0)
	var right = params.get("right", 1.0)
	var bottom = params.get("bottom", 1.0)
	
	if path == "": return {"error": "path required"}
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	
	var node = root.get_node_or_null(path)
	if not node: return {"error": "Node not found"}
	if not node is Control: return {"error": "Node is not a Control"}
	
	node.anchor_left = float(left)
	node.anchor_top = float(top)
	node.anchor_right = float(right)
	node.anchor_bottom = float(bottom)
	
	return {"result": "Anchors set"}

# ============ NEW: Open Scripts ============

func _get_open_scripts(_params) -> Dictionary:
	var script_editor = EditorInterface.get_script_editor()
	if not script_editor: return {"error": "Could not access script editor"}
	
	var open_scripts = script_editor.get_open_scripts()
	var results = []
	
	for script in open_scripts:
		if script:
			results.append({
				"path": script.resource_path,
				"class": script.get_class()
			})
	
	return {"scripts": results}

# ============ NEW: Edit File (Find/Replace) ============

func _edit_file(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	var find = params.get("find", "")
	var replace = params.get("replace", "")
	
	if path == "" or find == "": return {"error": "path and find required"}
	if not FileAccess.file_exists(path): return {"error": "File not found"}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: return {"error": "Could not read file"}
	
	var content = file.get_as_text()
	file.close()
	
	var count = content.count(find)
	if count == 0:
		return {"error": "String not found in file", "find": find}
	
	var new_content = content.replace(find, replace)
	
	file = FileAccess.open(path, FileAccess.WRITE)
	if not file: return {"error": "Could not write file"}
	
	file.store_string(new_content)
	file.close()
	
	EditorInterface.get_resource_filesystem().scan()
	return {"result": "Replaced " + str(count) + " occurrence(s)"}

# ============ NEW: Clear Output ============

func _clear_output(_params) -> Dictionary:
	# There's no direct API to clear the output panel
	# But we can try to access it via the editor interface
	# This is a best-effort approach
	print("\n\n\n--- OUTPUT CLEARED BY MCP ---\n\n\n")
	return {"result": "Output cleared (added separator)"}

# ============ NEW: Project Info ============

func _get_project_info(_params) -> Dictionary:
	var info = {}
	
	# Basic project settings
	info["name"] = ProjectSettings.get_setting("application/config/name", "Unknown")
	info["version"] = ProjectSettings.get_setting("application/config/version", "")
	info["main_scene"] = ProjectSettings.get_setting("application/run/main_scene", "")
	info["icon"] = ProjectSettings.get_setting("application/config/icon", "")
	
	# Rendering
	info["renderer"] = ProjectSettings.get_setting("rendering/renderer/rendering_method", "")
	
	# Window
	info["window_width"] = ProjectSettings.get_setting("display/window/size/viewport_width", 1152)
	info["window_height"] = ProjectSettings.get_setting("display/window/size/viewport_height", 648)
	
	# Physics
	info["physics_fps"] = ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 60)
	info["gravity"] = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	
	# Godot version
	info["godot_version"] = Engine.get_version_info()
	
	# Current scene
	var root = EditorInterface.get_edited_scene_root()
	if root:
		info["current_scene"] = root.scene_file_path
		info["current_scene_name"] = root.name
	
	return info

func _get_selection(_params) -> Dictionary:
	var selection = EditorInterface.get_selection().get_selected_nodes()
	var paths = []
	for node in selection:
		paths.append(str(node.get_path()))
	return {"selection": paths}

func _set_project_setting(params: Dictionary) -> Dictionary:
	var name = params.get("name", "")
	var value = params.get("value")
	if name == "": return {"error": "Setting name required"}
	
	# Handle types if needed, but ProjectSettings tries to auto-convert
	ProjectSettings.set_setting(name, value)
	ProjectSettings.save()
	return {"result": "Setting updated"}

func _create_folder(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	if not path.begins_with("res://"): return {"error": "Path must be in res://"}
	
	var err = DirAccess.make_dir_recursive_absolute(path)
	if err != OK: return {"error": "Failed to create folder: " + str(err)}
	
	EditorInterface.get_resource_filesystem().scan()
	return {"result": "Folder created"}

func _create_shader(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	var code = params.get("code", "")
	if not path.ends_with(".gdshader"): return {"error": "Path must end with .gdshader"}
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file: return {"error": "Could not write shader"}
	file.store_string(code)
	file.close()
	
	EditorInterface.get_resource_filesystem().scan()
	return {"result": "Shader created"}

func _apply_shader(params: Dictionary) -> Dictionary:
	var node_path = params.get("node_path", "")
	var shader_path = params.get("shader_path", "")
	
	var root = _get_actual_editor_root()
	var node = root.get_node_or_null(node_path)
	if not node: return {"error": "Node not found"}
	
	if not FileAccess.file_exists(shader_path): return {"error": "Shader file not found"}
	
	# Load shader
	var shader = load(shader_path)
	if not shader: return {"error": "Failed to load shader"}
	
	# Create ShaderMaterial
	var mat = ShaderMaterial.new()
	mat.shader = shader
	
	# Apply to node (assuming MeshInstance3D or similar)
	if node.has_method("set_surface_override_material"):
		node.set_surface_override_material(0, mat)
	elif "material" in node:
		node.material = mat
	elif "material_override" in node:
		node.material_override = mat
	else:
		return {"error": "Node does not support materials"}
		
	return {"result": "Shader applied"}

func _setup_input_map(params: Dictionary) -> Dictionary:
	var action_name = params.get("action", "")
	var event_type = params.get("event_type", "") # "key" or "joy"
	var key_string = params.get("key", "") # e.g. "Space", "W"
	var joy_button = params.get("joy_button", -1)
	
	if action_name == "": return {"error": "Action name required"}
	
	# 1. Add Action
	if not ProjectSettings.has_setting("input/" + action_name):
		var setting = {"events": [], "deadzone": 0.5}
		ProjectSettings.set_setting("input/" + action_name, setting)
	
	# 2. Get existing events
	var setting = ProjectSettings.get_setting("input/" + action_name)
	var events = setting.get("events", [])
	
	# 3. Create new event
	var event
	if event_type == "key":
		event = InputEventKey.new()
		var keycode = OS.find_keycode_from_string(key_string)
		if keycode == 0: return {"error": "Invalid key string: " + key_string}
		event.keycode = keycode
	elif event_type == "joy":
		event = InputEventJoypadButton.new()
		event.button_index = int(joy_button)
	else:
		return {"error": "Unknown event type: " + event_type}
		
	# 4. Add to list
	events.append(event)
	setting["events"] = events
	
	# 5. Save back to ProjectSettings
	ProjectSettings.set_setting("input/" + action_name, setting)
	ProjectSettings.save()
	
	# 6. Also update runtime InputMap for immediate effect
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	InputMap.action_add_event(action_name, event)
	
	return {"result": "Added " + event_type + " event to " + action_name}

func _read_script(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	if not FileAccess.file_exists(path): return {"error": "File not found"}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: return {"error": "Could not read file"}
	
	return {"content": file.get_as_text(), "path": path}

func _connect_signal(params: Dictionary) -> Dictionary:
	var source_path = params.get("source", "")
	var target_path = params.get("target", "")
	var signal_name = params.get("signal", "")
	var method_name = params.get("method", "")
	
	var root = _get_actual_editor_root()
	var source = root.get_node_or_null(source_path)
	var target = root.get_node_or_null(target_path)
	
	if not source or not target: return {"error": "Source or Target node not found"}
	
	if not source.has_signal(signal_name): return {"error": "Source does not have signal: " + signal_name}
	
	# In editor, we persistent connections slightly differently if we want them saved
	# But practically, we can just use the node method if we want runtime connection.
	# For persistent editor connection:
	if source.is_connected(signal_name, Callable(target, method_name)):
		return {"result": "Already connected"}
	source.connect(signal_name, Callable(target, method_name))
	return {"result": "Connected " + signal_name + " to " + method_name}

func _disconnect_signal(params: Dictionary) -> Dictionary:
	var source_path = params.get("source", "")
	var target_path = params.get("target", "")
	var signal_name = params.get("signal", "")
	var method_name = params.get("method", "")
	
	var root = _get_actual_editor_root()
	if not root:
		return {"error": "No active scene"}
	var source = root.get_node_or_null(source_path)
	var target = root.get_node_or_null(target_path)
	if not source or not target:
		return {"error": "Source or Target node not found"}
	if not source.has_signal(signal_name):
		return {"error": "Source does not have signal: " + signal_name}
	var callable = Callable(target, method_name)
	if not source.is_connected(signal_name, callable):
		return {"result": "Not connected"}
	source.disconnect(signal_name, callable)
	return {"result": "Disconnected " + signal_name + " from " + method_name}

func _collect_signal_connections(root: Node, source: Object, signal_name: StringName, results: Array):
	var list = source.get_signal_connection_list(signal_name)
	for c in list:
		var target = c.get("target")
		var method = c.get("method")
		var flags = c.get("flags", 0)
		var target_path = ""
		if target is Node:
			target_path = str(root.get_path_to(target))
		results.append({
			"signal": str(signal_name),
			"target_path": target_path,
			"method": str(method),
			"flags": flags
		})

func _list_signal_connections(params: Dictionary) -> Dictionary:
	var source_path = params.get("source", "")
	var signal_name = params.get("signal", "")
	if source_path == "":
		return {"error": "source required"}
	var root = _get_actual_editor_root()
	if not root:
		return {"error": "No active scene"}
	var source = root.get_node_or_null(source_path)
	if not source:
		return {"error": "Source node not found"}
	var results: Array = []
	if signal_name != "":
		if not source.has_signal(signal_name):
			return {"error": "Source does not have signal: " + signal_name}
		_collect_signal_connections(root, source, signal_name, results)
	else:
		for sig in source.get_signal_list():
			_collect_signal_connections(root, source, sig.name, results)
	return {"connections": results}

func _play_game(params: Dictionary) -> Dictionary:
	EditorInterface.play_main_scene()
	return {"result": "Game started"}

func _stop_game(params: Dictionary) -> Dictionary:
	EditorInterface.stop_playing_scene()
	return {"result": "Game stopped"}

func _save_scene(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	var root = EditorInterface.get_edited_scene_root()
	if not root: return {"error": "No active scene to save"}
	
	var packed_scene = PackedScene.new()
	var err = packed_scene.pack(root)
	if err != OK: return {"error": "Failed to pack scene: " + str(err)}
	
	# If path is empty, try to use existing filename
	if path == "":
		path = root.scene_file_path
	
	if path == "": return {"error": "No path provided and scene has no filename"}
	
	err = ResourceSaver.save(packed_scene, path)
	if err != OK: return {"error": "Failed to save scene to " + path + ": " + str(err)}
	
	# Reload to keep editor in sync
	root.scene_file_path = path
	return {"result": "Scene saved to " + path}

func _get_state() -> Dictionary:
	var scenes = EditorInterface.get_open_scenes()
	var edited = EditorInterface.get_edited_scene_root()
	return {
		"open_scenes": scenes,
		"edited_scene_root": str(edited) if edited else "null",
		"edited_scene_name": edited.name if edited else ""
	}

func _get_node_details(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	if path == "": return {"error": "Path required"}
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	
	var node = root.get_node_or_null(path) if path != "." else root
	if not node: return {"error": "Node not found"}
	
	var props = {}
	for p in node.get_property_list():
		# Filter out some internal clutter if desired, but raw is fine for now
		if p.usage & PROPERTY_USAGE_STORAGE:
			var val = node.get(p.name)
			props[p.name] = str(val) # Stringify for JSON safety
			
	return {"name": node.name, "class": node.get_class(), "properties": props}

func _set_property(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	var prop = params.get("property", "")
	var val = params.get("value")
	
	if path == "" or prop == "": return {"error": "Missing path or property"}
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	
	var node = root.get_node_or_null(path) if path != "." else root
	if not node: return {"error": "Node not found"}
	
	# Try to guess type from current value
	var current = node.get(prop)
	if current == null:
		node.set(prop, val)
	elif typeof(current) == TYPE_INT:
		node.set(prop, int(val))
	elif typeof(current) == TYPE_FLOAT:
		node.set(prop, float(val))
	elif typeof(current) == TYPE_BOOL:
		node.set(prop, str(val).to_lower() == "true")
	elif typeof(current) == TYPE_VECTOR2:
		if val is String:
			var parts = val.split(",")
			if parts.size() == 2:
				node.set(prop, Vector2(float(parts[0]), float(parts[1])))
	elif typeof(current) == TYPE_VECTOR2I:
		if val is String:
			var parts = val.split(",")
			if parts.size() == 2:
				node.set(prop, Vector2i(int(parts[0]), int(parts[1])))
	elif typeof(current) == TYPE_VECTOR3:
		if val is String:
			var parts = val.split(",")
			if parts.size() == 3:
				node.set(prop, Vector3(float(parts[0]), float(parts[1]), float(parts[2])))
	elif typeof(current) == TYPE_VECTOR3I:
		if val is String:
			var parts = val.split(",")
			if parts.size() == 3:
				node.set(prop, Vector3i(int(parts[0]), int(parts[1]), int(parts[2])))
	elif typeof(current) == TYPE_COLOR:
		if val is String:
			# Support "r,g,b,a" or "#RRGGBB" or named colors
			if val.begins_with("#"):
				node.set(prop, Color.html(val))
			elif "," in val:
				var parts = val.split(",")
				if parts.size() >= 3:
					var a = float(parts[3]) if parts.size() > 3 else 1.0
					node.set(prop, Color(float(parts[0]), float(parts[1]), float(parts[2]), a))
			else:
				# Try named color
				node.set(prop, Color(val))
	else:
		# Fallback
		node.set(prop, val)
		
	return {"result": "Property set", "new_value": str(node.get(prop))}

func _list_dir(params: Dictionary) -> Dictionary:
	var path = params.get("path", "res://")
	var dir = DirAccess.open(path)
	if not dir: return {"error": "Failed to open directory: " + path}
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var files = []
	while file_name != "":
		if not file_name.begins_with("."):
			files.append(file_name)
		file_name = dir.get_next()
	
	return {"files": files, "path": path}

func _save_script(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	var content = params.get("content", "")
	if not path.begins_with("res://"): return {"error": "Path must start with res://"}
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file: return {"error": "Could not write to " + path}
	
	file.store_string(content)
	file.close()
	
	# Refresh filesystem
	EditorInterface.get_resource_filesystem().scan()
	return {"result": "Saved " + path}

func _delete_node(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	if path == "": return {"error": "Path required"}
	
	var root = _get_actual_editor_root()
	if not root: return {"error": "No active scene"}
	
	var node = root.get_node_or_null(path)
	if not node: return {"error": "Node not found"}
	if node == root: return {"error": "Cannot delete root node"}
	
	node.queue_free()
	return {"result": "Node deleted"}

func _reparent_node(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	var new_parent_path = params.get("new_parent", "")
	
	var root = _get_actual_editor_root()
	var node = root.get_node_or_null(path)
	var new_parent = root.get_node_or_null(new_parent_path) if new_parent_path != "." else root
	
	if not node or not new_parent: return {"error": "Node or parent not found"}
	
	node.get_parent().remove_child(node)
	new_parent.add_child(node)
	node.owner = root
	
	return {"result": "Reparented"}

func _instantiate_scene(params: Dictionary) -> Dictionary:
	var path = params.get("path", "")
	var parent_path = params.get("parent_path", ".")
	
	if not FileAccess.file_exists(path): return {"error": "File not found: " + path}
	
	var packed_scene = load(path)
	if not packed_scene: return {"error": "Failed to load scene"}
	
	var new_node = packed_scene.instantiate()
	
	var root = _get_actual_editor_root()
	var parent = root.get_node_or_null(parent_path) if parent_path != "." else root
	if not parent: return {"error": "Parent not found"}
	
	parent.add_child(new_node)
	new_node.owner = root
	
	return {"result": "Instantiated " + new_node.name}

func _get_scene_tree() -> Dictionary:
	var root = _get_actual_editor_root()
	if not root:
		return {"error": "No active scene"}
	
	return {"tree": _serialize_node(root)}

func _get_actual_editor_root() -> Node:
	var root = EditorInterface.get_edited_scene_root()
	if root:
		return root
		
	# Fallback: Try to find the first node in the edited scene list
	var scenes = EditorInterface.get_open_scenes()
	if scenes.size() > 0:
		return scenes[0] # This is usually a path string, not a node
		
	# If we are here, maybe we can cheat and look at the SceneTree dock?
	# But API access is limited. 
	return null

func _serialize_node(node: Node) -> Dictionary:
	var data = {
		"name": node.name,
		"type": node.get_class(),
		"path": str(node.get_path()),
		"children": []
	}
	for child in node.get_children():
		data["children"].append(_serialize_node(child))
	return data

func _add_node(params: Dictionary) -> Dictionary:
	var type = params.get("type", "Node")
	var parent_path = params.get("parent_path", "")
	var name = params.get("name", "")
	
	var root = _get_actual_editor_root()
	if not root:
		return {"error": "No active scene"}

	var parent: Node = root
	if parent_path != "" and parent_path != ".":
		parent = root.get_node_or_null(parent_path)
		if not parent:
			return {"error": "Parent path not found: " + parent_path}
	
	# Instantiate the node
	# First check if it's a built-in type
	if not ClassDB.class_exists(type):
		return {"error": "Invalid node type: " + type}
		
	var new_node = ClassDB.instantiate(type)
	if name != "":
		new_node.name = name
	
	parent.add_child(new_node)
	new_node.owner = root # Necessary for it to show up in the scene file
	
	return {"result": "Node created", "path": str(new_node.get_path())}

func _execute_script(params: Dictionary) -> Dictionary:
	var code = params.get("code", "")
	if code == "":
		return {"error": "No code provided"}

	# To execute code dynamically in Godot 4, we can use Expression or create a temporary script.
	# Creating a script is more powerful as it allows multiple lines and context.
	
	var script = GDScript.new()
	script.source_code = "@tool\nextends RefCounted\nfunc eval(editor_interface):\n"
	
	# Indent user code
	var lines = code.replace("\r\n", "\n").split("\n")
	for line in lines:
		script.source_code += "\t" + line + "\n"
		
	var err = script.reload()
	if err != OK:
		return {"error": "Script parse error", "source": script.source_code}
		
	var obj = script.new()
	var result = obj.eval(EditorInterface)
	
	return {"result": str(result)}

