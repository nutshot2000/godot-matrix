shader_type spatial;
render_mode specular_schlick_ggx;

// Caribbean Water Colors
uniform vec3 albedo : source_color = vec3(0.0, 0.6, 0.7); // Teal shallow
uniform vec3 albedo2 : source_color = vec3(0.0, 0.2, 0.5); // Deep blue
uniform float metallic : hint_range(0.0, 1.0) = 0.1;
uniform float roughness : hint_range(0.0, 1.0) = 0.02;
uniform float wave_direction = 1.0;
uniform float wave_direction2 = 1.0;
uniform float time_scale : hint_range(0.0, 0.2, 0.005) = 0.025;
uniform float noise_scale = 10.0;
uniform float height_scale = 0.15;

uniform sampler2D wave;
uniform sampler2D texture_normal;
uniform sampler2D texture_normal2;

// Depth/Edge Fade
uniform float beer_factor = 0.2; // Lower = clearer water
uniform float foam_distance = 0.01;
uniform float foam_max_distance = 0.4;
uniform float foam_min_distance = 0.04;
uniform vec4 foam_color : source_color = vec4(1.0);

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void vertex() {
	float height = texture(wave, VERTEX.xz / noise_scale + TIME * time_scale).r;
	VERTEX.y += height * height_scale;
}

void fragment() {
	// Time calculations
	float time = TIME * time_scale;
	vec2 d1 = vec2(wave_direction, wave_direction2);
	vec2 d2 = vec2(wave_direction2, -wave_direction);
	vec2 normal_dist = texture(texture_normal, UV * noise_scale + time * d1).rg;
	vec2 normal_dist2 = texture(texture_normal2, UV * noise_scale + time * d2).rg;
	vec3 normal_blend = mix(vec3(normal_dist, 1.0), vec3(normal_dist2, 1.0), 0.5);
	
	// Fresnel
	float fresnel = sqrt(1.0 - dot(NORMAL, VIEW));
	
	// Rim/Color
	vec3 surface_color = mix(albedo, albedo2, fresnel);
	
	// Depth Logic
	float depth = texture(depth_texture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	float object_depth = VERTEX.z; // In view space, z is negative
	
	// Depth difference
	float depth_blend = exp((depth - FRAGCOORD.z) * -beer_factor);
	depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
	float rho = 0.3;
	
	// Simple edge foam
	float z_depth = linear_depth + VERTEX.z;
	float foam = clamp(1.0 - (linear_depth - (-VERTEX.z)) / 1.0, 0.0, 1.0);
	
	ALBEDO = clamp(surface_color + (foam * foam_color.rgb), vec3(0.0), vec3(1.0));
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal_blend;
	ALPHA = clamp(0.8 + depth_blend, 0.0, 1.0); // Transparent
}
