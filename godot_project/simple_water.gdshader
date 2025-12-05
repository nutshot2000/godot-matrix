shader_type spatial;
render_mode specular_schlick_ggx, depth_draw_always, cull_back;

uniform vec3 color_shallow : source_color = vec3(0.0, 0.4, 0.6);
uniform vec3 color_deep : source_color = vec3(0.0, 0.1, 0.3);
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.02;

uniform sampler2D wave_noise;
uniform float noise_scale = 20.0;
uniform float height_scale = 2.0;
uniform float time_scale = 0.05;

uniform sampler2D normal_noise;
uniform float normal_scale = 1.0;

varying float height;
varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float noise = texture(wave_noise, world_pos.xz / noise_scale + TIME * time_scale).r;
	height = noise;
	VERTEX.y += height * height_scale;
}

void fragment() {
	// 1. Base Color based on Height (simple but effective)
	// Peaks are lighter (shallow), troughs are darker (deep)
	vec3 albedo = mix(color_deep, color_shallow, height);
	
	// 2. Normal Map (Two scrolling layers for detail)
	vec2 uv = world_pos.xz / noise_scale;
	vec3 n1 = texture(normal_noise, uv + TIME * time_scale).rgb;
	vec3 n2 = texture(normal_noise, uv * 0.5 - TIME * time_scale * 0.5).rgb;
	vec3 final_normal = normalize(vec3(n1.r + n2.r - 1.0, n1.b, n1.g + n2.g - 1.0)); // Swizzle for Godot
	
	ALBEDO = albedo;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = final_normal;
	NORMAL_MAP_DEPTH = normal_scale;
	
	// 3. Fresnel (Rim Lighting) - Kept subtle
	float fresnel = sqrt(1.0 - dot(NORMAL, VIEW));
	ALBEDO += vec3(0.1) * fresnel; // Add a little white rim
	
	// 4. Transparency
	ALPHA = 0.9;
}
